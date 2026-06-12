part of 'settings_cubit.dart';

enum SettingsStatus { initial, loading, loaded, saving, saved, error }

class SettingsState extends Equatable {
  final SettingsStatus status;
  final AgentConfig config;
  final String? errorMessage;

  const SettingsState({
    this.status = SettingsStatus.initial,
    this.config = const AgentConfig.empty(),
    this.errorMessage,
  });

  SettingsState copyWith({
    SettingsStatus? status,
    AgentConfig? config,
    String? errorMessage,
  }) {
    return SettingsState(
      status: status ?? this.status,
      config: config ?? this.config,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, config, errorMessage];
}
