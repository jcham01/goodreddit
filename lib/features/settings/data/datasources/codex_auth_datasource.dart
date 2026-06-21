import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:goodreddit/core/constants/codex_constants.dart';
import 'package:goodreddit/core/error/exceptions.dart';
import 'package:goodreddit/core/network/chatgpt_web_client.dart';
import 'package:uuid/uuid.dart';

/// What the generator/ranking datasources need from Codex — kept narrow so they
/// don't depend on the whole auth machinery (and so tests can fake it).
abstract class CodexCaller {
  /// Sends [prompt] to the Codex backend and returns the assistant text.
  /// Throws [LlmException] when not signed in, on quota/auth errors, etc.
  Future<String> generateText(String prompt, {String? model});

  /// Best-effort live Codex model list ([] when unavailable).
  Future<List<String>> listModels();
}

/// What the UI needs to launch the OAuth WebView: the authorize URL plus the
/// PKCE verifier and `state` it must echo back when the redirect is intercepted.
class CodexAuthRequest {
  final String authorizeUrl;
  final String state;
  final String codeVerifier;

  const CodexAuthRequest({
    required this.authorizeUrl,
    required this.state,
    required this.codeVerifier,
  });
}

/// The credential bundle obtained from "Sign in with ChatGPT".
class CodexTokens {
  final String accessToken;
  final String? refreshToken;
  final String? idToken;
  final String? accountId;
  final String? planType;
  final DateTime? expiresAt;

  const CodexTokens({
    required this.accessToken,
    this.refreshToken,
    this.idToken,
    this.accountId,
    this.planType,
    this.expiresAt,
  });

  /// Parses the raw `/oauth/token` JSON response, decoding the id_token to pull
  /// out `chatgpt_account_id` / `chatgpt_plan_type` and the access-token `exp`.
  factory CodexTokens.fromTokenResponse(Map<String, dynamic> json) {
    final access = (json['access_token'] as String?) ?? '';
    final idToken = json['id_token'] as String?;

    String? accountId;
    String? plan;
    final idClaims = idToken == null ? null : decodeJwtClaims(idToken);
    final auth = idClaims?[CodexConstants.authClaimNamespace];
    if (auth is Map) {
      accountId = auth['chatgpt_account_id'] as String?;
      plan = auth['chatgpt_plan_type'] as String?;
    }

    DateTime? exp;
    final accClaims = access.isEmpty ? null : decodeJwtClaims(access);
    final e = accClaims?['exp'];
    if (e is num) {
      exp = DateTime.fromMillisecondsSinceEpoch(e.toInt() * 1000, isUtc: true);
    }

    return CodexTokens(
      accessToken: access,
      refreshToken: json['refresh_token'] as String?,
      idToken: idToken,
      accountId: accountId,
      planType: plan,
      expiresAt: exp,
    );
  }

  factory CodexTokens.fromStore(Map<String, dynamic> json) => CodexTokens(
    accessToken: json['accessToken'] as String? ?? '',
    refreshToken: json['refreshToken'] as String?,
    idToken: json['idToken'] as String?,
    accountId: json['accountId'] as String?,
    planType: json['planType'] as String?,
    expiresAt: json['expiresAt'] != null
        ? DateTime.tryParse(json['expiresAt'] as String)
        : null,
  );

  Map<String, dynamic> toStore() => {
    'accessToken': accessToken,
    'refreshToken': refreshToken,
    'idToken': idToken,
    'accountId': accountId,
    'planType': planType,
    'expiresAt': expiresAt?.toIso8601String(),
  };

