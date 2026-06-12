part of 'history_cubit.dart';

enum HistoryStatus { initial, loading, loaded, error }

class HistoryState extends Equatable {
  final HistoryStatus status;
  final List<ResearchSession> sessions;
  final String? errorMessage;

  const HistoryState({
    this.status = HistoryStatus.initial,
    this.sessions = const [],
    this.errorMessage,
  });

  HistoryState copyWith({
    HistoryStatus? status,
    List<ResearchSession>? sessions,
    String? errorMessage,
  }) {
    return HistoryState(
      status: status ?? this.status,
      sessions: sessions ?? this.sessions,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, sessions, errorMessage];
}
