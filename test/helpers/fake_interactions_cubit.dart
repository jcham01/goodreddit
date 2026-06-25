import 'package:dartz/dartz.dart';
import 'package:goodreddit/core/error/failures.dart';
import 'package:goodreddit/core/util/vote_math.dart';
import 'package:goodreddit/features/interactions/domain/repositories/interactions_repository.dart';
import 'package:goodreddit/features/interactions/domain/usecases/cast_vote.dart';
import 'package:goodreddit/features/interactions/domain/usecases/set_saved.dart';
import 'package:goodreddit/features/interactions/domain/usecases/set_subscribed.dart';
import 'package:goodreddit/features/interactions/presentation/bloc/interactions_cubit.dart';

/// A real [InteractionsCubit] backed by a no-op repository, for tests of the
/// reader cubits — which only ever SEED into the store and never trigger a
/// write, so the usecases here are present but unused.
InteractionsCubit fakeInteractionsCubit() {
  final repo = _OkInteractionsRepository();
  return InteractionsCubit(
    castVote: CastVote(repo),
    setSaved: SetSaved(repo),
    setSubscribed: SetSubscribed(repo),
  );
}

class _OkInteractionsRepository implements InteractionsRepository {
  @override
  Future<Either<Failure, Unit>> vote({
    required String fullname,
    required VoteDir dir,
  }) async => const Right(unit);

  @override
  Future<Either<Failure, Unit>> setSaved({
    required String fullname,
    required bool saved,
  }) async => const Right(unit);

  @override
  Future<Either<Failure, Unit>> setSubscribed({
    required String srName,
    String? fullname,
    required bool subscribe,
  }) async => const Right(unit);
}
