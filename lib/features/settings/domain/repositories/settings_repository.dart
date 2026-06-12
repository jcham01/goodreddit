import 'package:dartz/dartz.dart';
import 'package:goodreddit/core/error/failures.dart';
import 'package:goodreddit/features/settings/domain/entities/agent_config.dart';

abstract class SettingsRepository {
  Future<Either<Failure, AgentConfig>> getConfig();
  Future<Either<Failure, Unit>> saveConfig(AgentConfig config);
}
