import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:goodreddit/core/error/failures.dart';
import 'package:goodreddit/core/usecases/usecase.dart';
import 'package:goodreddit/features/settings/domain/entities/agent_config.dart';
import 'package:goodreddit/features/settings/domain/repositories/settings_repository.dart';

class ListModels implements UseCase<List<String>, ListModelsParams> {
  final SettingsRepository repository;

  ListModels(this.repository);

  @override
  Future<Either<Failure, List<String>>> call(ListModelsParams params) {
    return repository.getAvailableModels(params.provider, params.apiKey);
  }
}

class ListModelsParams extends Equatable {
  final LlmProvider provider;
  final String apiKey;

  const ListModelsParams({required this.provider, required this.apiKey});

  @override
  List<Object?> get props => [provider, apiKey];
}
