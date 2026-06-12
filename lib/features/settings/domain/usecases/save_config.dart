import 'package:dartz/dartz.dart';
import 'package:goodreddit/core/error/failures.dart';
import 'package:goodreddit/core/usecases/usecase.dart';
import 'package:goodreddit/features/settings/domain/entities/agent_config.dart';
import 'package:goodreddit/features/settings/domain/repositories/settings_repository.dart';

class SaveConfig implements UseCase<Unit, AgentConfig> {
  final SettingsRepository repository;

  SaveConfig(this.repository);

  @override
  Future<Either<Failure, Unit>> call(AgentConfig params) {
    return repository.saveConfig(params);
  }
}
