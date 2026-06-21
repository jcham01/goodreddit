import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:goodreddit/core/constants/codex_constants.dart';
import 'package:goodreddit/core/error/exceptions.dart';

/// Browser-engine HTTP for the ChatGPT Codex backend.
///
/// Mirrors [RedditWebClient]: the request runs as a `fetch()` *inside* a
/// headless WebView whose document is served from the `chatgpt.com` origin, so:
///
///  * it carries a genuine Chromium TLS fingerprint and header set — Cloudflare
///    sees a real browser, not a Dart client (a raw `dio` POST is 403'd by CF's
///    fingerprint check; that is the whole point of this transport);
///  * the Cloudflare clearance cookie obtained while loading chatgpt.com is
///    attached automatically (`credentials: include`, same-origin).
///
/// This is genuinely a browser making the call — no TLS spoofing. It is the same
/// deliberate technique this app already uses for Reddit, and it is what makes a
/// Codex call from a phone even possible.
class ChatGptWebClient {
  HeadlessInAppWebView? _headless;
  InAppWebViewController? _controller;
  Completer<void>? _load;

  // A real Chrome-on-Android UA, matching what the engine actually is — this is
  // what lets Cloudflare's browser check pass.
  static const _chromeUa =
      'Mozilla/5.0 (Linux; Android 14; Pixel 8) '
      'AppleWebKit/537.36 (KHTML, like Gecko) '
      'Chrome/126.0.0.0 Mobile Safari/537.36';

  /// Boots the headless WebView on the chatgpt.com origin (letting Cloudflare's
  /// challenge JS run and set a clearance cookie). Idempotent.
  Future<void> ensureReady() async {
    if (_controller != null) return;

    final first = Completer<void>();
    _load = first;

    _headless = HeadlessInAppWebView(
      initialUrlRequest: URLRequest(
        url: WebUri('${CodexConstants.chatgptOrigin}/'),
      ),
      initialSettings: InAppWebViewSettings(
        userAgent: _chromeUa,
        javaScriptEnabled: true,
        thirdPartyCookiesEnabled: true,
      ),
      onWebViewCreated: (controller) => _controller = controller,
      onLoadStop: (_, __) {
        if (!(_load?.isCompleted ?? true)) _load!.complete();
      },
      onReceivedError: (_, __, error) {
        if (!(_load?.isCompleted ?? true)) {
          _load!.completeError(
            LlmException('chatgpt.com load failed: ${error.description}'),
          );
        }
      },
    );

    await _headless!.run();
    await first.future.timeout(const Duration(seconds: 30));
    // Give Cloudflare's challenge JS a moment to set cf_clearance.
    await Future<void>.delayed(const Duration(seconds: 3));

    // The fetch must be same-origin (chatgpt.com). Loading "/" may have bounced
    // to the auth origin when there is no chatgpt.com session — in that case
    // come back via a stable, non-redirecting chatgpt.com URL.
    final url = await _controller!.getUrl();
    if (!(url?.host.endsWith('chatgpt.com') ?? false)) {
      await _loadAndWait('${CodexConstants.chatgptOrigin}/robots.txt');
    }
  }

  Future<void> _loadAndWait(String url) async {
    final completer = Completer<void>();
    _load = completer;
    await _controller!.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
    await completer.future.timeout(const Duration(seconds: 30));
  }

  /// POSTs [body] to [url] as a same-origin `fetch` and returns the raw status,
  /// response text (the SSE stream read in full) and response headers — enough
  /// to diagnose success vs a Cloudflare/auth/quota block. Same-origin, so all
  /// response headers are readable (no CORS restriction).
  Future<({int status, String body, Map<String, String> headers})> postJson({
    required String url,
    required Map<String, String> headers,
    required String body,
  }) async {
    await ensureReady();
    final controller = _controller;
    if (controller == null) {
      throw const LlmException('ChatGPT web client not initialised');
    }

    CallAsyncJavaScriptResult? result;
    try {
      result = await controller
          .callAsyncJavaScript(
            functionBody: '''
        try {
          const resp = await fetch(url, {
            method: "POST",
            credentials: "include",
            headers: headers,
            body: body,
          });
          const text = await resp.text();
          const hdrs = {};
          resp.headers.forEach((v, k) => { hdrs[k] = v; });
          return { status: resp.status, body: text, headers: hdrs };
        } catch (e) {
          return { status: -1, body: String(e), headers: {} };
        }
      ''',
            arguments: {'url': url, 'headers': headers, 'body': body},
          )
          .timeout(const Duration(seconds: 90));
    } on TimeoutException {
      return (status: -1, body: 'In-page fetch timed out', headers: <String, String>{});
    }

    if (result == null || result.error != null) {
      return (
        status: -1,
        body: 'In-page fetch error: ${result?.error ?? 'no result'}',
        headers: <String, String>{},
      );
    }

    final value = result.value as Map<dynamic, dynamic>;
    final status = (value['status'] as num).toInt();
    final text = value['body'] as String? ?? '';
    final rawHeaders = value['headers'];
    final responseHeaders = <String, String>{};
    if (rawHeaders is Map) {
      rawHeaders.forEach((k, v) => responseHeaders['$k'] = '$v');
    }
    debugPrint('[GoodReddit/codex] POST $url → HTTP $status (${text.length} bytes)');
    return (status: status, body: text, headers: responseHeaders);
  }

  /// GETs [url] as a same-origin `fetch` and returns the raw status + body.
  Future<({int status, String body})> getJson({
    required String url,
    required Map<String, String> headers,
  }) async {
    await ensureReady();
    final controller = _controller;
    if (controller == null) {
      throw const LlmException('ChatGPT web client not initialised');
    }

    CallAsyncJavaScriptResult? result;
    try {
      result = await controller
          .callAsyncJavaScript(
            functionBody: '''
        try {
          const resp = await fetch(url, {
            method: "GET",
            credentials: "include",
            headers: headers,
          });
          const text = await resp.text();
          return { status: resp.status, body: text };
        } catch (e) {
          return { status: -1, body: String(e) };
        }
      ''',
            arguments: {'url': url, 'headers': headers},
          )
          .timeout(const Duration(seconds: 20));
    } on TimeoutException {
      return (status: -1, body: 'In-page fetch timed out');
    }

    if (result == null || result.error != null) {
      return (status: -1, body: 'In-page fetch error: ${result?.error ?? 'no result'}');
    }
    final value = result.value as Map<dynamic, dynamic>;
    final status = (value['status'] as num).toInt();
    final text = value['body'] as String? ?? '';
    debugPrint('[GoodReddit/codex] GET $url → HTTP $status (${text.length} bytes)');
    return (status: status, body: text);
  }

  Future<void> dispose() async {
    await _headless?.dispose();
    _headless = null;
    _controller = null;
    _load = null;
  }
}
