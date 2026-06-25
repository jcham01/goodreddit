import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goodreddit/core/error/failures.dart';
import 'package:goodreddit/core/util/thread.dart';
import 'package:goodreddit/features/reader/data/models/post_detail_model.dart';
import 'package:goodreddit/features/reader/domain/entities/comment_sort.dart';
import 'package:goodreddit/features/reader/domain/entities/feed_page.dart';
import 'package:goodreddit/features/reader/domain/entities/feed_source.dart';
import 'package:goodreddit/features/reader/domain/entities/post_detail.dart';
import 'package:goodreddit/features/reader/domain/entities/post_media.dart';
import 'package:goodreddit/features/reader/domain/entities/thread_item.dart';
import 'package:goodreddit/features/reader/domain/repositories/reader_repository.dart';
import 'package:goodreddit/features/reader/domain/usecases/get_post_detail.dart';
import 'package:goodreddit/features/reader/presentation/bloc/post_detail_cubit.dart';
import 'package:goodreddit/features/scraper/domain/entities/post.dart';

Map<String, dynamic> _listing(List children) => {
  'kind': 'Listing',
  'data': {'children': children},
};

List _response(Map<String, dynamic> postData, [List comments = const []]) => [
  _listing([
    {'kind': 't3', 'data': postData},
  ]),
  _listing(comments),
];

CommentNode _c(String id, int depth) => CommentNode(
  id: id,
  author: 'a',
  body: 'b',
  score: 0,
  createdAt: DateTime(2020),
  depth: depth,
);

