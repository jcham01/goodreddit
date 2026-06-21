import 'package:flutter/material.dart';

/// Small chip naming the LLM [provider] and/or [model] in use.
/// Both null means no LLM is configured (heuristic-only ranking).
/// Pass an empty [prefix] to show just "provider · model".
class ModelBadge extends StatelessWidget {
  final String? model;
  final String? provider;
  final String prefix;

  const ModelBadge({
    super.key,
    required this.model,
    this.provider,
    this.prefix = 'Model',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final core = [
      if (provider != null) provider!,
      if (model != null) model!,
    ].join(' · ');
    final hasLlm = core.isNotEmpty;
    final text = !hasLlm
        ? 'No LLM — heuristic only'
        : (prefix.isEmpty ? core : '$prefix: $core');

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
            hasLlm ? Icons.auto_awesome : Icons.calculate_outlined,
            size: 14,
            color: theme.colorScheme.onSecondaryContainer,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
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
