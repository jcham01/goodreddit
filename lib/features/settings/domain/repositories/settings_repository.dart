import 'package:dartz/dartz.dart';
import 'package:goodreddit/core/error/failures.dart';
import 'package:goodreddit/features/settings/domain/entities/agent_config.dart';

abstract class SettingsRepository {
  Future<Either<Failure, AgentConfig>> getConfig();
  Future<Either<Failure, Unit>> saveConfig(AgentConfig config);

  /// Model ids selectable for [provider]. Queries the provider's live
  /// list-models endpoint when [apiKey] is set; falls back to a static
  /// catalog otherwise (or when the fetch fails).
  Future<Either<Failure, List<String>>> getAvailableModels(
    LlmProvider provider,
    String apiKey,
  );
}
