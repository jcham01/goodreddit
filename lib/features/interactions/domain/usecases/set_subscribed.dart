import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:goodreddit/core/error/failures.dart';
import 'package:goodreddit/core/usecases/usecase.dart';
import 'package:goodreddit/features/interactions/domain/repositories/interactions_repository.dart';

class SetSubscribed implements UseCase<Unit, SetSubscribedParams> {
  final InteractionsRepository repository;
  const SetSubscribed(this.repository);

  @override
  Future<Either<Failure, Unit>> call(SetSubscribedParams params) =>
      repository.setSubscribed(
        srName: params.srName,
        fullname: params.fullname,
        subscribe: params.subscribe,
      );
}

class SetSubscribedParams extends Equatable {
  final String srName;
  final String? fullname;
  final bool subscribe;
  const SetSubscribedParams({
    required this.srName,
    this.fullname,
    required this.subscribe,
  });

  @override
  List<Object?> get props => [srName, fullname, subscribe];
}
