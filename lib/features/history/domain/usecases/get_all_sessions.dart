import 'package:dartz/dartz.dart';
import 'package:goodreddit/core/error/failures.dart';
import 'package:goodreddit/core/usecases/usecase.dart';
import 'package:goodreddit/features/history/domain/entities/research_session.dart';
import 'package:goodreddit/features/history/domain/repositories/history_repository.dart';

class GetAllSessions implements UseCase<List<ResearchSession>, NoParams> {
  final HistoryRepository repository;

  GetAllSessions(this.repository);

  @override
  Future<Either<Failure, List<ResearchSession>>> call(NoParams params) {
    return repository.getAll();
  }
}
