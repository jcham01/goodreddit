import 'package:dartz/dartz.dart';
import 'package:goodreddit/core/error/exceptions.dart';
import 'package:goodreddit/core/error/failures.dart';
import 'package:goodreddit/features/search/data/datasources/llm_ranking_datasource.dart';
import 'package:goodreddit/features/search/data/datasources/reddit_search_datasource.dart';
import 'package:goodreddit/features/search/data/models/subreddit_model.dart';
import 'package:goodreddit/features/search/data/models/subreddit_score_model.dart';
import 'package:goodreddit/features/search/domain/entities/subreddit_score.dart';
import 'package:goodreddit/features/search/domain/repositories/subreddit_repository.dart';
import 'package:goodreddit/features/settings/data/datasources/settings_local_datasource.dart';

class SubredditRepositoryImpl implements SubredditRepository {
  final RedditSearchDataSource searchDataSource;
  final LlmRankingDataSource llmRankingDataSource;
  final SettingsLocalDataSource settingsDataSource;

  SubredditRepositoryImpl({
    required this.searchDataSource,
    required this.llmRankingDataSource,
    required this.settingsDataSource,
  });

  @override
  Future<Either<Failure, List<SubredditScore>>> searchAndRank(
      String query) async {
    try {
      final subreddits = await searchDataSource.searchSubreddits(query);
      if (subreddits.isEmpty) {
        return const Right([]);
      }

      // Try to enrich with an LLM semantic score; degrade gracefully on failure
      // so a bad key or rate limit never breaks the base ranking.
      final semantic = await _semanticScores(query, subreddits);

      final scored = subreddits.map((sub) {
        final ranking = semantic[sub.name.toLowerCase()];
        return SubredditScoreModel.compute(
          subreddit: sub,
          query: query,
          semanticScore: ranking?.score ?? 0.0,
          llmReasoning: ranking?.reasoning,
        );
      }).toList()
        ..sort((a, b) => b.totalScore.compareTo(a.totalScore));

      return Right(scored);
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

  Future<Map<String, _Ranking>> _semanticScores(
    String query,
    List<SubredditModel> subreddits,
  ) async {
    try {
      final config = await settingsDataSource.getConfig();
      if (!config.isConfigured) return const {};

      final payload = subreddits
          .map((s) => {
                'name': s.name,
                'title': s.title,
                'subscribers': s.subscribers,
                'active_users': s.activeUsers,
                'description': s.description,
              })
          .toList();

      final response = await llmRankingDataSource.rankSubreddits(
        subreddits: payload,
        query: query,
        config: config,
      );

      final rankings = (response['rankings'] as List?) ?? const [];
      final map = <String, _Ranking>{};
      for (final r in rankings) {
        if (r is Map) {
          final name = (r['name'] as String?)?.toLowerCase();
          final score = (r['score'] as num?)?.toDouble();
          if (name != null && score != null) {
            map[name] = _Ranking(
              score: score.clamp(0.0, 1.0),
              reasoning: r['reasoning'] as String?,
            );
          }
        }
      }
      return map;
    } catch (_) {
      // LLM ranking is an optional enhancement — keep the base ranking.
      return const {};
    }
  }
}

class _Ranking {
  final double score;
  final String? reasoning;
  const _Ranking({required this.score, this.reasoning});
}
