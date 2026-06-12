import 'package:dartz/dartz.dart';
import 'package:goodreddit/core/error/exceptions.dart';
import 'package:goodreddit/core/error/failures.dart';
import 'package:goodreddit/features/auth/data/datasources/reddit_auth_datasource.dart';
import 'package:goodreddit/features/auth/domain/entities/reddit_session.dart';
import 'package:goodreddit/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final RedditAuthDataSource dataSource;

  AuthRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, RedditSession>> currentSession() async {
    try {
      // `/api/me.json` is authoritative regardless of the session cookie's name,
      // so prefer it; fall back to a cookie check if it can't be resolved.
      final username = await dataSource.resolveUsername();
      if (username != null) {
        return Right(RedditSession(isAuthenticated: true, username: username));
      }
      final loggedIn = await dataSource.isLoggedIn();
      return Right(RedditSession(isAuthenticated: loggedIn));
    } catch (e) {
      return Left(RedditFailure('Could not read session: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> logout() async {
    try {
      await dataSource.clearSession();
      return const Right(unit);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
