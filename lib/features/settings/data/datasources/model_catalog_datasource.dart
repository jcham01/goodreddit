import 'package:dio/dio.dart';
import 'package:goodreddit/core/constants/api_constants.dart';
import 'package:goodreddit/core/error/exceptions.dart';
import 'package:goodreddit/features/settings/data/datasources/codex_auth_datasource.dart';
import 'package:goodreddit/features/settings/domain/entities/agent_config.dart';

/// Fetches the live list of model ids from the configured provider's
/// list-models endpoint, using the user's API key (or the Codex session).
abstract class ModelCatalogDataSource {
  Future<List<String>> fetchModels(LlmProvider provider, String apiKey);
}

class ModelCatalogDataSourceImpl implements ModelCatalogDataSource {
  final Dio dio;
  final CodexCaller codex;

  ModelCatalogDataSourceImpl({required this.dio, required this.codex});

  @override
  Future<List<String>> fetchModels(LlmProvider provider, String apiKey) async {
    try {
      switch (provider) {
        case LlmProvider.claude:
          return await _fetchAnthropic(apiKey);
        case LlmProvider.openai:
          return await _fetchOpenai(apiKey);
        case LlmProvider.google:
          return await _fetchGoogle(apiKey);
        case LlmProvider.openaiCodex:
          // Live (best-effort) via the Codex session; [] degrades to fallback.
          return await codex.listModels();
      }
    } on DioException catch (e) {
      throw LlmException('Failed to list models: ${e.message}');
    }
  }

  Future<List<String>> _fetchAnthropic(String apiKey) async {
    final response = await dio.get<Map<String, dynamic>>(
      ApiConstants.anthropicModelsUrl,
      options: Options(
        headers: {
          'x-api-key': apiKey,
          'anthropic-version': ApiConstants.claudeApiVersion,
        },
      ),
    );
    final data = (response.data?['data'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    return data.map((m) => m['id'] as String).toList();
  }

  Future<List<String>> _fetchOpenai(String apiKey) async {
    final response = await dio.get<Map<String, dynamic>>(
      ApiConstants.openaiModelsUrl,
      options: Options(headers: {'Authorization': 'Bearer $apiKey'}),
    );
    final data = (response.data?['data'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    // The endpoint also lists embedding/audio/image models — keep chat ones.
    final chatLike = RegExp(r'^(gpt-|o\d)');
    return data.map((m) => m['id'] as String).where(chatLike.hasMatch).toList()
      ..sort();
  }

  Future<List<String>> _fetchGoogle(String apiKey) async {
    final response = await dio.get<Map<String, dynamic>>(
      ApiConstants.googleApiUrl,
      queryParameters: {'key': apiKey, 'pageSize': 200},
    );
    final models = (response.data?['models'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    return models
        .where(
          (m) =>
              ((m['supportedGenerationMethods'] as List<dynamic>?) ?? const [])
                  .contains('generateContent'),
        )
        .map((m) => (m['name'] as String).replaceFirst('models/', ''))
        .toList();
  }
}
