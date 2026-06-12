part of 'settings_cubit.dart';

enum SettingsStatus { initial, loading, loaded, saving, saved, error }

class SettingsState extends Equatable {
  final SettingsStatus status;
  final AgentConfig config;
  final List<String> models;
  final bool modelsLoading;
  final String? errorMessage;

  const SettingsState({
    this.status = SettingsStatus.initial,
    this.config = const AgentConfig.empty(),
    this.models = const [],
    this.modelsLoading = false,
    this.errorMessage,
  });

  SettingsState copyWith({
    SettingsStatus? status,
    AgentConfig? config,
    List<String>? models,
    bool? modelsLoading,
    String? errorMessage,
  }) {
    return SettingsState(
      status: status ?? this.status,
      config: config ?? this.config,
      models: models ?? this.models,
      modelsLoading: modelsLoading ?? this.modelsLoading,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    config,
    models,
    modelsLoading,
    errorMessage,
  ];
}
