import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:goodreddit/core/error/failures.dart';
import 'package:goodreddit/core/usecases/usecase.dart';
import 'package:goodreddit/core/util/vote_math.dart';
import 'package:goodreddit/features/interactions/domain/repositories/interactions_repository.dart';

class CastVote implements UseCase<Unit, CastVoteParams> {
  final InteractionsRepository repository;
  const CastVote(this.repository);

  @override
  Future<Either<Failure, Unit>> call(CastVoteParams params) =>
      repository.vote(fullname: params.fullname, dir: params.dir);
}

class CastVoteParams extends Equatable {
  final String fullname;
  final VoteDir dir;
  const CastVoteParams({required this.fullname, required this.dir});

  @override
  List<Object?> get props => [fullname, dir];
}
