import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goodreddit/core/error/exceptions.dart';
import 'package:goodreddit/core/error/failures.dart';
import 'package:goodreddit/features/reader/data/datasources/reddit_reader_datasource.dart';
import 'package:goodreddit/features/reader/data/models/feed_page_model.dart';
import 'package:goodreddit/features/reader/data/models/post_detail_model.dart';
import 'package:goodreddit/features/reader/data/models/subreddit_about_model.dart';
import 'package:goodreddit/features/reader/data/repositories/reader_repository_impl.dart';
import 'package:goodreddit/features/reader/domain/entities/comment_sort.dart';
import 'package:goodreddit/features/reader/domain/entities/feed_page.dart';
import 'package:goodreddit/features/reader/domain/entities/feed_source.dart';
import 'package:goodreddit/features/reader/domain/entities/post_detail.dart';
import 'package:goodreddit/features/reader/domain/entities/subreddit_about.dart';
import 'package:goodreddit/features/reader/domain/entities/subreddit_sort.dart';
import 'package:goodreddit/features/reader/domain/repositories/reader_repository.dart';
import 'package:goodreddit/features/reader/domain/usecases/get_subreddit_about.dart';
import 'package:goodreddit/features/reader/domain/usecases/get_subreddit_feed.dart';
import 'package:goodreddit/features/reader/presentation/bloc/subreddit_cubit.dart';
import 'package:goodreddit/features/scraper/domain/entities/post.dart';

Post _post(String id) => Post(
  id: id,
  title: id,
  selfText: '',
  author: 'u',
  score: 1,
  numComments: 0,
  url: '',
  permalink: '/r/x/comments/$id',
  createdAt: DateTime(2020),
  subreddit: 'x',
);

void main() {
  group('SubredditAboutModel.fromJson', () {
    test('parses a t5 thing, decoding and falling back the icon', () {
      final about = SubredditAboutModel.fromJson({
        'kind': 't5',
        'data': {
          'display_name': 'flutterdev',
          'title': 'Flutter Dev',
          'public_description': 'A community',
          'subscribers': 123456,
          'active_user_count': 789,
          'community_icon': 'https://styles/icon.png?w=1&amp;s=abc',
          'over18': false,
        },
      });
      expect(about.name, 'flutterdev');
      expect(about.subscribers, 123456);
      expect(about.activeUsers, 789);
      expect(about.iconUrl, 'https://styles/icon.png?w=1&s=abc');
      expect(about.over18, isFalse);
    });

    test('falls back to icon_img when community_icon is empty', () {
      final about = SubredditAboutModel.fromJson({
        'data': {
          'display_name': 'x',
          'community_icon': '',
          'icon_img': 'https://i/icon.png',
          'over_18': true,
        },
      });
      expect(about.iconUrl, 'https://i/icon.png');
      expect(about.over18, isTrue);
    });

    test('throws when the sub does not exist (Listing body)', () {
      expect(
        () => SubredditAboutModel.fromJson({
          'kind': 'Listing',
          'data': {'children': []},
        }),
        throwsA(isA<RedditException>()),
      );
    });
  });

  group('ReaderRepositoryImpl.getSubredditFeed', () {
    test('sends a time window only for the Top sort', () async {
      final ds = _CapturingDataSource();
      final repo = ReaderRepositoryImpl(dataSource: ds);

      await repo.getSubredditFeed(subreddit: 'x', sort: SubredditSort.hot);
      expect(ds.lastSort, 'hot');
      expect(ds.lastTimeFilter, isNull);

      await repo.getSubredditFeed(subreddit: 'x', sort: SubredditSort.top);
      expect(ds.lastSort, 'top');
      expect(ds.lastTimeFilter, isNotNull); // 'week'
    });
  });

  group('SubredditCubit', () {
    test('load fetches the about header and the first listing page', () async {
      final repo = _FakeReaderRepository(
        pages: [
          FeedPage(posts: [_post('a')], after: 't3_a'),
          FeedPage(posts: [_post('b')], after: null),
        ],
        about: const SubredditAbout(name: 'x', subscribers: 10),
      );
      final cubit = SubredditCubit(
        getFeed: GetSubredditFeed(repo),
        getAbout: GetSubredditAbout(repo),
        name: 'x',
      );

      await cubit.load();
      await Future<void>.delayed(Duration.zero); // let _loadAbout settle
      expect(cubit.state.status, SubredditStatus.loaded);
      expect(cubit.state.posts.map((p) => p.id), ['a']);
      expect(cubit.state.hasMore, isTrue);
      expect(cubit.state.about?.subscribers, 10);

      await cubit.loadMore();
      expect(cubit.state.posts.map((p) => p.id), ['a', 'b']);
      expect(cubit.state.hasMore, isFalse);
      expect(repo.lastAfter, 't3_a');

      await cubit.close();
    });

    test('setSort reloads with the new order', () async {
      final repo = _FakeReaderRepository(
        pages: [
          FeedPage(posts: [_post('hot')], after: null),
          FeedPage(posts: [_post('top')], after: null),
        ],
      );
      final cubit = SubredditCubit(
        getFeed: GetSubredditFeed(repo),
        getAbout: GetSubredditAbout(repo),
        name: 'x',
      );

      await cubit.load();
      expect(cubit.state.sort, SubredditSort.hot);

      cubit.setSort(SubredditSort.top);
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.sort, SubredditSort.top);
      expect(cubit.state.posts.single.id, 'top');
      expect(repo.lastSort, SubredditSort.top);

      await cubit.close();
    });

    test('fetches the about header only once across refreshes', () async {
      final repo = _FakeReaderRepository(
        pages: [const FeedPage(posts: [], after: null)],
        about: const SubredditAbout(name: 'x', subscribers: 5),
      );
      final cubit = SubredditCubit(
        getFeed: GetSubredditFeed(repo),
        getAbout: GetSubredditAbout(repo),
        name: 'x',
      );

      await cubit.load();
      await Future<void>.delayed(Duration.zero);
      await cubit.refresh();
      await Future<void>.delayed(Duration.zero);
      expect(repo.aboutCalls, 1); // static header, fetched once

      await cubit.close();
    });

    test('surfaces an auth failure as needsAuth', () async {
      final repo = _FakeReaderRepository(
        pages: const [],
        feedFailure: const NotAuthenticatedFailure('nope'),
      );
      final cubit = SubredditCubit(
        getFeed: GetSubredditFeed(repo),
        getAbout: GetSubredditAbout(repo),
        name: 'x',
      );

      await cubit.load();
      expect(cubit.state.status, SubredditStatus.error);
      expect(cubit.state.needsAuth, isTrue);

      await cubit.close();
    });
  });
}

