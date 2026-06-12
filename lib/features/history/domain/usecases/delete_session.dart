import 'package:dartz/dartz.dart';
import 'package:goodreddit/core/error/failures.dart';
import 'package:goodreddit/core/usecases/usecase.dart';
import 'package:goodreddit/features/history/domain/repositories/history_repository.dart';

class DeleteSession implements UseCase<Unit, String> {
  final HistoryRepository repository;

  DeleteSession(this.repository);

  @override
  Future<Either<Failure, Unit>> call(String params) {
    return repository.delete(params);
  }
}
