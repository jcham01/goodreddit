import 'package:dartz/dartz.dart';
import 'package:goodreddit/core/error/failures.dart';
import 'package:goodreddit/features/search/domain/entities/subreddit_score.dart';

abstract class SubredditRepository {
  /// Searches subreddits for [query], scores them with the composite ranker,
  /// and — when an LLM is configured — refines the ranking with a semantic
  /// score. Results are returned sorted by total score, best first.
  Future<Either<Failure, List<SubredditScore>>> searchAndRank(String query);
}
