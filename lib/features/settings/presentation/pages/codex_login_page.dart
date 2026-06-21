import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:goodreddit/core/constants/codex_constants.dart';

/// Visible "Sign in with ChatGPT" page. The user signs in on OpenAI's own
/// page inside a WebView; we never see their credentials. The Codex OAuth client
/// is registered with a loopback redirect (`http://localhost:1455/...`) we can't
/// re-register, so instead of running a local server we **intercept** the
/// navigation to that URL, pull out the `code`, and exchange it for tokens with
/// an in-page `fetch` (same-origin auth.openai.com, real browser fingerprint).
///
/// Pops with the raw `/oauth/token` JSON map on success, or `null` on
/// cancel/error.
class CodexLoginPage extends StatefulWidget {
  final String authorizeUrl;
  final String state;
  final String codeVerifier;

  const CodexLoginPage({
    super.key,
    required this.authorizeUrl,
    required this.state,
    required this.codeVerifier,
  });

  @override
  State<CodexLoginPage> createState() => _CodexLoginPageState();
}

class _CodexLoginPageState extends State<CodexLoginPage> {
  InAppWebViewController? _controller;
  bool _handled = false;
  double _progress = 0;
  String? _status;

  static final _settings = InAppWebViewSettings(
    userAgent:
        'Mozilla/5.0 (Linux; Android 14; Pixel 8) '
        'AppleWebKit/537.36 (KHTML, like Gecko) '
        'Chrome/126.0.0.0 Mobile Safari/537.36',
    javaScriptEnabled: true,
    thirdPartyCookiesEnabled: true,
    useShouldOverrideUrlLoading: true,
  );

  void _log(String msg) => debugPrint('[GoodReddit/codex-auth] $msg');

  bool _isRedirect(WebUri? u) =>
      u != null &&
      u.scheme == 'http' &&
      u.host == 'localhost' &&
      u.path == '/auth/callback';

  Future<void> _handleRedirect(WebUri uri) async {
    if (_handled) return;
    _handled = true;
    _log('redirect intercepted: ${uri.removeFragment()}');

    final error = uri.queryParameters['error'];
    if (error != null) {
      _failAndPop('Connexion refusée : $error');
      return;
    }
    if (uri.queryParameters['state'] != widget.state) {
      _failAndPop('state invalide (protection anti-CSRF)');
      return;
    }
    final code = uri.queryParameters['code'];
    if (code == null || code.isEmpty) {
      _failAndPop('Aucun code d\'autorisation reçu');
      return;
    }

    if (mounted) setState(() => _status = 'Échange du code contre les tokens…');
    final tokenJson = await _exchangeCode(code);
    if (!mounted) return;
    Navigator.of(context).pop(tokenJson);
  }

  /// Exchanges the auth code for tokens via an in-page POST to /oauth/token.
  /// The current document is still on auth.openai.com here, so this is a
  /// same-origin request with a genuine browser fingerprint.
  Future<Map<String, dynamic>?> _exchangeCode(String code) async {
    final controller = _controller;
    if (controller == null) return null;
    try {
      final res = await controller.callAsyncJavaScript(
        functionBody: '''
          const body = "grant_type=authorization_code"
            + "&code=" + encodeURIComponent(code)
            + "&redirect_uri=" + encodeURIComponent(redirectUri)
            + "&client_id=" + encodeURIComponent(clientId)
            + "&code_verifier=" + encodeURIComponent(verifier);
          try {
            const r = await fetch(tokenUrl, {
              method: "POST",
              headers: { "Content-Type": "application/x-www-form-urlencoded" },
              body: body,
            });
            return { status: r.status, body: await r.text() };
          } catch (e) {
            return { status: -1, body: String(e) };
          }
        ''',
        arguments: {
          'code': code,
          'redirectUri': CodexConstants.redirectUri,
          'clientId': CodexConstants.clientId,
          'verifier': widget.codeVerifier,
          'tokenUrl': CodexConstants.tokenUrl,
        },
      );

      if (res == null || res.error != null) {
        _showError('Échec de l\'échange (JS) : ${res?.error}');
        return null;
      }
      final value = res.value as Map<dynamic, dynamic>;
      final status = (value['status'] as num).toInt();
      final bodyStr = value['body'] as String? ?? '';
      if (status != 200) {
        _showError('Token endpoint HTTP $status : ${_short(bodyStr)}');
        return null;
      }
      final decoded = jsonDecode(bodyStr);
      if (decoded is Map<String, dynamic>) return decoded;
      _showError('Réponse token inattendue');
      return null;
    } catch (e) {
      _showError('Exception pendant l\'échange : $e');
      return null;
    }
  }

  void _failAndPop(String msg) {
    _showError(msg);
    if (mounted) Navigator.of(context).pop(null);
  }

  void _showError(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  String _short(String s) => s.length > 200 ? '${s.substring(0, 200)}…' : s;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Se connecter avec ChatGPT'),
        bottom: _progress < 1
            ? PreferredSize(
                preferredSize: const Size.fromHeight(2),
                child: LinearProgressIndicator(value: _progress),
              )
            : null,
      ),
      body: Column(
        children: [
          if (_status != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(_status!)),
                ],
              ),
            ),
          Expanded(
            child: InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri(widget.authorizeUrl)),
              initialSettings: _settings,
              onWebViewCreated: (controller) => _controller = controller,
              onProgressChanged: (_, progress) {
                if (mounted) setState(() => _progress = progress / 100);
              },
              shouldOverrideUrlLoading: (controller, action) async {
                final uri = action.request.url;
                if (_isRedirect(uri)) {
                  await _handleRedirect(uri!);
                  return NavigationActionPolicy.CANCEL;
                }
                return NavigationActionPolicy.ALLOW;
              },
              // Fallbacks: some redirects to the loopback URL slip past
              // shouldOverrideUrlLoading and surface here instead.
              onLoadStart: (controller, url) {
                if (_isRedirect(url)) _handleRedirect(url!);
              },
              onReceivedError: (controller, request, error) {
                if (_isRedirect(request.url)) _handleRedirect(request.url);
              },
            ),
          ),
        ],
      ),
    );
  }
}
