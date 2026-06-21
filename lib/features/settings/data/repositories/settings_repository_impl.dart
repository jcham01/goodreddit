import 'package:dartz/dartz.dart';
import 'package:goodreddit/core/constants/api_constants.dart';
import 'package:goodreddit/core/error/exceptions.dart';
import 'package:goodreddit/core/error/failures.dart';
import 'package:goodreddit/features/settings/data/datasources/model_catalog_datasource.dart';
import 'package:goodreddit/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:goodreddit/features/settings/domain/entities/agent_config.dart';
import 'package:goodreddit/features/settings/domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsLocalDataSource dataSource;
  final ModelCatalogDataSource modelCatalogDataSource;

  SettingsRepositoryImpl({
    required this.dataSource,
    required this.modelCatalogDataSource,
  });

  @override
  Future<Either<Failure, AgentConfig>> getConfig() async {
    try {
      return Right(await dataSource.getConfig());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Unit>> saveConfig(AgentConfig config) async {
    try {
      await dataSource.saveConfig(config);
      return const Right(unit);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<String>>> getAvailableModels(
    LlmProvider provider,
    String apiKey,
  ) async {
    // Codex has no API key — its live list comes from the ChatGPT session.
    if (provider == LlmProvider.openaiCodex) {
      try {
        final models = await modelCatalogDataSource.fetchModels(provider, '');
        if (models.isNotEmpty) return Right(models);
      } on LlmException {
        // Degrade to the static catalog below.
      }
      return Right(_fallbackModels(provider));
    }

    if (apiKey.isNotEmpty) {
      try {
        final models = await modelCatalogDataSource.fetchModels(
          provider,
          apiKey,
        );
        if (models.isNotEmpty) return Right(models);
      } on LlmException {
        // Degrade to the static catalog — model selection must keep working
        // offline or with a bad key.
      }
    }
    return Right(_fallbackModels(provider));
  }

  List<String> _fallbackModels(LlmProvider provider) {
    switch (provider) {
      case LlmProvider.claude:
        return ApiConstants.claudeFallbackModels;
      case LlmProvider.openai:
        return ApiConstants.openaiFallbackModels;
      case LlmProvider.google:
        return ApiConstants.googleFallbackModels;
      case LlmProvider.openaiCodex:
        return ApiConstants.openaiCodexFallbackModels;
    }
  }
}
