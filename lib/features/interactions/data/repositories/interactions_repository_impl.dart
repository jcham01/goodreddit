import 'package:dartz/dartz.dart';
import 'package:goodreddit/core/error/exceptions.dart';
import 'package:goodreddit/core/error/failures.dart';
import 'package:goodreddit/core/util/vote_math.dart';
import 'package:goodreddit/features/interactions/data/datasources/reddit_interactions_datasource.dart';
import 'package:goodreddit/features/interactions/domain/repositories/interactions_repository.dart';

class InteractionsRepositoryImpl implements InteractionsRepository {
  final RedditInteractionsDataSource dataSource;

  InteractionsRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, Unit>> vote({
    required String fullname,
    required VoteDir dir,
  }) => _guard(() => dataSource.vote(fullname: fullname, dir: dir));

  @override
  Future<Either<Failure, Unit>> setSaved({
    required String fullname,
    required bool saved,
  }) => _guard(() => dataSource.setSaved(fullname: fullname, saved: saved));

  @override
  Future<Either<Failure, Unit>> setSubscribed({
    required String srName,
    String? fullname,
    required bool subscribe,
  }) => _guard(
    () => dataSource.setSubscribed(
      srName: srName,
      fullname: fullname,
      subscribe: subscribe,
    ),
  );

  /// Same exception → Failure ladder as ReaderRepositoryImpl.
  Future<Either<Failure, Unit>> _guard(Future<void> Function() action) async {
    try {
      await action();
      return const Right(unit);
    } on NotAuthenticatedException catch (e) {
      return Left(NotAuthenticatedFailure(e.message));
    } on RedditException catch (e) {
      return Left(RedditFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
