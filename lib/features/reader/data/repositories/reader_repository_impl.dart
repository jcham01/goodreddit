import 'package:dartz/dartz.dart';
import 'package:goodreddit/core/constants/api_constants.dart';
import 'package:goodreddit/core/error/exceptions.dart';
import 'package:goodreddit/core/error/failures.dart';
import 'package:goodreddit/features/reader/data/datasources/reddit_reader_datasource.dart';
import 'package:goodreddit/features/reader/domain/entities/comment_sort.dart';
import 'package:goodreddit/features/reader/domain/entities/feed_page.dart';
import 'package:goodreddit/features/reader/domain/entities/feed_source.dart';
import 'package:goodreddit/features/reader/domain/entities/post_detail.dart';
import 'package:goodreddit/features/reader/domain/repositories/reader_repository.dart';

class ReaderRepositoryImpl implements ReaderRepository {
  final RedditReaderDataSource dataSource;

  ReaderRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, FeedPage>> getFeed({
    required FeedSource source,
    String? after,
    int limit = ApiConstants.defaultFeedLimit,
  }) async {
    try {
      final path = switch (source) {
        FeedSource.home => ApiConstants.homeFeedPath,
        FeedSource.popular => ApiConstants.popularFeedPath,
      };
      final page = await dataSource.getFeed(
        path: path,
        after: after,
        limit: limit,
      );
      return Right(page);
    } on NotAuthenticatedException catch (e) {
      return Left(NotAuthenticatedFailure(e.message));
    } on RedditException catch (e) {
      return Left(RedditFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PostDetail>> getPostDetail({
    required String subreddit,
    required String postId,
    CommentSort sort = CommentSort.best,
    int limit = ApiConstants.defaultCommentLimit,
  }) async {
    try {
      final detail = await dataSource.getPostDetail(
        subreddit: subreddit,
        postId: postId,
        sort: sort.apiValue,
        limit: limit,
      );
      return Right(detail);
    } on NotAuthenticatedException catch (e) {
      return Left(NotAuthenticatedFailure(e.message));
    } on RedditException catch (e) {
      return Left(RedditFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
