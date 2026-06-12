import 'package:dartz/dartz.dart';
import 'package:goodreddit/core/error/exceptions.dart';
import 'package:goodreddit/core/error/failures.dart';
import 'package:goodreddit/features/scraper/data/datasources/reddit_scraper_datasource.dart';
import 'package:goodreddit/features/scraper/data/models/comment_model.dart';
import 'package:goodreddit/features/scraper/domain/entities/subreddit_content.dart';
import 'package:goodreddit/features/scraper/domain/repositories/scraper_repository.dart';

class ScraperRepositoryImpl implements ScraperRepository {
  final RedditScraperDataSource dataSource;

  /// Number of top posts whose comment threads we also fetch.
  static const _commentedPostCount = 5;

  /// Spacing between comment-thread fetches, to stay friendly to Reddit.
  static const _interRequestDelay = Duration(milliseconds: 500);

  ScraperRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, SubredditContent>> scrapeContent(
    String subredditName, {
    String timeFilter = 'week',
  }) async {
    try {
      final posts = await dataSource.getTopPosts(
        subredditName,
        timeFilter: timeFilter,
      );

      final comments = <CommentModel>[];
      for (final post in posts.take(_commentedPostCount)) {
        final postComments =
            await dataSource.getPostComments(subredditName, post.id);
        comments.addAll(postComments);
        await Future.delayed(_interRequestDelay);
      }

      return Right(SubredditContent(posts: posts, comments: comments));
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
