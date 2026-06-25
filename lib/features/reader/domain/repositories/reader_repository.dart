import 'package:dartz/dartz.dart';
import 'package:goodreddit/core/constants/api_constants.dart';
import 'package:goodreddit/core/error/failures.dart';
import 'package:goodreddit/features/reader/domain/entities/comment_sort.dart';
import 'package:goodreddit/features/reader/domain/entities/feed_page.dart';
import 'package:goodreddit/features/reader/domain/entities/feed_source.dart';
import 'package:goodreddit/features/reader/domain/entities/post_detail.dart';
import 'package:goodreddit/features/reader/domain/entities/subreddit_about.dart';
import 'package:goodreddit/features/reader/domain/entities/subreddit_sort.dart';

abstract class ReaderRepository {
  Future<Either<Failure, FeedPage>> getFeed({
    required FeedSource source,
    String? after,
    int limit = ApiConstants.defaultFeedLimit,
  });

  Future<Either<Failure, PostDetail>> getPostDetail({
    required String subreddit,
    required String postId,
    CommentSort sort = CommentSort.best,
    int limit = ApiConstants.defaultCommentLimit,
  });

  Future<Either<Failure, FeedPage>> getSubredditFeed({
    required String subreddit,
    SubredditSort sort = SubredditSort.hot,
    String? after,
    int limit = ApiConstants.defaultFeedLimit,
  });

  Future<Either<Failure, SubredditAbout>> getSubredditAbout(String subreddit);
}