  /// Applies a refresh response, keeping the original account id/plan when the
  /// refreshed tokens omit those claims (they often do).
  CodexTokens mergedWithRefresh(Map<String, dynamic> json) {
    final refreshed = CodexTokens.fromTokenResponse({
      'access_token': json['access_token'] ?? accessToken,
      'id_token': json['id_token'] ?? idToken,
      'refresh_token': json['refresh_token'] ?? refreshToken,
    });
    return CodexTokens(
      accessToken: refreshed.accessToken,
      refreshToken: refreshed.refreshToken,
      idToken: refreshed.idToken,
      accountId: refreshed.accountId ?? accountId,
      planType: refreshed.planType ?? planType,
      expiresAt: refreshed.expiresAt ?? expiresAt,
    );
  }

  bool get isValid => accessToken.isNotEmpty;
}

/// One usage window (5h = primary, weekly = secondary) as reported by the Codex
/// backend. Percentages are 0–100 of the window consumed.
class CodexRateWindow {
  final double usedPercent;
  final int? windowMinutes;
  final DateTime? resetsAt;

  const CodexRateWindow({
    required this.usedPercent,
    this.windowMinutes,
    this.resetsAt,
  });

  double get remainingPercent => (100 - usedPercent).clamp(0, 100).toDouble();

  factory CodexRateWindow.fromStore(Map<String, dynamic> j) => CodexRateWindow(
    usedPercent: (j['usedPercent'] as num?)?.toDouble() ?? 0,
    windowMinutes: (j['windowMinutes'] as num?)?.toInt(),
    resetsAt: j['resetsAt'] != null
        ? DateTime.tryParse(j['resetsAt'] as String)
        : null,
  );

  Map<String, dynamic> toStore() => {
    'usedPercent': usedPercent,
    'windowMinutes': windowMinutes,
    'resetsAt': resetsAt?.toIso8601String(),
  };
}

/// Snapshot of the Codex usage limits at [capturedAt].
class CodexRateLimits {
  final CodexRateWindow? primary; // ~5h rolling window
  final CodexRateWindow? secondary; // ~weekly window
  final DateTime capturedAt;

  const CodexRateLimits({this.primary, this.secondary, required this.capturedAt});

  factory CodexRateLimits.fromStore(Map<String, dynamic> j) => CodexRateLimits(
    primary: j['primary'] is Map
        ? CodexRateWindow.fromStore((j['primary'] as Map).cast<String, dynamic>())
        : null,
    secondary: j['secondary'] is Map
        ? CodexRateWindow.fromStore(
            (j['secondary'] as Map).cast<String, dynamic>(),
          )
        : null,
    capturedAt:
        DateTime.tryParse(j['capturedAt'] as String? ?? '') ?? DateTime.now(),
  );

  Map<String, dynamic> toStore() => {
    'primary': primary?.toStore(),
    'secondary': secondary?.toStore(),
    'capturedAt': capturedAt.toIso8601String(),
  };
}

/// The outcome of the feasibility probe — the one-shot diagnostic call.
class CodexProbeResult {
  final int status;
  final bool ok;
  final String verdict;
  final String? text;
  final String rawBodySnippet;
  final Map<String, String> headers;

  const CodexProbeResult({
    required this.status,
    required this.ok,
    required this.verdict,
    this.text,
    this.rawBodySnippet = '',
    this.headers = const {},
  });
}

/// Owns the Codex "Sign in with ChatGPT" flow: PKCE, token persistence +
/// proactive refresh, the model-list fetch, and the actual Responses calls
/// (through the browser-engine transport so Cloudflare lets them through).
///
/// The OAuth WebView is driven by the presentation layer, which hands the raw
/// token JSON back via [completeSignIn] (keeps this class UI-free).
class CodexAuthDataSource implements CodexCaller {
  final FlutterSecureStorage secureStorage;
  final Uuid uuid;
  final ChatGptWebClient chatGptWebClient;
  final Dio dio;

  static const _storeKey = 'codex_tokens';
  static const _usageKey = 'codex_usage';

  CodexAuthDataSource({
    required this.secureStorage,
    required this.uuid,
    required this.chatGptWebClient,
    required this.dio,
  });

  // ---- OAuth / PKCE ----

