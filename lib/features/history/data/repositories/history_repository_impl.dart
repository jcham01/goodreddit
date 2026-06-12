import 'package:dartz/dartz.dart';
import 'package:goodreddit/core/error/exceptions.dart';
import 'package:goodreddit/core/error/failures.dart';
import 'package:goodreddit/features/history/data/datasources/session_local_datasource.dart';
import 'package:goodreddit/features/history/data/models/research_session_model.dart';
import 'package:goodreddit/features/history/domain/entities/research_session.dart';
import 'package:goodreddit/features/history/domain/repositories/history_repository.dart';

class HistoryRepositoryImpl implements HistoryRepository {
  final SessionLocalDataSource dataSource;

  HistoryRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, List<ResearchSession>>> getAll() async {
    try {
      return Right(await dataSource.getAll());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Unit>> save(ResearchSession session) async {
    try {
      await dataSource.save(ResearchSessionModel.fromEntity(session));
      return const Right(unit);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Unit>> delete(String id) async {
    try {
      await dataSource.delete(id);
      return const Right(unit);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }
}
