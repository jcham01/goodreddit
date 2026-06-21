import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:goodreddit/core/error/failures.dart';
import 'package:goodreddit/core/usecases/usecase.dart';
import 'package:goodreddit/core/widgets/model_badge.dart';
import 'package:goodreddit/features/settings/domain/entities/agent_config.dart';
import 'package:goodreddit/features/settings/domain/usecases/get_config.dart';

/// Persistent chip showing the currently configured LLM provider + model.
///
/// Reads the saved config on build, so giving it a fresh `key` after the user
/// edits settings re-fetches and updates the label.
class ActiveLlmBadge extends StatelessWidget {
  const ActiveLlmBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Either<Failure, AgentConfig>>(
      future: GetIt.I<GetConfig>()(const NoParams()),
      builder: (context, snapshot) {
        final config = snapshot.data?.fold((_) => null, (c) => c);
        return ModelBadge(
          provider: config?.provider.label,
          model: config?.effectiveModel,
          prefix: '',
        );
      },
    );
  }
}
