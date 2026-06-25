import 'package:flutter_test/flutter_test.dart';
import 'package:goodreddit/core/error/exceptions.dart';
import 'package:goodreddit/core/error/failures.dart';
import 'package:goodreddit/core/network/reddit_web_client.dart';
import 'package:goodreddit/core/util/vote_math.dart';
import 'package:goodreddit/features/interactions/data/datasources/reddit_interactions_datasource.dart';
import 'package:goodreddit/features/interactions/data/repositories/interactions_repository_impl.dart';

void main() {
  group('RedditInteractionsDataSourceImpl', () {
    test('vote posts id+dir with the cached modhash; me.json fetched once', () async {
      final web = _FakeWebClient();
      final ds = RedditInteractionsDataSourceImpl(webClient: web);

      await ds.vote(fullname: 't3_a', dir: VoteDir.up);
      expect(web.lastPath, '/api/vote');
      expect(web.lastFields, {'id': 't3_a', 'dir': '1', 'api_type': 'json'});
      expect(web.lastModhash, 'MH');
      expect(web.meCalls, 1);

      await ds.setSaved(fullname: 't3_a', saved: true);
      expect(web.lastPath, '/api/save');
      expect(web.meCalls, 1); // modhash reused
    });

    test('setSaved(false) hits /api/unsave', () async {
      final web = _FakeWebClient();
      final ds = RedditInteractionsDataSourceImpl(webClient: web);
      await ds.setSaved(fullname: 't3_a', saved: false);
      expect(web.lastPath, '/api/unsave');
    });

    test('subscribe prefers sr (t5_), falls back to sr_name', () async {
      final web = _FakeWebClient();
      final ds = RedditInteractionsDataSourceImpl(webClient: web);

      await ds.setSubscribed(srName: 'flutter', fullname: 't5_x', subscribe: true);
      expect(web.lastFields, {
        'action': 'sub',
        'sr': 't5_x',
        'api_type': 'json',
      });

      await ds.setSubscribed(srName: 'flutter', fullname: null, subscribe: false);
      expect(web.lastFields, {
        'action': 'unsub',
        'sr_name': 'flutter',
        'api_type': 'json',
      });
    });

    test('an empty modhash throws NotAuthenticatedException', () async {
      final web = _FakeWebClient()..modhash = '';
      final ds = RedditInteractionsDataSourceImpl(webClient: web);
      await expectLater(
        ds.vote(fullname: 't3_a', dir: VoteDir.up),
        throwsA(isA<NotAuthenticatedException>()),
      );
    });

    test('a json.errors body throws RedditException with the human message', () async {
      final web = _FakeWebClient()
        ..postResult = {
          'json': {
            'errors': [
              ['RATELIMIT', 'you are doing that too much', 'ratelimit'],
            ],
          },
        };
      final ds = RedditInteractionsDataSourceImpl(webClient: web);
      await expectLater(
        ds.vote(fullname: 't3_a', dir: VoteDir.up),
        throwsA(
          predicate(
            (e) => e is RedditException && e.message == 'you are doing that too much',
          ),
        ),
      );
    });

    test('USER_REQUIRED refreshes the modhash once then rethrows', () async {
      final web = _FakeWebClient()
        ..postResult = {
          'json': {
            'errors': [
              ['USER_REQUIRED', 'please log in'],
            ],
          },
        };
      final ds = RedditInteractionsDataSourceImpl(webClient: web);
      await expectLater(
        ds.vote(fullname: 't3_a', dir: VoteDir.up),
        throwsA(isA<RedditException>()),
      );
      expect(web.meCalls, 2); // refetched once before giving up
    });
  });

  group('InteractionsRepositoryImpl mapping', () {
    test('bare success → Right(unit); RedditException → Left(RedditFailure)', () async {
      final ds = _StubDataSource();
      final repo = InteractionsRepositoryImpl(dataSource: ds);

      expect((await repo.vote(fullname: 't3_a', dir: VoteDir.up)).isRight(), isTrue);

      ds.error = const RedditException('boom');
      final r = await repo.vote(fullname: 't3_a', dir: VoteDir.up);
      r.fold((f) => expect(f, isA<RedditFailure>()), (_) => fail('expected Left'));
    });

    test('NotAuthenticatedException → NotAuthenticatedFailure', () async {
      final ds = _StubDataSource()..error = const NotAuthenticatedException();
      final repo = InteractionsRepositoryImpl(dataSource: ds);
      final r = await repo.setSaved(fullname: 't3_a', saved: true);
      r.fold(
        (f) => expect(f, isA<NotAuthenticatedFailure>()),
        (_) => fail('expected Left'),
      );
    });
  });
}

class _FakeWebClient extends RedditWebClient {
  String? modhash = 'MH';
  dynamic postResult = const <String, dynamic>{}; // {} = success
  String? lastPath;
  Map<String, String>? lastFields;
  String? lastModhash;
  int meCalls = 0;

  @override
  Future<dynamic> getJson(String path, {Map<String, dynamic>? query}) async {
    if (path == '/api/me.json') {
      meCalls++;
      return {
        'data': {'modhash': modhash ?? ''},
      };
    }
    return const <String, dynamic>{};
  }

  @override
  Future<dynamic> postForm(
    String path, {
    required String modhash,
    Map<String, String> fields = const {},
  }) async {
    lastPath = path;
    lastFields = fields;
    lastModhash = modhash;
    return postResult;
  }
}

class _StubDataSource implements RedditInteractionsDataSource {
  Exception? error;

  Future<void> _maybeThrow() async {
    final e = error;
    if (e != null) throw e;
  }

  @override
  Future<void> vote({required String fullname, required VoteDir dir}) =>
      _maybeThrow();

  @override
  Future<void> setSaved({required String fullname, required bool saved}) =>
      _maybeThrow();

  @override
  Future<void> setSubscribed({
    required String srName,
    String? fullname,
    required bool subscribe,
  }) => _maybeThrow();
}
