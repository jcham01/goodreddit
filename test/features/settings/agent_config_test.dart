import 'package:flutter_test/flutter_test.dart';
import 'package:goodreddit/features/settings/domain/entities/agent_config.dart';

void main() {
  test('OpenAI Codex provider uses ChatGPT (OAuth) auth instead of an API key', () {
    const config = AgentConfig(provider: LlmProvider.openaiCodex, apiKey: '');

    expect(config.usesApiKey, isFalse);
    expect(config.usesChatGptAuth, isTrue);
    expect(config.isConfigured, isTrue);
    expect(config.effectiveModel, 'gpt-5.5');
  });

  test('provider labels are the user-facing names', () {
    expect(LlmProvider.claude.label, 'Claude');
    expect(LlmProvider.openai.label, 'OpenAI');
    expect(LlmProvider.google.label, 'Gemini');
    expect(LlmProvider.openaiCodex.label, 'Codex');
  });
}
