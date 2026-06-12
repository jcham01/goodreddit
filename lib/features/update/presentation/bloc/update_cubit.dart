import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goodreddit/core/usecases/usecase.dart';
import 'package:goodreddit/features/update/domain/entities/app_update.dart';
import 'package:goodreddit/features/update/domain/usecases/check_for_update.dart';

part 'update_state.dart';

class UpdateCubit extends Cubit<UpdateState> {
  final CheckForUpdate checkForUpdate;

  UpdateCubit({required this.checkForUpdate}) : super(const UpdateState());

  Future<void> check() async {
    emit(state.copyWith(status: UpdateStatus.checking));
    final result = await checkForUpdate(const NoParams());
    result.fold(
      // A failed check must never get in the user's way at launch.
      (_) => emit(state.copyWith(status: UpdateStatus.upToDate)),
      (update) => emit(update == null
          ? state.copyWith(status: UpdateStatus.upToDate)
          : state.copyWith(status: UpdateStatus.available, update: update)),
    );
  }
}
