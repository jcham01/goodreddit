import 'package:flutter/material.dart';

/// Small chip naming the LLM model a result set was produced with.
/// [model] null means no LLM was configured (heuristic-only ranking).
class ModelBadge extends StatelessWidget {
  final String? model;
  final String prefix;

  const ModelBadge({super.key, required this.model, this.prefix = 'Model'});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            model != null ? Icons.auto_awesome : Icons.calculate_outlined,
            size: 14,
            color: theme.colorScheme.onSecondaryContainer,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              model != null ? '$prefix: $model' : 'No LLM — heuristic only',
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
