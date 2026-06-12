import 'package:dartz/dartz.dart';
import 'package:goodreddit/core/error/failures.dart';
import 'package:goodreddit/core/usecases/usecase.dart';
import 'package:goodreddit/features/update/domain/entities/app_update.dart';
import 'package:goodreddit/features/update/domain/repositories/update_repository.dart';

class CheckForUpdate implements UseCase<AppUpdate?, NoParams> {
  final UpdateRepository repository;

  CheckForUpdate(this.repository);

  @override
  Future<Either<Failure, AppUpdate?>> call(NoParams params) {
    return repository.checkForUpdate();
  }
}
