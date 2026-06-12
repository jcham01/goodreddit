import 'package:dartz/dartz.dart';
import 'package:goodreddit/core/error/failures.dart';
import 'package:goodreddit/features/auth/domain/entities/reddit_session.dart';

abstract class AuthRepository {
  /// Inspects the shared browser cookie store to determine whether a Reddit
  /// session is currently active.
  Future<Either<Failure, RedditSession>> currentSession();

  /// Clears the Reddit session cookies (sign out).
  Future<Either<Failure, Unit>> logout();
}
