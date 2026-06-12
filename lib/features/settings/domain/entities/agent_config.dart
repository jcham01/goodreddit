import 'package:equatable/equatable.dart';
import 'package:goodreddit/core/constants/api_constants.dart';

enum LlmProvider { claude, openai, google }

class AgentConfig extends Equatable {
  final LlmProvider provider;
  final String apiKey;
  final String? model;

  const AgentConfig({
    required this.provider,
    required this.apiKey,
    this.model,
  });

  const AgentConfig.empty()
      : provider = LlmProvider.claude,
        apiKey = '',
        model = null;

  bool get isConfigured => apiKey.isNotEmpty;

  String get effectiveModel {
    if (model != null && model!.isNotEmpty) return model!;
    switch (provider) {
      case LlmProvider.claude:
        return ApiConstants.claudeDefaultModel;
      case LlmProvider.openai:
        return ApiConstants.openaiDefaultModel;
      case LlmProvider.google:
        return ApiConstants.googleDefaultModel;
    }
  }

  AgentConfig copyWith({
    LlmProvider? provider,
    String? apiKey,
    String? model,
  }) {
    return AgentConfig(
      provider: provider ?? this.provider,
      apiKey: apiKey ?? this.apiKey,
      model: model ?? this.model,
    );
  }

  @override
  List<Object?> get props => [provider, apiKey, model];
}
