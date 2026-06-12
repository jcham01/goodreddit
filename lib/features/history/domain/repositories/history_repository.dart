import 'package:dartz/dartz.dart';
import 'package:goodreddit/core/error/failures.dart';
import 'package:goodreddit/features/history/domain/entities/research_session.dart';

abstract class HistoryRepository {
  Future<Either<Failure, List<ResearchSession>>> getAll();
  Future<Either<Failure, Unit>> save(ResearchSession session);
  Future<Either<Failure, Unit>> delete(String id);
}
