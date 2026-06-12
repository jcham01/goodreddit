import 'package:dartz/dartz.dart';
import 'package:goodreddit/core/error/failures.dart';
import 'package:goodreddit/core/usecases/usecase.dart';
import 'package:goodreddit/features/auth/domain/repositories/auth_repository.dart';

class Logout implements UseCase<Unit, NoParams> {
  final AuthRepository repository;

  Logout(this.repository);

  @override
  Future<Either<Failure, Unit>> call(NoParams params) {
    return repository.logout();
  }
}
