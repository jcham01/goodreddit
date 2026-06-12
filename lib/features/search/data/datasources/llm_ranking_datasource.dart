import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:goodreddit/core/constants/api_constants.dart';
import 'package:goodreddit/core/error/exceptions.dart';
import 'package:goodreddit/features/settings/domain/entities/agent_config.dart';

/// Asks an LLM to rate each subreddit's semantic relevance to the query.
/// Returns the decoded `{"rankings": [{name, score, reasoning}, ...]}` map.
abstract class LlmRankingDataSource {
  Future<Map<String, dynamic>> rankSubreddits({
    required List<Map<String, dynamic>> subreddits,
    required String query,
    required AgentConfig config,
  });
}

class LlmRankingDataSourceImpl implements LlmRankingDataSource {
  final Dio dio;

  LlmRankingDataSourceImpl({required this.dio});

  @override
  Future<Map<String, dynamic>> rankSubreddits({
    required List<Map<String, dynamic>> subreddits,
    required String query,
    required AgentConfig config,
  }) async {
    try {
      final prompt = _buildRankingPrompt(subreddits, query);
      switch (config.provider) {
        case LlmProvider.claude:
          return await _callClaude(prompt, config);
        case LlmProvider.openai:
          return await _callOpenAI(prompt, config);
        case LlmProvider.google:
          return await _callGoogle(prompt, config);
      }
    } on DioException catch (e) {
      throw LlmException('LLM API call failed: ${e.message}');
    } catch (e) {
      if (e is LlmException) rethrow;
      throw LlmException('LLM ranking failed: $e');
    }
  }

  String _buildRankingPrompt(
    List<Map<String, dynamic>> subreddits,
    String query,
  ) {
    final subList = subreddits
        .map((s) {
          return '- r/${s['name']}: "${s['title']}" (${s['subscribers']} subscribers, '
              '${s['active_users']} active). Description: ${s['description']}';
        })
        .join('\n');

    return '''You are an expert at evaluating subreddit relevance.
Given the search query "$query", rank these subreddits by semantic relevance.
For each subreddit, provide a score from 0.0 to 1.0 and a brief reasoning.

Subreddits:
$subList

Respond in this exact JSON format:
{
  "rankings": [
    {"name": "subreddit_name", "score": 0.85, "reasoning": "Brief explanation"}
  ]
}

Only output the JSON, no other text.''';
  }

  Future<Map<String, dynamic>> _callClaude(
    String prompt,
    AgentConfig config,
  ) async {
    final response = await dio.post(
      ApiConstants.claudeApiUrl,
      data: {
        'model': config.effectiveModel,
        'max_tokens': 1024,
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
    final content = response.data['content'][0]['text'] as String;
    return _parseJsonResponse(content);
  }

  Future<Map<String, dynamic>> _callOpenAI(
    String prompt,
    AgentConfig config,
  ) async {
    final response = await dio.post(
      ApiConstants.openaiApiUrl,
      data: {
        'model': config.effectiveModel,
        'messages': [
          {'role': 'user', 'content': prompt},
        ],
        'temperature': 0.3,
      },
      options: Options(
        headers: {
          'Authorization': 'Bearer ${config.apiKey}',
          'Content-Type': 'application/json',
        },
      ),
    );
    final content = response.data['choices'][0]['message']['content'] as String;
    return _parseJsonResponse(content);
  }

  Future<Map<String, dynamic>> _callGoogle(
    String prompt,
    AgentConfig config,
  ) async {
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
        'generationConfig': {'temperature': 0.3},
      },
      options: Options(headers: {'Content-Type': 'application/json'}),
    );
    final content =
        response.data['candidates'][0]['content']['parts'][0]['text'] as String;
    return _parseJsonResponse(content);
  }

  Map<String, dynamic> _parseJsonResponse(String content) {
    var jsonStr = content.trim();
    if (jsonStr.startsWith('```')) {
      jsonStr = jsonStr.replaceAll(RegExp(r'^```\w*\n?'), '');
      jsonStr = jsonStr.replaceAll(RegExp(r'\n?```$'), '');
    }
    try {
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (e) {
      throw LlmException('Failed to parse LLM response as JSON: $e');
    }
  }
}