void main() {
  group('PostDetailModel.fromResponse — comment flattening', () {
    test('flattens nested replies depth-first with computed depth', () {
      final detail = PostDetailModel.fromResponse(
        _response({'id': 'p1', 'is_self': true}, [
          {
            'kind': 't1',
            'data': {
              'id': 'c1',
              'author': 'u1',
              'body': 'top',
              'score': 5,
              'created_utc': 0,
              'is_submitter': true,
              'replies': _listing([
                {
                  'kind': 't1',
                  'data': {
                    'id': 'c2',
                    'author': 'u2',
                    'body': 'reply',
                    'score': 2,
                    'created_utc': 0,
                  },
                },
                {
                  'kind': 'more',
                  'data': {'count': 3},
                },
              ]),
            },
          },
          {
            'kind': 't1',
            'data': {
              'id': 'c3',
              'author': 'u3',
              'body': 'second top',
              'score': 1,
              'created_utc': 0,
              'replies': '',
            },
          },
          {
            'kind': 'more',
            'data': {'count': 0}, // synthetic "continue thread" → skipped
          },
        ]),
      );

      final thread = detail.thread;
      expect(thread.length, 4);
      expect(thread[0], isA<CommentNode>());
      expect((thread[0] as CommentNode).id, 'c1');
      expect(thread[0].depth, 0);
      expect((thread[0] as CommentNode).isSubmitter, isTrue);
      expect((thread[1] as CommentNode).id, 'c2');
      expect(thread[1].depth, 1);
      expect(thread[2], isA<MoreNode>());
      expect((thread[2] as MoreNode).count, 3);
      expect(thread[2].depth, 1);
      expect((thread[3] as CommentNode).id, 'c3');
      expect(thread[3].depth, 0);
      expect(detail.commentCount, 3); // MoreNode excluded
    });

    test('throws on an unexpected response shape', () {
      expect(
        () => PostDetailModel.fromResponse({'not': 'a list'}),
        throwsA(isA<Object>()),
      );
    });
  });

  group('PostDetailModel.fromResponse — media resolution', () {
    test('native gallery yields ordered, entity-decoded images', () {
      final detail = PostDetailModel.fromResponse(
        _response({
          'id': 'p',
          'is_gallery': true,
          'gallery_data': {
            'items': [
              {'media_id': 'm1'},
              {'media_id': 'm2'},
            ],
          },
          'media_metadata': {
            'm1': {
              's': {'u': 'https://i.redd.it/m1.jpg?w=1&amp;s=x', 'x': 100, 'y': 200},
            },
            'm2': {
              's': {'u': 'https://i.redd.it/m2.jpg'},
            },
          },
        }),
      );
      expect(detail.media.kind, MediaKind.gallery);
      expect(detail.media.images.length, 2);
      expect(detail.media.images.first.url, 'https://i.redd.it/m1.jpg?w=1&s=x');
      expect(detail.media.images.first.width, 100);
      expect(detail.media.images.first.height, 200);
    });

    test('direct image post uses the url', () {
      final detail = PostDetailModel.fromResponse(
        _response({
          'id': 'p',
          'post_hint': 'image',
          'url': 'https://i.redd.it/abc.jpg',
        }),
      );
      expect(detail.media.kind, MediaKind.image);
      expect(detail.media.images.single.url, 'https://i.redd.it/abc.jpg');
    });

    test('external link keeps the url and a decoded preview thumbnail', () {
      final detail = PostDetailModel.fromResponse(
        _response({
          'id': 'p',
          'url': 'https://example.com/article',
          'preview': {
            'images': [
              {
                'source': {'url': 'https://prev.example/i.jpg?a&amp;b'},
              },
            ],
          },
        }),
      );
      expect(detail.media.kind, MediaKind.link);
      expect(detail.media.externalUrl, 'https://example.com/article');
      expect(detail.media.previewUrl, 'https://prev.example/i.jpg?a&b');
    });

    test('self post has no media block', () {
      final detail = PostDetailModel.fromResponse(
        _response({'id': 'p', 'is_self': true, 'selftext': 'hello'}),
      );
      expect(detail.media.kind, MediaKind.none);
    });

    test('video post is opened externally with a poster', () {
      final detail = PostDetailModel.fromResponse(
        _response({
          'id': 'p',
          'is_video': true,
          'url': 'https://v.redd.it/xyz',
          'preview': {
            'images': [
              {
                'source': {'url': 'https://prev/poster.jpg'},
              },
            ],
          },
        }),
      );
      expect(detail.media.kind, MediaKind.video);
      expect(detail.media.externalUrl, 'https://v.redd.it/xyz');
      expect(detail.media.previewUrl, 'https://prev/poster.jpg');
    });

    test('direct image keeps preview dimensions for a correct aspect ratio', () {
      final detail = PostDetailModel.fromResponse(
        _response({
          'id': 'p',
          'post_hint': 'image',
          'url': 'https://i.redd.it/abc.jpg',
          'preview': {
            'images': [
              {
                'source': {
                  'url': 'https://prev/i.jpg?a&amp;b',
                  'width': 800,
                  'height': 1200,
                },
              },
            ],
          },
        }),
      );
      expect(detail.media.kind, MediaKind.image);
      expect(detail.media.images.single.url, 'https://i.redd.it/abc.jpg');
      expect(detail.media.images.single.width, 800);
      expect(detail.media.images.single.height, 1200);
    });

    test('crosspost resolves media from the parent submission', () {
      final detail = PostDetailModel.fromResponse(
        _response({
          'id': 'p',
          'url': 'https://www.reddit.com/r/orig/comments/x/title/',
          'crosspost_parent_list': [
            {
              'post_hint': 'image',
              'url': 'https://i.redd.it/parent.jpg',
            },
          ],
        }),
      );
      expect(detail.media.kind, MediaKind.image);
      expect(detail.media.images.single.url, 'https://i.redd.it/parent.jpg');
    });

    test('mp4-only animated gallery item is kept via a still preview', () {
      final detail = PostDetailModel.fromResponse(
        _response({
          'id': 'p',
          'is_gallery': true,
          'gallery_data': {
            'items': [
              {'media_id': 'm1'},
              {'media_id': 'm2'},
            ],
          },
          'media_metadata': {
            'm1': {
              'e': 'AnimatedImage',
              's': {'mp4': 'https://v/m1.mp4', 'x': 100, 'y': 100},
              'p': [
                {'u': 'https://p/m1a.jpg?a&amp;b', 'x': 50, 'y': 50},
                {'u': 'https://p/m1b.jpg', 'x': 100, 'y': 100},
              ],
            },
            'm2': {
              's': {'u': 'https://i/m2.jpg'},
            },
          },
        }),
      );
      expect(detail.media.kind, MediaKind.gallery);
      expect(detail.media.images.length, 2); // order/count preserved
      expect(detail.media.images.first.url, 'https://p/m1b.jpg');
      expect(detail.media.images[1].url, 'https://i/m2.jpg');
    });
  });

  group('thread collapse helpers', () {
    final thread = [_c('c1', 0), _c('c2', 1), _c('c3', 2), _c('c4', 0)];

    test('descendantCount counts every nested reply', () {
      expect(descendantCount(thread, 0), 2); // c2 + c3
      expect(descendantCount(thread, 1), 1); // c3
      expect(descendantCount(thread, 3), 0); // leaf
    });

    test('collapsing a comment hides its whole subtree', () {
      final visible = visibleThread(thread, {'c1'});
      expect(visible.map((i) => (i as CommentNode).id), ['c1', 'c4']);
    });

    test('no collapsed ids returns the list unchanged', () {
      expect(visibleThread(thread, const {}), same(thread));
    });
  });

  group('PostDetailCubit', () {
    final seed = Post(
      id: 'p1',
      title: 'T',
      selfText: '',
      author: 'u',
      score: 1,
      numComments: 0,
      url: '',
      permalink: '/r/x/comments/p1',
      createdAt: DateTime(2020),
      subreddit: 'x',
    );

    test('load populates detail; setSort re-fetches with the new order', () async {
      final repo = _FakeReaderRepository();
      final cubit = PostDetailCubit(
        getPostDetail: GetPostDetail(repo),
        seed: seed,
      );

      await cubit.load();
      expect(cubit.state.status, PostDetailStatus.loaded);
      expect(cubit.state.detail, isNotNull);
      expect(repo.calls, 1);
      expect(repo.lastSort, CommentSort.best);

      cubit.setSort(CommentSort.newest);
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.sort, CommentSort.newest);
      expect(repo.calls, 2);
      expect(repo.lastSort, CommentSort.newest);

      // Re-selecting the same sort is a no-op.
      cubit.setSort(CommentSort.newest);
      await Future<void>.delayed(Duration.zero);
      expect(repo.calls, 2);

      await cubit.close();
    });

    test('a failed re-sort reverts the menu and keeps the old comments', () async {
      final repo = _FailSecondReaderRepository();
      final cubit = PostDetailCubit(
        getPostDetail: GetPostDetail(repo),
        seed: seed,
      );

      await cubit.load();
      expect(cubit.state.status, PostDetailStatus.loaded);
      expect(cubit.state.sort, CommentSort.best);

      cubit.setSort(CommentSort.newest);
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.status, PostDetailStatus.error);
      expect(cubit.state.detail, isNotNull); // old comments kept on screen
      expect(cubit.state.sort, CommentSort.best); // menu reverted to loaded sort

      await cubit.close();
    });
  });

  group('descendantCounts (linear)', () {
    test('matches per-node descendantCount for every comment', () {
      final thread = [
        _c('c1', 0),
        _c('c2', 1),
        _c('c3', 2),
        _c('c4', 0),
        _c('c5', 1),
      ];
      final bulk = descendantCounts(thread);
      for (var i = 0; i < thread.length; i++) {
        final node = thread[i];
        expect(bulk[node.id], descendantCount(thread, i), reason: node.id);
      }
      expect(bulk, {'c1': 2, 'c2': 1, 'c3': 0, 'c4': 1, 'c5': 0});
    });
  });
}

