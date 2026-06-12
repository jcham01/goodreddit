import 'package:dartz/dartz.dart';
import 'package:goodreddit/core/error/failures.dart';
import 'package:goodreddit/features/scraper/domain/entities/subreddit_content.dart';

abstract class ScraperRepository {
  /// Fetches the top posts for [subredditName] and the comments of the most
  /// popular posts.
  Future<Either<Failure, SubredditContent>> scrapeContent(
    String subredditName, {
    String timeFilter,
  });
}
