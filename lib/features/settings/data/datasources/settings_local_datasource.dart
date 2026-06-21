import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:goodreddit/core/error/exceptions.dart';
import 'package:goodreddit/features/settings/domain/entities/agent_config.dart';

/// Persists the LLM configuration. The API key is kept in the platform secure
/// store (Android Keystore-backed EncryptedSharedPreferences), never in plain
/// preferences.
abstract class SettingsLocalDataSource {
  Future<AgentConfig> getConfig();
  Future<void> saveConfig(AgentConfig config);
  Future<void> clearConfig();
}

class SettingsLocalDataSourceImpl implements SettingsLocalDataSource {
  final FlutterSecureStorage secureStorage;

  static const _providerKey = 'llm_provider';
  static const _apiKeyKey = 'llm_api_key';
  static const _modelKey = 'llm_model';

  SettingsLocalDataSourceImpl({required this.secureStorage});

  @override
  Future<AgentConfig> getConfig() async {
    try {
      final providerStr = await secureStorage.read(key: _providerKey);
      final apiKey = await secureStorage.read(key: _apiKeyKey) ?? '';
      final model = await secureStorage.read(key: _modelKey);

      final provider = switch (providerStr) {
        'openai' => LlmProvider.openai,
        'google' => LlmProvider.google,
        'openaiCodex' => LlmProvider.openaiCodex,
        'openai_codex' => LlmProvider.openaiCodex,
        _ => LlmProvider.claude,
      };

      return AgentConfig(provider: provider, apiKey: apiKey, model: model);
    } catch (e) {
      throw CacheException('Failed to read config: $e');
    }
  }

  @override
  Future<void> saveConfig(AgentConfig config) async {
    try {
      await secureStorage.write(key: _providerKey, value: config.provider.name);
      if (config.usesApiKey) {
        await secureStorage.write(key: _apiKeyKey, value: config.apiKey);
      } else {
        await secureStorage.delete(key: _apiKeyKey);
      }
      if (config.model != null && config.model!.isNotEmpty) {
        await secureStorage.write(key: _modelKey, value: config.model);
      } else {
        await secureStorage.delete(key: _modelKey);
      }
    } catch (e) {
      throw CacheException('Failed to save config: $e');
    }
  }

  @override
  Future<void> clearConfig() async {
    try {
      await secureStorage.delete(key: _providerKey);
      await secureStorage.delete(key: _apiKeyKey);
      await secureStorage.delete(key: _modelKey);
    } catch (e) {
      throw CacheException('Failed to clear config: $e');
    }
  }
}