class _FailSecondReaderRepository implements ReaderRepository {
  int calls = 0;

  @override
  Future<Either<Failure, PostDetail>> getPostDetail({
    required String subreddit,
    required String postId,
    CommentSort sort = CommentSort.best,
    int limit = 50,
  }) async {
    calls++;
    if (calls >= 2) return const Left(RedditFailure('boom'));
    return Right(
      PostDetail(
        post: Post(
          id: postId,
          title: 'T',
          selfText: '',
          author: 'u',
          score: 1,
          numComments: 0,
          url: '',
          permalink: '/r/$subreddit/comments/$postId',
          createdAt: DateTime(2020),
          subreddit: subreddit,
        ),
        media: PostMedia.none,
        thread: const [],
      ),
    );
  }

  @override
  Future<Either<Failure, FeedPage>> getFeed({
    required FeedSource source,
    String? after,
    int limit = 25,
  }) async => throw UnimplementedError();
}

class _FakeReaderRepository implements ReaderRepository {
  int calls = 0;
  CommentSort? lastSort;

  @override
  Future<Either<Failure, PostDetail>> getPostDetail({
    required String subreddit,
    required String postId,
    CommentSort sort = CommentSort.best,
    int limit = 50,
  }) async {
    calls++;
    lastSort = sort;
    return Right(
      PostDetail(
        post: Post(
          id: postId,
          title: 'T',
          selfText: '',
          author: 'u',
          score: 1,
          numComments: 0,
          url: '',
          permalink: '/r/$subreddit/comments/$postId',
          createdAt: DateTime(2020),
          subreddit: subreddit,
        ),
        media: PostMedia.none,
        thread: const [],
      ),
    );
  }

  @override
  Future<Either<Failure, FeedPage>> getFeed({
    required FeedSource source,
    String? after,
    int limit = 25,
  }) async {
    throw UnimplementedError();
  }
}
