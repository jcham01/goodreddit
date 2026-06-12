part of 'update_cubit.dart';

enum UpdateStatus { initial, checking, upToDate, available }

class UpdateState extends Equatable {
  final UpdateStatus status;
  final AppUpdate? update;

  const UpdateState({this.status = UpdateStatus.initial, this.update});

  UpdateState copyWith({UpdateStatus? status, AppUpdate? update}) {
    return UpdateState(
      status: status ?? this.status,
      update: update ?? this.update,
    );
  }

  @override
  List<Object?> get props => [status, update];
}
