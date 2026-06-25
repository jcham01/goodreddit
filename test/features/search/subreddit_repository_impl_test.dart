import 'package:flutter_test/flutter_test.dart';
import 'package:goodreddit/core/error/exceptions.dart';
import 'package:goodreddit/features/search/data/datasources/llm_ranking_datasource.dart';
import 'package:goodreddit/features/search/data/datasources/reddit_search_datasource.dart';
import 'package:goodreddit/features/search/data/models/subreddit_model.dart';
import 'package:goodreddit/features/search/data/repositories/subreddit_repository_impl.dart';
import 'package:goodreddit/features/search/domain/entities/search_ranking_result.dart';
import 'package:goodreddit/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:goodreddit/features/settings/domain/entities/agent_config.dart';

void main() {
  group('SubredditRepositoryImpl', () {
    test(
      'returns heuristic-only status when no LLM key is configured',
      () async {
        final llm = _FakeLlmRankingDataSource();
        final repository = _repository(
          settings: const AgentConfig.empty(),
          llm: llm,
        );

        final result = await repository.searchAndRank('flutter');
        final ranking = result.fold(
          (failure) => fail(failure.message),
          (r) => r,
        );

        expect(ranking.llmStatus, LlmRankingStatus.notConfigured);
        expect(ranking.modelUsed, isNull);
        expect(ranking.scores, isNotEmpty);
        expect(ranking.scores.every((s) => s.semanticScore == 0), isTrue);
        expect(llm.calls, 0);
      },
    );

    test(
      'returns applied status and semantic scores when LLM succeeds',
      () async {
        final repository = _repository(
          settings: const AgentConfig(
            provider: LlmProvider.claude,
            apiKey: 'test-key',
            model: 'claude-test',
          ),
          llm: _FakeLlmRankingDataSource(
            response: {
              'rankings': [
                {
                  'name': 'cooking',
                  'score': 0.9,
                  'reasoning': 'Strong community match',
                },
                {'name': 'flutterdev', 'score': 0.1},
              ],
            },
          ),
        );

        final result = await repository.searchAndRank('community');
        final ranking = result.fold(
          (failure) => fail(failure.message),
          (r) => r,
        );

        expect(ranking.llmStatus, LlmRankingStatus.applied);
        expect(ranking.modelUsed, 'claude-test');
        expect(ranking.llmErrorMessage, isNull);
        expect(ranking.scores.first.subreddit.name, 'cooking');
        expect(ranking.scores.first.semanticScore, 0.9);
        expect(ranking.scores.first.llmReasoning, 'Strong community match');
      },
    );

    test('falls back visibly to heuristics when LLM fails', () async {
      final llm = _FakeLlmRankingDataSource(
        failure: const LlmException('rate limited'),
      );
      final repository = _repository(
        settings: const AgentConfig(
          provider: LlmProvider.openai,
          apiKey: 'test-key',
          model: 'gpt-test',
        ),
        llm: llm,
      );

      final result = await repository.searchAndRank('flutter');
      final ranking = result.fold((failure) => fail(failure.message), (r) => r);

      expect(ranking.llmStatus, LlmRankingStatus.failed);
      expect(ranking.modelUsed, 'gpt-test');
      expect(ranking.llmErrorMessage, 'rate limited');
      expect(ranking.scores, isNotEmpty);
      expect(ranking.scores.every((s) => s.semanticScore == 0), isTrue);
      expect(llm.calls, 1);
    });

    test('joins semantic scores even when the LLM echoes an r/ prefix', () async {
      final repository = _repository(
        settings: const AgentConfig(
          provider: LlmProvider.claude,
          apiKey: 'test-key',
          model: 'claude-test',
        ),
        llm: _FakeLlmRankingDataSource(
          response: {
            'rankings': [
              {'name': 'r/cooking', 'score': 0.9},
              {'name': '/r/flutterdev', 'score': 0.2},
            ],
          },
        ),
      );

      final result = await repository.searchAndRank('community');
      final ranking = result.fold((failure) => fail(failure.message), (r) => r);

      final cooking = ranking.scores.firstWhere(
        (s) => s.subreddit.name == 'cooking',
      );
      final flutter = ranking.scores.firstWhere(
        (s) => s.subreddit.name == 'flutterdev',
      );
      expect(cooking.semanticScore, 0.9);
      expect(flutter.semanticScore, 0.2);
    });
  });
}

SubredditRepositoryImpl _repository({
  required AgentConfig settings,
  required _FakeLlmRankingDataSource llm,
}) {
  return SubredditRepositoryImpl(
    searchDataSource: _FakeRedditSearchDataSource(),
    llmRankingDataSource: llm,
    settingsDataSource: _FakeSettingsLocalDataSource(settings),
  );
}

class _FakeRedditSearchDataSource implements RedditSearchDataSource {
  @override
  Future<List<SubredditModel>> searchSubreddits(String query) async {
    return const [
      SubredditModel(
        name: 'flutterdev',
        displayName: 'r/flutterdev',
        title: 'Flutter development',
        description: 'A community about Flutter',
        subscribers: 100000,
        activeUsers: 500,
        url: '/r/flutterdev',
      ),
      SubredditModel(
        name: 'cooking',
        displayName: 'r/cooking',
        title: 'Cooking',
        description: 'A community about recipes',
        subscribers: 100000,
        activeUsers: 500,
        url: '/r/cooking',
      ),
    ];
  }
}

class _FakeLlmRankingDataSource implements LlmRankingDataSource {
  final Map<String, dynamic> response;
  final Object? failure;
  int calls = 0;

  _FakeLlmRankingDataSource({
    this.response = const {'rankings': []},
    this.failure,
  });

  @override
  Future<Map<String, dynamic>> rankSubreddits({
    required List<Map<String, dynamic>> subreddits,
    required String query,
    required AgentConfig config,
  }) async {
    calls += 1;
    final failure = this.failure;
    if (failure != null) throw failure;
    return response;
  }
}

class _FakeSettingsLocalDataSource implements SettingsLocalDataSource {
  final AgentConfig config;

  _FakeSettingsLocalDataSource(this.config);

  @override
  Future<void> clearConfig() async {}

  @override
  Future<AgentConfig> getConfig() async => config;

  @override
  Future<void> saveConfig(AgentConfig config) async {}
}
