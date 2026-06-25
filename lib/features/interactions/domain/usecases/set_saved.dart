import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:goodreddit/core/error/failures.dart';
import 'package:goodreddit/core/usecases/usecase.dart';
import 'package:goodreddit/features/interactions/domain/repositories/interactions_repository.dart';

class SetSaved implements UseCase<Unit, SetSavedParams> {
  final InteractionsRepository repository;
  const SetSaved(this.repository);

  @override
  Future<Either<Failure, Unit>> call(SetSavedParams params) =>
      repository.setSaved(fullname: params.fullname, saved: params.saved);
}

class SetSavedParams extends Equatable {
  final String fullname;
  final bool saved;
  const SetSavedParams({required this.fullname, required this.saved});

  @override
  List<Object?> get props => [fullname, saved];
}
