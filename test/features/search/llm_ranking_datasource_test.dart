import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goodreddit/core/error/exceptions.dart';
import 'package:goodreddit/features/search/data/datasources/llm_ranking_datasource.dart';
import 'package:goodreddit/features/settings/data/datasources/codex_auth_datasource.dart';
import 'package:goodreddit/features/settings/domain/entities/agent_config.dart';

class _FakeCodexCaller implements CodexCaller {
  final String? response;
  final Object? error;
  const _FakeCodexCaller({this.response, this.error});

  @override
  Future<String> generateText(String prompt, {String? model}) async {
    if (error != null) throw error!;
    return response!;
  }

  @override
  Future<List<String>> listModels() async => const [];
}

void main() {
  const codexConfig = AgentConfig(
    provider: LlmProvider.openaiCodex,
    apiKey: '',
  );

  test('Codex provider routes ranking through the Codex caller', () async {
    final dataSource = LlmRankingDataSourceImpl(
      dio: Dio(),
      codex: const _FakeCodexCaller(
        response: '{"rankings": [{"name": "flutter", "score": 0.9}]}',
      ),
    );

    final result = await dataSource.rankSubreddits(
      subreddits: const [],
      query: 'flutter',
      config: codexConfig,
    );

    expect(result['rankings'], isA<List<dynamic>>());
    expect((result['rankings'] as List).first['name'], 'flutter');
  });

  test('Codex ranking surfaces the caller error (e.g. not signed in)', () async {
    final dataSource = LlmRankingDataSourceImpl(
      dio: Dio(),
      codex: const _FakeCodexCaller(
        error: LlmException('Codex : non connecté.'),
      ),
    );

    await expectLater(
      dataSource.rankSubreddits(
        subreddits: const [],
        query: 'flutter',
        config: codexConfig,
      ),
      throwsA(
        isA<LlmException>().having(
          (e) => e.message,
          'message',
          contains('non connecté'),
        ),
      ),
    );
  });
}
