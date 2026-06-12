import 'package:dartz/dartz.dart';
import 'package:goodreddit/core/error/failures.dart';
import 'package:goodreddit/core/usecases/usecase.dart';
import 'package:goodreddit/features/history/domain/entities/research_session.dart';
import 'package:goodreddit/features/history/domain/repositories/history_repository.dart';

class SaveSession implements UseCase<Unit, ResearchSession> {
  final HistoryRepository repository;

  SaveSession(this.repository);

  @override
  Future<Either<Failure, Unit>> call(ResearchSession params) {
    return repository.save(params);
  }
}
