import 'package:dartz/dartz.dart';
import 'package:goodreddit/core/error/failures.dart';
import 'package:goodreddit/core/util/vote_math.dart';

/// Write actions against Reddit (T2). Kept separate from `ReaderRepository` so
/// the read interface — and its test fakes — stay untouched. Each returns
/// [Unit] on a bare success; the store has already computed the optimistic
/// state, so the repo only confirms or fails.
abstract class InteractionsRepository {
  Future<Either<Failure, Unit>> vote({
    required String fullname,
    required VoteDir dir,
  });

  Future<Either<Failure, Unit>> setSaved({
    required String fullname,
    required bool saved,
  });

  Future<Either<Failure, Unit>> setSubscribed({
    required String srName,
    String? fullname,
    required bool subscribe,
  });
}
