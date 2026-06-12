import 'package:dio/dio.dart';
import 'package:goodreddit/core/constants/api_constants.dart';
import 'package:goodreddit/core/error/exceptions.dart';
import 'package:goodreddit/features/settings/domain/entities/agent_config.dart';

abstract class LlmGeneratorDataSource {
  Future<String> generateContent({
    required String prompt,
    required AgentConfig config,
  });
}

class LlmGeneratorDataSourceImpl implements LlmGeneratorDataSource {
  final Dio dio;

  LlmGeneratorDataSourceImpl({required this.dio});

  @override
  Future<String> generateContent({
    required String prompt,
    required AgentConfig config,
  }) async {
    try {
      switch (config.provider) {
        case LlmProvider.claude:
          return await _callClaude(prompt, config);
        case LlmProvider.openai:
          return await _callOpenAI(prompt, config);
        case LlmProvider.google:
          return await _callGoogle(prompt, config);
      }
    } on DioException catch (e) {
      throw LlmException('LLM generation failed: ${e.message}');
    } catch (e) {
      if (e is LlmException) rethrow;
      throw LlmException('LLM generation failed: $e');
    }
  }

  Future<String> _callClaude(String prompt, AgentConfig config) async {
    final response = await dio.post(
      ApiConstants.claudeApiUrl,
      data: {
        'model': config.effectiveModel,
        'max_tokens': 4096,
        'messages': [
          {'role': 'user', 'content': prompt},
        ],
      },
      options: Options(
        headers: {
          'x-api-key': config.apiKey,
          'anthropic-version': ApiConstants.claudeApiVersion,
          'content-type': 'application/json',
        },
      ),
    );
    return response.data['content'][0]['text'] as String;
  }

  Future<String> _callOpenAI(String prompt, AgentConfig config) async {
    final response = await dio.post(
      ApiConstants.openaiApiUrl,
      data: {
        'model': config.effectiveModel,
        'messages': [
          {'role': 'user', 'content': prompt},
        ],
        'temperature': 0.7,
      },
      options: Options(
        headers: {
          'Authorization': 'Bearer ${config.apiKey}',
          'Content-Type': 'application/json',
        },
      ),
    );
    return response.data['choices'][0]['message']['content'] as String;
  }

  Future<String> _callGoogle(String prompt, AgentConfig config) async {
    final url =
        '${ApiConstants.googleApiUrl}/${config.effectiveModel}:generateContent?key=${config.apiKey}';
    final response = await dio.post(
      url,
      data: {
        'contents': [
          {
            'parts': [
              {'text': prompt},
            ],
          },
        ],
        'generationConfig': {'temperature': 0.7},
      },
      options: Options(headers: {'Content-Type': 'application/json'}),
    );
    return response.data['candidates'][0]['content']['parts'][0]['text']
        as String;
  }
}