  /// Builds the authorize URL + PKCE material. Call before launching the WebView.
  CodexAuthRequest beginSignIn() {
    final verifier = _randomUrlSafe(64);
    final state = _randomUrlSafe(32);
    final challenge = _codeChallenge(verifier);

    final query = _encodeQuery({
      'response_type': 'code',
      'client_id': CodexConstants.clientId,
      'redirect_uri': CodexConstants.redirectUri,
      'scope': CodexConstants.scope,
      'code_challenge': challenge,
      'code_challenge_method': 'S256',
      'id_token_add_organizations': 'true',
      'codex_cli_simplified_flow': 'true',
      'state': state,
      'originator': CodexConstants.originator,
    });

    return CodexAuthRequest(
      authorizeUrl: '${CodexConstants.authorizeUrl}?$query',
      state: state,
      codeVerifier: verifier,
    );
  }

  /// Parses the `/oauth/token` JSON the WebView captured, persists it, returns it.
  Future<CodexTokens> completeSignIn(Map<String, dynamic> tokenJson) async {
    final tokens = CodexTokens.fromTokenResponse(tokenJson);
    await _store(tokens);
    _log(
      'signed in · plan=${tokens.planType ?? "?"} · '
      'account=${tokens.accountId ?? "?"} · '
      'refresh=${tokens.refreshToken != null ? "present" : "absent"} · '
      'exp=${tokens.expiresAt?.toIso8601String() ?? "?"}',
    );
    return tokens;
  }

  // ---- Persistence ----

