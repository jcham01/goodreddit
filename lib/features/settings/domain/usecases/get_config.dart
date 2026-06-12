import 'package:dartz/dartz.dart';
import 'package:goodreddit/core/error/failures.dart';
import 'package:goodreddit/core/usecases/usecase.dart';
import 'package:goodreddit/features/settings/domain/entities/agent_config.dart';
import 'package:goodreddit/features/settings/domain/repositories/settings_repository.dart';

class GetConfig implements UseCase<AgentConfig, NoParams> {
  final SettingsRepository repository;

  GetConfig(this.repository);

  @override
  Future<Either<Failure, AgentConfig>> call(NoParams params) {
    return repository.getConfig();
  }
}
