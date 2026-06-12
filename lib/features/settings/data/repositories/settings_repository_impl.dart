import 'package:dartz/dartz.dart';
import 'package:goodreddit/core/error/exceptions.dart';
import 'package:goodreddit/core/error/failures.dart';
import 'package:goodreddit/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:goodreddit/features/settings/domain/entities/agent_config.dart';
import 'package:goodreddit/features/settings/domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsLocalDataSource dataSource;

  SettingsRepositoryImpl({required this.dataSource});

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
}
