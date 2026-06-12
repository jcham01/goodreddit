import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goodreddit/core/usecases/usecase.dart';
import 'package:goodreddit/features/history/domain/entities/research_session.dart';
import 'package:goodreddit/features/history/domain/usecases/delete_session.dart';
import 'package:goodreddit/features/history/domain/usecases/get_all_sessions.dart';

part 'history_state.dart';

class HistoryCubit extends Cubit<HistoryState> {
  final GetAllSessions getAllSessions;
  final DeleteSession deleteSession;

  HistoryCubit({required this.getAllSessions, required this.deleteSession})
    : super(const HistoryState());

  Future<void> load() async {
    emit(state.copyWith(status: HistoryStatus.loading));
    final result = await getAllSessions(const NoParams());
    result.fold(
      (f) => emit(
        state.copyWith(status: HistoryStatus.error, errorMessage: f.message),
      ),
      (sessions) => emit(
        state.copyWith(status: HistoryStatus.loaded, sessions: sessions),
      ),
    );
  }

  Future<void> remove(String id) async {
    await deleteSession(id);
    await load();
  }
}
