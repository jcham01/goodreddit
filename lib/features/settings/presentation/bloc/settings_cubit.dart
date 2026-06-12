import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goodreddit/core/usecases/usecase.dart';
import 'package:goodreddit/features/settings/domain/entities/agent_config.dart';
import 'package:goodreddit/features/settings/domain/usecases/get_config.dart';
import 'package:goodreddit/features/settings/domain/usecases/save_config.dart';

part 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  final GetConfig getConfig;
  final SaveConfig saveConfig;

  SettingsCubit({
    required this.getConfig,
    required this.saveConfig,
  }) : super(const SettingsState());

  Future<void> load() async {
    emit(state.copyWith(status: SettingsStatus.loading));
    final result = await getConfig(const NoParams());
    result.fold(
      (failure) => emit(state.copyWith(
        status: SettingsStatus.error,
        errorMessage: failure.message,
      )),
      (config) => emit(state.copyWith(
        status: SettingsStatus.loaded,
        config: config,
      )),
    );
  }

  Future<void> save(AgentConfig config) async {
    emit(state.copyWith(status: SettingsStatus.saving, config: config));
    final result = await saveConfig(config);
    result.fold(
      (failure) => emit(state.copyWith(
        status: SettingsStatus.error,
        errorMessage: failure.message,
      )),
      (_) => emit(state.copyWith(status: SettingsStatus.saved, config: config)),
    );
  }
}
