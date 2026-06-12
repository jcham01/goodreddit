import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:goodreddit/core/constants/api_constants.dart';

/// Visible Reddit login. The user signs in on Reddit's own page inside a
/// WebView; we never see their credentials. Once a logged-in session is
/// detected, we pop with `true`.
///
/// Detection is authoritative and resilient:
///  * We poll `/api/me.json` from the reddit.com document, so a soft SPA
///    login (no navigation event) is still detected.
///  * OAuth popups (e.g. "Sign in with Google") are supported via
///    [onCreateWindow], otherwise the token hand-off never completes.
///  * A manual "Done" action is always available as a fallback.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  InAppWebViewController? _controller;
  Timer? _poll;
  double _progress = 0;
  bool _popped = false;

  static final _settings = InAppWebViewSettings(
    userAgent: 'Mozilla/5.0 (Linux; Android 14; Pixel 8) '
        'AppleWebKit/537.36 (KHTML, like Gecko) '
        'Chrome/126.0.0.0 Mobile Safari/537.36',
    javaScriptEnabled: true,
    thirdPartyCookiesEnabled: true,
    supportMultipleWindows: true,
    javaScriptCanOpenWindowsAutomatically: true,
  );

  @override
  void initState() {
    super.initState();
    // Poll for a completed session even when Reddit updates its SPA in place
    // without firing a navigation event.
    _poll = Timer.periodic(const Duration(seconds: 2), (_) => _detectSession());
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  void _log(String msg) => debugPrint('[GoodReddit/auth] $msg');

  void _finish(String reason) {
    if (_popped || !mounted) return;
    _log('login detected ($reason) → closing');
    _popped = true;
    _poll?.cancel();
    Navigator.of(context).pop(true);
  }

  /// Authoritative check: a logged-in browser session returns the user's data
  /// from `/api/me.json`. Cross-origin pages (e.g. the Google step) return null.
  Future<void> _detectSession() async {
    if (_popped || _controller == null) return;
    try {
      final url = await _controller!.getUrl();
      if (!(url?.host.contains('reddit.com') ?? false)) return;

      final result = await _controller!.callAsyncJavaScript(functionBody: '''
        try {
          const r = await fetch('/api/me.json',
            { credentials: 'same-origin', headers: { 'Accept': 'application/json' } });
          if (!r.ok) return null;
          const j = await r.json();
          return (j && j.data && j.data.name) ? j.data.name : null;
        } catch (e) { return null; }
      ''');
      final name = result?.value;
      if (name is String && name.isNotEmpty) {
        _finish('u/$name');
      }
    } catch (e) {
      _log('detect error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign in to Reddit'),
        actions: [
          TextButton(
            onPressed: () => _finish('manual'),
            child: const Text('DONE'),
          ),
        ],
        bottom: _progress < 1
            ? PreferredSize(
                preferredSize: const Size.fromHeight(2),
                child: LinearProgressIndicator(value: _progress),
              )
            : null,
      ),
      body: InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri(ApiConstants.redditLoginUrl)),
        initialSettings: _settings,
        onWebViewCreated: (controller) => _controller = controller,
        onProgressChanged: (controller, progress) {
          if (mounted) setState(() => _progress = progress / 100);
        },
        onLoadStop: (controller, url) {
          _log('loadStop: $url');
          _detectSession();
        },
        onUpdateVisitedHistory: (controller, url, isReload) => _detectSession(),
        // Support the OAuth popup window ("Sign in with Google", etc.).
        onCreateWindow: (controller, createWindowAction) async {
          _log('popup requested (windowId=${createWindowAction.windowId})');
          await showDialog(
            context: context,
            builder: (dialogContext) => Dialog(
              insetPadding: const EdgeInsets.all(12),
              child: SizedBox(
                width: double.maxFinite,
                height: MediaQuery.of(dialogContext).size.height * 0.8,
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(dialogContext).pop(),
                      ),
                    ),
                    Expanded(
                      child: InAppWebView(
                        windowId: createWindowAction.windowId,
                        initialSettings: _settings,
                        onCloseWindow: (_) {
                          if (Navigator.of(dialogContext).canPop()) {
                            Navigator.of(dialogContext).pop();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
          // The popup typically posts the credential back to the main reddit
          // window; the periodic poll picks up the completed session.
          _detectSession();
          return true;
        },
      ),
    );
  }
}