  Future<CodexTokens?> loadTokens() async {
    final raw = await secureStorage.read(key: _storeKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final tokens = CodexTokens.fromStore(
        jsonDecode(raw) as Map<String, dynamic>,
      );
      return tokens.isValid ? tokens : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _store(CodexTokens tokens) =>
      secureStorage.write(key: _storeKey, value: jsonEncode(tokens.toStore()));

  Future<void> clear() => secureStorage.delete(key: _storeKey);

  Future<bool> isSignedIn() async => (await loadTokens()) != null;

  // ---- Usage / rate limits ----

  /// Last persisted usage snapshot (captured from the headers of the most recent
  /// Codex call, or from [fetchUsage]).
  Future<CodexRateLimits?> loadUsage() async {
    final raw = await secureStorage.read(key: _usageKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return CodexRateLimits.fromStore(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> _storeUsage(CodexRateLimits rl) =>
      secureStorage.write(key: _usageKey, value: jsonEncode(rl.toStore()));

  Future<void> _captureUsage(Map<String, String> headers, String body) async {
    final rl = _rateLimitsFromResponse(headers, body);
    if (rl != null) await _storeUsage(rl);
  }

  /// Refreshes usage via the dedicated read-only endpoint (does NOT consume model
  /// quota). Falls back to the last stored snapshot on any failure.
  Future<CodexRateLimits?> fetchUsage() async {
    final tokens = await loadTokens();
    if (tokens == null) return null;
    try {
      final fresh = await ensureFresh(tokens);
      final res = await chatGptWebClient.getJson(
        url: CodexConstants.codexUsageUrl,
        headers: _authHeaders(fresh),
      );
      _log('usage ← HTTP ${res.status}');
      _logBlock('usage body', res.body);
      if (res.status == 200) {
        final rl = _rateLimitsFromJson(res.body);
        if (rl != null) {
          await _storeUsage(rl);
          return rl;
        }
      }
      return loadUsage();
    } catch (e) {
      _log('usage fetch failed: $e');
      return loadUsage();
    }
  }

  // ---- Token refresh ----

  /// Refreshes the access token if it is missing or about to expire (<5 min).
  /// Falls back to the current token when there is nothing to refresh; throws
  /// [LlmException] if a refresh attempt is rejected (re-login needed).
  Future<CodexTokens> ensureFresh(CodexTokens tokens) async {
    final exp = tokens.expiresAt;
    final soon = DateTime.now().toUtc().add(const Duration(minutes: 5));
    final needsRefresh = exp == null || exp.isBefore(soon);
    if (!needsRefresh) return tokens;
    final refresh = tokens.refreshToken;
    if (refresh == null || refresh.isEmpty) return tokens;
    return _refresh(tokens);
  }

  Future<CodexTokens> _refresh(CodexTokens current) async {
    try {
      final resp = await dio.post<Map<String, dynamic>>(
        CodexConstants.tokenUrl,
        data: {
          'client_id': CodexConstants.clientId,
          'grant_type': 'refresh_token',
          'refresh_token': current.refreshToken,
        },
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
      final merged = current.mergedWithRefresh(resp.data ?? const {});
      await _store(merged);
      _log('token refreshed · exp=${merged.expiresAt?.toIso8601String() ?? "?"}');
      return merged;
    } on DioException catch (e) {
      _log('refresh failed: HTTP ${e.response?.statusCode} ${e.message}');
      throw const LlmException(
        'Codex : session expirée. Reconnecte-toi via Réglages → Codex.',
      );
    }
  }

  // ---- CodexCaller: real model calls ----

  @override
  Future<String> generateText(String prompt, {String? model}) async {
    final tokens = await _freshTokensOrThrow();
    final res = await chatGptWebClient.postJson(
      url: CodexConstants.codexResponsesUrl,
      headers: _callHeaders(tokens),
      body: _responsesBody(prompt, model ?? CodexConstants.defaultModel),
    );
    _log('generateText ← HTTP ${res.status}');
    await _captureUsage(res.headers, res.body);
    if (res.status == 200) {
      final text = _extractSseText(res.body);
      if (text.isEmpty) {
        throw const LlmException('Codex : réponse vide du backend.');
      }
      return text;
    }
    throw LlmException(_diagnose(res.status, res.body, res.headers));
  }

  @override
  Future<List<String>> listModels() async {
    final tokens = await loadTokens();
    if (tokens == null) return const [];
    try {
      final fresh = await ensureFresh(tokens);
      final res = await chatGptWebClient.getJson(
        url: CodexConstants.codexModelsUrl,
        headers: _authHeaders(fresh),
      );
      _log('listModels ← HTTP ${res.status}');
      _logBlock('models body', res.body);
      if (res.status != 200) return const [];
      return _parseModelIds(res.body);
    } catch (e) {
      _log('listModels failed: $e');
      return const [];
    }
  }

  Future<CodexTokens> _freshTokensOrThrow() async {
    final tokens = await loadTokens();
    if (tokens == null) {
      throw const LlmException(
        'Codex : non connecté. Va dans Réglages → Codex → '
        '« Se connecter avec ChatGPT ».',
      );
    }
    return ensureFresh(tokens);
  }

  // ---- The feasibility probe (Settings PoC panel) ----

  /// Fires ONE Codex Responses call and reports exactly what came back.
  Future<CodexProbeResult> probe(CodexTokens tokens, {String? model}) async {
    try {
      final fresh = await ensureFresh(tokens);
      _log(
        'probe → POST ${CodexConstants.codexResponsesUrl} '
        'model=${model ?? CodexConstants.defaultModel} '
        'account=${fresh.accountId ?? "<none>"} '
        'token=${_mask(fresh.accessToken)}',
      );

      final res = await chatGptWebClient.postJson(
        url: CodexConstants.codexResponsesUrl,
        headers: _callHeaders(fresh),
        body: _responsesBody(
          'Reply with exactly: CODEX_OK',
          model ?? CodexConstants.defaultModel,
        ),
      );

      _log('probe ← HTTP ${res.status}');
      _logBlock(
        'response headers',
        res.headers.entries.map((e) => '${e.key}: ${e.value}').join('\n'),
      );
      _logBlock('response body', res.body);
      await _captureUsage(res.headers, res.body);

      final CodexProbeResult result;
      if (res.status == 200) {
        final text = _extractSseText(res.body);
        result = CodexProbeResult(
          status: 200,
          ok: true,
          verdict:
              '✅ SUCCÈS — Cloudflare a laissé passer. 200 reçu du backend Codex. '
              'La feature complète est faisable via ce transport.',
          text: text.isEmpty ? null : text,
          rawBodySnippet: _snippet(res.body),
          headers: res.headers,
        );
      } else {
        result = CodexProbeResult(
          status: res.status,
          ok: false,
          verdict: _diagnose(res.status, res.body, res.headers),
          rawBodySnippet: _snippet(res.body),
          headers: res.headers,
        );
      }
      _log('verdict: ${result.verdict}');
      return result;
    } catch (e) {
      return CodexProbeResult(
        status: -1,
        ok: false,
        verdict: '❌ Erreur pendant l\'appel : $e',
      );
    }
  }

  // ---- request builders ----

  Map<String, String> _authHeaders(CodexTokens t) => {
    'Authorization': 'Bearer ${t.accessToken}',
    'ChatGPT-Account-ID': t.accountId ?? '',
    'originator': CodexConstants.originator,
  };

  Map<String, String> _callHeaders(CodexTokens t) => {
    ..._authHeaders(t),
    // No User-Agent (forbidden in fetch; the WebView already presents a real
    // browser). No OpenAI-Beta: current openai/codex sends none on the SSE POST.
    'Accept': 'text/event-stream',
    'Content-Type': 'application/json',
    'session-id': uuid.v4(),
    'x-client-request-id': uuid.v4(),
  };

  String _responsesBody(String prompt, String model) => jsonEncode({
    'model': model,
    // The backend rejects an empty `instructions`.
    'instructions': 'You are a helpful assistant.',
    'input': [
      {
        'role': 'user',
        'content': [
          {'type': 'input_text', 'text': prompt},
        ],
      },
    ],
    'tools': <dynamic>[],
    'tool_choice': 'auto',
    'parallel_tool_calls': false,
    'reasoning': {'summary': 'auto'},
    'store': false,
    'stream': true,
    'include': ['reasoning.encrypted_content'],
    'prompt_cache_key': uuid.v4(),
  });

  // ---- response parsing ----

  /// Rate limits from a /responses call: `x-codex-{primary,secondary}-*` headers
  /// first, falling back to a `rate_limits` object embedded in the SSE stream.
  CodexRateLimits? _rateLimitsFromResponse(
    Map<String, String> headers,
    String body,
  ) {
    final h = {for (final e in headers.entries) e.key.toLowerCase(): e.value};

    CodexRateWindow? fromHeaders(String tier) {
      final used = double.tryParse(h['x-codex-$tier-used-percent'] ?? '');
      if (used == null) return null;
      final win = int.tryParse(h['x-codex-$tier-window-minutes'] ?? '');
      final resetSec = int.tryParse(
        h['x-codex-$tier-reset-after-seconds'] ??
            h['x-codex-$tier-resets-in-seconds'] ??
            '',
      );
      return CodexRateWindow(
        usedPercent: used,
        windowMinutes: win,
        resetsAt: resetSec != null
            ? DateTime.now().add(Duration(seconds: resetSec))
            : null,
      );
    }

    final primary = fromHeaders('primary');
    final secondary = fromHeaders('secondary');
    if (primary != null || secondary != null) {
      return CodexRateLimits(
        primary: primary,
        secondary: secondary,
        capturedAt: DateTime.now(),
      );
    }

    // Fallback: a `rate_limits` object may ride along in the SSE stream.
    for (final line in const LineSplitter().convert(body)) {
      final l = line.trim();
      if (!l.startsWith('data:')) continue;
      final data = l.substring(5).trim();
      if (data.isEmpty || data == '[DONE]') continue;
      try {
        final rl = _rateLimitsFromJsonValue(jsonDecode(data));
        if (rl != null) return rl;
      } catch (_) {}
    }
    return null;
  }

  CodexRateLimits? _rateLimitsFromJson(String body) {
    try {
      return _rateLimitsFromJsonValue(jsonDecode(body));
    } catch (_) {
      return null;
    }
  }

  CodexRateLimits? _rateLimitsFromJsonValue(dynamic json) {
    final rl = _findRateLimitsMap(json);
    if (rl == null) return null;
    final primary = _windowFromJson(rl['primary']);
    final secondary = _windowFromJson(rl['secondary']);
    if (primary == null && secondary == null) return null;
    return CodexRateLimits(
      primary: primary,
      secondary: secondary,
      capturedAt: DateTime.now(),
    );
  }

  Map<String, dynamic>? _findRateLimitsMap(dynamic j) {
    if (j is Map<String, dynamic>) {
      if (j['rate_limits'] is Map) {
        return (j['rate_limits'] as Map).cast<String, dynamic>();
      }
      if (j['primary'] is Map || j['secondary'] is Map) return j;
      for (final v in j.values) {
        final r = _findRateLimitsMap(v);
        if (r != null) return r;
      }
    } else if (j is List) {
      for (final v in j) {
        final r = _findRateLimitsMap(v);
        if (r != null) return r;
      }
    }
    return null;
  }

  CodexRateWindow? _windowFromJson(dynamic m) {
    if (m is! Map) return null;
    final used = (m['used_percent'] as num?)?.toDouble();
    if (used == null) return null;
    final resetSec = (m['resets_in_seconds'] as num?)?.toInt();
    return CodexRateWindow(
      usedPercent: used,
      windowMinutes: (m['window_minutes'] as num?)?.toInt(),
      resetsAt: resetSec != null
          ? DateTime.now().add(Duration(seconds: resetSec))
          : null,
    );
  }

  List<String> _parseModelIds(String raw) {
    final ids = <String>{};
    void addFrom(dynamic list) {
      if (list is! List) return;
      for (final m in list) {
        if (m is String) {
          ids.add(m);
        } else if (m is Map) {
          final id = m['slug'] ?? m['id'] ?? m['model'] ?? m['name'];
          if (id is String) ids.add(id);
        }
      }
    }

    try {
      final json = jsonDecode(raw);
      if (json is Map) {
        addFrom(json['models']);
        addFrom(json['data']);
      } else {
        addFrom(json);
      }
    } catch (_) {
      return const [];
    }

    // Only codex-named slugs are valid for the codex /responses endpoint; the
    // curated valid ids (e.g. gpt-5.5) are merged in by the repository.
    final codexLike =
        ids.where((id) => id.toLowerCase().contains('codex')).toList()..sort();
    return codexLike;
  }

  String _diagnose(int status, String body, Map<String, String> headers) {
    final low = body.toLowerCase();
    final h = {for (final e in headers.entries) e.key.toLowerCase(): e.value};
    final looksCloudflare =
        low.contains('cloudflare') ||
        low.contains('cf-ray') ||
        low.contains('just a moment') ||
        low.contains('attention required') ||
        low.contains('mitigation') ||
        h.containsKey('cf-mitigated') ||
        (h['server']?.toLowerCase().contains('cloudflare') ?? false);

    final retryAfter = h['retry-after'] ?? h['x-ratelimit-reset'];
    final resetHint = retryAfter != null ? ' Réessaie dans ~$retryAfter.' : '';
    final usageLimit =
        low.contains('usage') ||
        low.contains('limit') ||
        low.contains('quota') ||
        (h['x-ratelimit-remaining'] == '0');

    switch (status) {
      case -1:
        return '❌ Aucune réponse (erreur réseau / JS / origine).';
      case 401:
        return '🔒 401 — session Codex refusée. Reconnecte-toi via Réglages → Codex.';
      case 403:
        return looksCloudflare
            ? '⛔ 403 Cloudflare — appel bloqué malgré un token valide.'
            : '⛔ 403 — accès refusé (originator/plan/résidence). Voir les logs.';
      case 429:
        return '⏳ 429 — quota Codex du plan ChatGPT atteint'
            '${usageLimit ? '' : ' (ou limite de débit)'}.$resetHint';
      case 400:
        return '⚠️ 400 — requête refusée par le backend Codex. Voir les logs.';
      default:
        return 'Codex : HTTP $status. Voir les logs.'
            '${looksCloudflare ? ' (marqueurs Cloudflare)' : ''}';
    }
  }

  /// Concatenates `response.output_text.delta` events from the SSE stream; falls
  /// back to parsing a single JSON body if the backend didn't actually stream.
  String _extractSseText(String raw) {
    final buffer = StringBuffer();
    for (final line in const LineSplitter().convert(raw)) {
      final l = line.trim();
      if (!l.startsWith('data:')) continue;
      final data = l.substring(5).trim();
      if (data.isEmpty || data == '[DONE]') continue;
      try {
        final ev = jsonDecode(data);
        if (ev is Map &&
            ev['type'] == 'response.output_text.delta' &&
            ev['delta'] is String) {
          buffer.write(ev['delta']);
        }
      } catch (_) {
        // Ignore keep-alive / non-JSON lines.
      }
    }
    if (buffer.isNotEmpty) return buffer.toString();

    // Non-streamed fallback: output[] -> message -> content[] -> output_text.
    try {
      final json = jsonDecode(raw);
      final output = (json is Map ? json['output'] : null);
      if (output is List) {
        for (final item in output) {
          if (item is Map && item['type'] == 'message') {
            final content = item['content'];
            if (content is List) {
              for (final c in content) {
                if (c is Map &&
                    c['type'] == 'output_text' &&
                    c['text'] is String) {
                  buffer.write(c['text']);
                }
              }
            }
          }
        }
      }
    } catch (_) {}
    return buffer.toString();
  }

  String _snippet(String body) =>
      body.length > 1200 ? '${body.substring(0, 1200)}…' : body;

  static const String _logTag = '[GoodReddit/codex]';

  void _log(String msg) => debugPrint('$_logTag $msg');

  /// Logs a long block line-by-line, every line tagged (so `grep <tag>` keeps
  /// them) and sub-chunked so Android logcat doesn't truncate long lines.
  void _logBlock(String title, String content) {
    _log('--- $title ---');
    if (content.isEmpty) {
      _log('(empty)');
      _log('--- end $title ---');
      return;
    }
    const maxLine = 700;
    for (final line in const LineSplitter().convert(content)) {
      if (line.length <= maxLine) {
        _log(line);
      } else {
        for (var i = 0; i < line.length; i += maxLine) {
          _log(line.substring(i, min(i + maxLine, line.length)));
        }
      }
    }
    _log('--- end $title ---');
  }

  String _mask(String token) {
    if (token.length <= 12) return token.isEmpty ? '<empty>' : '***';
    return '${token.substring(0, 6)}…${token.substring(token.length - 4)}';
  }

  String _randomUrlSafe(int byteLength) {
    final rng = Random.secure();
    final bytes = List<int>.generate(byteLength, (_) => rng.nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  String _codeChallenge(String verifier) {
    final digest = sha256.convert(ascii.encode(verifier));
    return base64UrlEncode(digest.bytes).replaceAll('=', '');
  }

  String _encodeQuery(Map<String, String> params) => params.entries
      .map(
        (e) =>
            '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}',
      )
      .join('&');
}

/// Base64url-decodes a JWT payload and returns its claims (no signature check —
/// these tokens are read-only here).
Map<String, dynamic>? decodeJwtClaims(String jwt) {
  try {
    final parts = jwt.split('.');
    if (parts.length < 2) return null;
    final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
    final decoded = jsonDecode(payload);
    return decoded is Map<String, dynamic> ? decoded : null;
  } catch (_) {
    return null;
  }
}
