import 'package:flutter_test/flutter_test.dart';
import 'package:goodreddit/features/settings/data/datasources/codex_auth_datasource.dart';

void main() {
  group('parseCodexModelIds', () {
    test('derives GPT-5.x versions from the picker `versions` grouping', () {
      // Trimmed shape of the real /backend-api/models response.
      const body = '''
      {
        "default_model_slug": "gpt-5-5",
        "models": [
          {"slug": "gpt-5-5", "title": "GPT-5.5"},
          {"slug": "gpt-5-4-thinking", "title": "GPT-5.4 Thinking"},
          {"slug": "o3", "title": "o3"},
          {"slug": "agent-mode", "title": "Agent"}
        ],
        "versions": [
          {"id": "5.5", "slugs": ["gpt-5-5", "gpt-5-5-thinking"]},
          {"id": "5.4", "slugs": ["gpt-5-4-thinking"]},
          {"id": "5.3", "slugs": ["gpt-5-3-instant"]},
          {"id": "o3", "slugs": ["o3"]}
        ]
      }''';

      expect(parseCodexModelIds(body), ['gpt-5.3', 'gpt-5.4', 'gpt-5.5']);
    });

    test('falls back to slug parsing when no `versions` block', () {
      const body = '''
      {"models": [
        {"slug": "gpt-5-5"},
        {"slug": "gpt-5-4-thinking"},
        {"slug": "gpt-5"},
        {"slug": "o3"},
        {"slug": "agent-mode"}
      ]}''';

      // o3 / agent-mode are excluded; gpt-5 family kept in dot form.
      expect(parseCodexModelIds(body), ['gpt-5', 'gpt-5.4', 'gpt-5.5']);
    });

    test('returns empty on garbage', () {
      expect(parseCodexModelIds('not json'), isEmpty);
      expect(parseCodexModelIds('[]'), isEmpty);
    });
  });
}
