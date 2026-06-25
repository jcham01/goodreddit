import 'package:dartz/dartz.dart';
import 'package:goodreddit/core/error/failures.dart';
import 'package:goodreddit/core/usecases/usecase.dart';
import 'package:goodreddit/features/reader/domain/entities/subreddit_about.dart';
import 'package:goodreddit/features/reader/domain/repositories/reader_repository.dart';

class GetSubredditAbout implements UseCase<SubredditAbout, String> {
  final ReaderRepository repository;

  GetSubredditAbout(this.repository);

  @override
  Future<Either<Failure, SubredditAbout>> call(String subreddit) {
    return repository.getSubredditAbout(subreddit);
  }
}
