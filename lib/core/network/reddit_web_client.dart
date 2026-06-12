import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:goodreddit/core/constants/api_constants.dart';
import 'package:goodreddit/core/error/exceptions.dart';

/// HTTP engine for Reddit, backed by a real browser engine.
///
/// Instead of issuing requests from Dart (which Reddit blocks by TLS
/// fingerprint on the public `*.json` endpoints), every request runs as a
/// `fetch()` *inside* a headless WebView whose document is served from the
/// `www.reddit.com` origin. Two consequences fall out of that:
///
///  * The request carries a genuine browser TLS fingerprint and header set —
///    Reddit sees it as the website talking to itself.
///  * The session cookie set by signing in (in the visible login WebView) is
///    attached automatically, because the Android WebView cookie store is
///    shared process-wide. So authenticated reads "just work" once logged in.
///
/// This is deliberately *not* the official OAuth flow: it needs no client ID,
/// at the cost of being against Reddit's API terms and more fragile if Reddit
/// changes its anti-bot handling.
class RedditWebClient {
  HeadlessInAppWebView? _headless;
  InAppWebViewController? _controller;
  Completer<void>? _ready;

  /// Boots the headless WebView and waits until a reddit.com document is loaded
  /// and able to run `fetch()`. Safe to call repeatedly — it is idempotent.
  Future<void> ensureReady() {
    final existing = _ready;
    if (existing != null) return existing.future;

    final completer = Completer<void>();
    _ready = completer;

    _headless = HeadlessInAppWebView(
      initialUrlRequest: URLRequest(
        url: WebUri('${ApiConstants.redditOrigin}/robots.txt'),
      ),
      initialSettings: InAppWebViewSettings(
        // A real Chrome-on-Android UA, matching what the engine actually is.
        userAgent:
            'Mozilla/5.0 (Linux; Android 14; Pixel 8) '
            'AppleWebKit/537.36 (KHTML, like Gecko) '
            'Chrome/126.0.0.0 Mobile Safari/537.36',
        javaScriptEnabled: true,
        thirdPartyCookiesEnabled: true,
      ),
      onWebViewCreated: (controller) => _controller = controller,
      onLoadStop: (controller, url) {
        if (!completer.isCompleted) completer.complete();
      },
      onReceivedError: (controller, request, error) {
        if (!completer.isCompleted) {
          completer.completeError(
            RedditException('Failed to load Reddit: ${error.description}'),
          );
        }
      },
    );

    unawaited(_headless!.run());
    return completer.future;
  }

  /// True when a Reddit session cookie is present in the shared cookie store.
  Future<bool> isLoggedIn() async {
    final cookies = await CookieManager.instance().getCookies(
      url: WebUri(ApiConstants.redditOrigin),
    );
    return cookies.any(
      (c) => c.name == 'reddit_session' && '${c.value}'.isNotEmpty,
    );
  }

  /// Runs a GET against a Reddit JSON endpoint from inside the page and returns
  /// the decoded JSON body (a `Map` or `List`).
  ///
  /// [path] is relative to [ApiConstants.redditOrigin] (e.g.
  /// `/subreddits/search.json`).
  Future<dynamic> getJson(String path, {Map<String, dynamic>? query}) async {
    await ensureReady();
    final controller = _controller;
    if (controller == null) {
      throw const RedditException('Reddit client not initialised');
    }

    final url = _buildUrl(path, query);

    // The function body runs in the reddit.com document. `callAsyncJavaScript`
    // awaits the returned promise and bridges the resolved value back to Dart.
    final result = await controller.callAsyncJavaScript(
      functionBody: '''
        try {
          const resp = await fetch(url, {
            credentials: "same-origin",
            headers: { "Accept": "application/json, text/plain, */*" },
          });
          const text = await resp.text();
          return { status: resp.status, body: text };
        } catch (e) {
          return { status: -1, body: String(e) };
        }
      ''',
      arguments: {'url': url},
    );

    if (result == null || result.error != null) {
      throw RedditException(
        'In-page request failed: ${result?.error ?? 'no result'}',
      );
    }

    final value = result.value as Map<dynamic, dynamic>;
    final status = (value['status'] as num).toInt();
    final body = value['body'] as String? ?? '';

    debugPrint(
      '[GoodReddit/web] GET $path → HTTP $status (${body.length} bytes)',
    );

    if (status == 401 || status == 403) {
      // 403 here usually means the session expired, not a TLS block (we are the
      // browser). Surface it as an auth problem so the UI can prompt re-login.
      if (!await isLoggedIn()) {
        throw const NotAuthenticatedException();
      }
      throw RedditException('Reddit refused the request (HTTP $status)');
    }
    if (status < 200 || status >= 300) {
      throw RedditException(_httpErrorMessage(status));
    }

    try {
      return jsonDecode(body);
    } catch (e) {
      throw RedditException('Failed to parse Reddit response: $e');
    }
  }

  String _buildUrl(String path, Map<String, dynamic>? query) {
    final buffer = StringBuffer(ApiConstants.redditOrigin)..write(path);
    if (query != null && query.isNotEmpty) {
      final qs = query.entries
          .map(
            (e) =>
                '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent('${e.value}')}',
          )
          .join('&');
      buffer
        ..write('?')
        ..write(qs);
    }
    return buffer.toString();
  }

  String _httpErrorMessage(int status) {
    switch (status) {
      case 404:
        return 'Not found (HTTP 404).';
      case 429:
        return 'Rate limited by Reddit (HTTP 429). Please wait and retry.';
      default:
        return 'Reddit request failed (HTTP $status).';
    }
  }

  Future<void> dispose() async {
    await _headless?.dispose();
    _headless = null;
    _controller = null;
    _ready = null;
  }
}
