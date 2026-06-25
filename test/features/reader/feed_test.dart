import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goodreddit/core/error/failures.dart';
import 'package:goodreddit/features/reader/data/models/feed_page_model.dart';
import 'package:goodreddit/features/reader/domain/entities/comment_sort.dart';
import 'package:goodreddit/features/reader/domain/entities/feed_page.dart';
import 'package:goodreddit/features/reader/domain/entities/feed_source.dart';
import 'package:goodreddit/features/reader/domain/entities/post_detail.dart';
import 'package:goodreddit/features/reader/domain/entities/subreddit_about.dart';
import 'package:goodreddit/features/reader/domain/entities/subreddit_sort.dart';
import 'package:goodreddit/features/reader/domain/repositories/reader_repository.dart';
import 'package:goodreddit/features/reader/domain/usecases/get_feed.dart';
import 'package:goodreddit/features/reader/presentation/bloc/feed_cubit.dart';
import 'package:goodreddit/features/scraper/domain/entities/post.dart';

Post _post(String id) => Post(
  id: id,
  title: id.toUpperCase(),
  selfText: '',
  author: 'u',
  score: 1,
  numComments: 0,
  url: '',
  permalink: '/r/x/comments/$id',
  createdAt: DateTime(2020),
  subreddit: 'x',
);

class _FakeReaderRepository implements ReaderRepository {
  final List<FeedPage> pages;
  int calls = 0;
  _FakeReaderRepository(this.pages);

  @override
  Future<Either<Failure, FeedPage>> getFeed({
    required FeedSource source,
    String? after,
    int limit = 25,
  }) async {
    return Right(pages[calls++ % pages.length]);
  }

  @override
  Future<Either<Failure, PostDetail>> getPostDetail({
    required String subreddit,
    required String postId,
    CommentSort sort = CommentSort.best,
    int limit = 50,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, FeedPage>> getSubredditFeed({
    required String subreddit,
    SubredditSort sort = SubredditSort.hot,
    String? after,
    int limit = 25,
  }) async => throw UnimplementedError();

  @override
  Future<Either<Failure, SubredditAbout>> getSubredditAbout(
    String subreddit,
  ) async => throw UnimplementedError();
}

void main() {
  group('FeedPageModel.fromListing', () {
    test('keeps only t3 children and reads the after cursor', () {
      final page = FeedPageModel.fromListing({
        'data': {
          'after': 't3_next',
          'children': [
            {
              'kind': 't3',
              'data': {'id': 'a', 'title': 'A', 'subreddit': 'x'},
            },
            {
              'kind': 't1',
              'data': {'id': 'c'},
            },
          ],
        },
      });
      expect(page.posts.length, 1);
      expect(page.posts.first.id, 'a');
      expect(page.hasMore, isTrue);
      expect(page.after, 't3_next');
    });

    test('no after cursor means no more pages', () {
      final page = FeedPageModel.fromListing({
        'data': {'after': null, 'children': []},
      });
      expect(page.posts, isEmpty);
      expect(page.hasMore, isFalse);
    });
  });

  group('FeedCubit', () {
    test('load then loadMore appends posts and tracks the cursor', () async {
      final repo = _FakeReaderRepository([
        FeedPage(posts: [_post('a')], after: 't3_a'),
        const FeedPage(posts: [], after: null),
      ]);
      repo.pages[1] = FeedPage(posts: [_post('b')], after: null);
      final cubit = FeedCubit(getFeed: GetFeed(repo));

      await cubit.load();
      expect(cubit.state.status, FeedStatus.loaded);
      expect(cubit.state.posts.map((p) => p.id), ['a']);
      expect(cubit.state.hasMore, isTrue);

      await cubit.loadMore();
      expect(cubit.state.posts.map((p) => p.id), ['a', 'b']);
      expect(cubit.state.hasMore, isFalse);

      await cubit.close();
    });

    test('switching source reloads the feed', () async {
      final repo = _FakeReaderRepository([
        FeedPage(posts: [_post('home')], after: null),
        FeedPage(posts: [_post('pop')], after: null),
      ]);
      final cubit = FeedCubit(getFeed: GetFeed(repo));

      await cubit.load(); // home
      expect(cubit.state.source, FeedSource.home);
      expect(cubit.state.posts.single.id, 'home');

      cubit.setSource(FeedSource.popular);
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.source, FeedSource.popular);
      expect(cubit.state.posts.single.id, 'pop');

      await cubit.close();
    });
  });
}