class _CapturingDataSource implements RedditReaderDataSource {
  String? lastSort;
  String? lastTimeFilter;

  @override
  Future<FeedPageModel> getSubredditFeed({
    required String subreddit,
    required String sort,
    String? timeFilter,
    String? after,
    int limit = 25,
  }) async {
    lastSort = sort;
    lastTimeFilter = timeFilter;
    return const FeedPageModel(posts: []);
  }

  @override
  Future<FeedPageModel> getFeed({
    required String path,
    String? after,
    int limit = 25,
  }) async => throw UnimplementedError();

  @override
  Future<PostDetailModel> getPostDetail({
    required String subreddit,
    required String postId,
    required String sort,
    int limit = 50,
  }) async => throw UnimplementedError();

  @override
  Future<SubredditAboutModel> getSubredditAbout(String subreddit) async =>
      throw UnimplementedError();
}

class _FakeReaderRepository implements ReaderRepository {
  final List<FeedPage> pages;
  final SubredditAbout? about;
  final Failure? feedFailure;
  int feedCalls = 0;
  int aboutCalls = 0;
  SubredditSort? lastSort;
  String? lastAfter;

  _FakeReaderRepository({required this.pages, this.about, this.feedFailure});

  @override
  Future<Either<Failure, FeedPage>> getSubredditFeed({
    required String subreddit,
    SubredditSort sort = SubredditSort.hot,
    String? after,
    int limit = 25,
  }) async {
    lastSort = sort;
    lastAfter = after;
    if (feedFailure != null) return Left(feedFailure!);
    return Right(pages[feedCalls++ % pages.length]);
  }

  @override
  Future<Either<Failure, SubredditAbout>> getSubredditAbout(
    String subreddit,
  ) async {
    aboutCalls++;
    final a = about;
    return a == null ? const Left(RedditFailure('no about')) : Right(a);
  }

  @override
  Future<Either<Failure, FeedPage>> getFeed({
    required FeedSource source,
    String? after,
    int limit = 25,
  }) async => throw UnimplementedError();

  @override
  Future<Either<Failure, PostDetail>> getPostDetail({
    required String subreddit,
    required String postId,
    CommentSort sort = CommentSort.best,
    int limit = 50,
  }) async => throw UnimplementedError();
}
