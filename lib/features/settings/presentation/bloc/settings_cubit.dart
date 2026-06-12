import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goodreddit/core/usecases/usecase.dart';
import 'package:goodreddit/features/settings/domain/entities/agent_config.dart';
import 'package:goodreddit/features/settings/domain/usecases/get_config.dart';
import 'package:goodreddit/features/settings/domain/usecases/list_models.dart';
import 'package:goodreddit/features/settings/domain/usecases/save_config.dart';

part 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  final GetConfig getConfig;
  final SaveConfig saveConfig;
  final ListModels listModels;

  SettingsCubit({
    required this.getConfig,
    required this.saveConfig,
    required this.listModels,
  }) : super(const SettingsState());

  Future<void> load() async {
    emit(state.copyWith(status: SettingsStatus.loading));
    final result = await getConfig(const NoParams());
    await result.fold(
      (failure) async => emit(
        state.copyWith(
          status: SettingsStatus.error,
          errorMessage: failure.message,
        ),
      ),
      (config) async {
        emit(state.copyWith(status: SettingsStatus.loaded, config: config));
        await loadModels(config.provider, config.apiKey);
      },
    );
  }

  /// Refreshes the selectable model list for [provider], using [apiKey] to
  /// query the provider's live list-models endpoint when available.
  Future<void> loadModels(LlmProvider provider, String apiKey) async {
    emit(state.copyWith(modelsLoading: true));
    final result = await listModels(
      ListModelsParams(provider: provider, apiKey: apiKey.trim()),
    );
    result.fold(
      // The repository already degrades to a static catalog; a failure here
      // is unexpected — keep whatever list we had.
      (_) => emit(state.copyWith(modelsLoading: false)),
      (models) => emit(state.copyWith(modelsLoading: false, models: models)),
    );
  }

  Future<void> save(AgentConfig config) async {
    emit(state.copyWith(status: SettingsStatus.saving, config: config));
    final result = await saveConfig(config);
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: SettingsStatus.error,
          errorMessage: failure.message,
        ),
      ),
      (_) => emit(state.copyWith(status: SettingsStatus.saved, config: config)),
    );
  }
}
