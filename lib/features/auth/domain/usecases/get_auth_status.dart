import 'package:dartz/dartz.dart';
import 'package:goodreddit/core/error/failures.dart';
import 'package:goodreddit/core/usecases/usecase.dart';
import 'package:goodreddit/features/auth/domain/entities/reddit_session.dart';
import 'package:goodreddit/features/auth/domain/repositories/auth_repository.dart';

class GetAuthStatus implements UseCase<RedditSession, NoParams> {
  final AuthRepository repository;

  GetAuthStatus(this.repository);

  @override
  Future<Either<Failure, RedditSession>> call(NoParams params) {
    return repository.currentSession();
  }
}
