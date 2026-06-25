import 'package:goodreddit/core/error/exceptions.dart';
import 'package:goodreddit/core/network/reddit_web_client.dart';
import 'package:goodreddit/core/util/vote_math.dart';

abstract class RedditInteractionsDataSource {
  Future<void> vote({required String fullname, required VoteDir dir});
  Future<void> setSaved({required String fullname, required bool saved});
  Future<void> setSubscribed({
    required String srName,
    String? fullname,
    required bool subscribe,
  });
}

/// Issues the authenticated write POSTs through [RedditWebClient.postForm]
/// (session cookie + `X-Modhash`). The modhash comes from `/api/me.json` and is
/// stable per session, so it is cached and only refetched when a write is
/// rejected with a CSRF-shaped error (e.g. right after re-login).
class RedditInteractionsDataSourceImpl implements RedditInteractionsDataSource {
  final RedditWebClient webClient;
  String? _modhash;

  RedditInteractionsDataSourceImpl({required this.webClient});

  Future<String> _csrf({bool force = false}) async {
    final cached = _modhash;
    if (!force && cached != null && cached.isNotEmpty) return cached;
    final me = await webClient.getJson('/api/me.json');
    final data = me is Map ? me['data'] : null;
    final hash = data is Map ? '${data['modhash'] ?? ''}' : '';
    if (hash.isEmpty) throw const NotAuthenticatedException();
    _modhash = hash;
    return hash;
  }

  /// POSTs to a write endpoint, refreshing the modhash and retrying ONCE if
  /// Reddit rejects with a CSRF/auth-shaped error or HTTP 403.
  Future<void> _post(String path, Map<String, String> fields) async {
    // `api_type=json` makes Reddit return the `{json:{errors:[...]}}` envelope
    // on a rejection, so genuine failures (and USER_REQUIRED) are detected
    // instead of being silently treated as success.
    final form = {...fields, 'api_type': 'json'};
    for (var attempt = 0; ; attempt++) {
      final modhash = await _csrf(force: attempt > 0);
      final dynamic body;
      try {
        body = await webClient.postForm(path, modhash: modhash, fields: form);
      } on RedditException catch (e) {
        if (attempt == 0 && e.message.contains('403')) {
          _modhash = null;
          continue;
        }
        rethrow;
      }
      final err = _firstError(body);
      if (err == null) return; // success ({} or no json.errors)
      if (attempt == 0 && _isCsrfCode(err.code)) {
        _modhash = null;
        continue;
      }
      throw RedditException(err.message.isNotEmpty ? err.message : err.code);
    }
  }

  @override
  Future<void> vote({required String fullname, required VoteDir dir}) =>
      _post('/api/vote', {'id': fullname, 'dir': dir.apiDir});

  @override
  Future<void> setSaved({required String fullname, required bool saved}) =>
      _post(saved ? '/api/save' : '/api/unsave', {'id': fullname});

  @override
  Future<void> setSubscribed({
    required String srName,
    String? fullname,
    required bool subscribe,
  }) => _post('/api/subscribe', {
    'action': subscribe ? 'sub' : 'unsub',
    if (fullname != null && fullname.isNotEmpty)
      'sr': fullname
    else
      'sr_name': srName,
  });

  /// Reddit replies `{ json: { errors: [["CODE","human msg","field"], ...] } }`
  /// on a rejected write. Returns the first (code, message), or null on success.
  ({String code, String message})? _firstError(dynamic body) {
    if (body is Map && body['json'] is Map) {
      final errors = (body['json'] as Map)['errors'];
      if (errors is List && errors.isNotEmpty) {
        final first = errors.first;
        if (first is List && first.isNotEmpty) {
          return (
            code: '${first.first}',
            message: first.length > 1 ? '${first[1]}' : '',
          );
        }
        return (code: '', message: '$first');
      }
    }
    return null;
  }

  bool _isCsrfCode(String code) {
    final c = code.toUpperCase();
    return c == 'USER_REQUIRED' || c.contains('MODHASH');
  }
}
