import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:goodreddit/core/constants/api_constants.dart';
import 'package:goodreddit/core/error/exceptions.dart';
import 'package:goodreddit/core/network/reddit_web_client.dart';

/// Reads and clears the Reddit browser session from the shared cookie store.
abstract class RedditAuthDataSource {
  Future<bool> isLoggedIn();
  Future<String?> resolveUsername();
  Future<void> clearSession();
}

class RedditAuthDataSourceImpl implements RedditAuthDataSource {
  final RedditWebClient webClient;

  RedditAuthDataSourceImpl({required this.webClient});

  @override
  Future<bool> isLoggedIn() => webClient.isLoggedIn();

  @override
  Future<String?> resolveUsername() async {
    try {
      // `/api/me.json` returns the logged-in user's data when a session cookie
      // is present; an anonymous session returns an empty object.
      final data = await webClient.getJson('/api/me.json');
      if (data is Map && data['data'] is Map) {
        final name = (data['data'] as Map)['name'];
        if (name is String && name.isNotEmpty) return name;
      }
      return null;
    } on NotAuthenticatedException {
      return null;
    } catch (_) {
      // Username resolution is best-effort; never fail auth over it.
      return null;
    }
  }

  @override
  Future<void> clearSession() async {
    try {
      final cookieManager = CookieManager.instance();
      await cookieManager.deleteCookies(url: WebUri(ApiConstants.redditOrigin));
      await cookieManager.deleteCookies(
        url: WebUri(ApiConstants.redditOrigin),
        domain: '.reddit.com',
      );
    } catch (e) {
      throw CacheException('Failed to clear Reddit session: $e');
    }
  }
}
