import 'package:flutter/material.dart';
import 'package:goodreddit/features/search/domain/entities/search_ranking_result.dart';

class RankingBadge extends StatelessWidget {
  final LlmRankingStatus status;
  final String? model;

  const RankingBadge({super.key, required this.status, this.model});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (icon, label, color, onColor) = switch (status) {
      LlmRankingStatus.applied => (
        Icons.auto_awesome,
        'LLM applied: ${model ?? 'unknown model'}',
        theme.colorScheme.secondaryContainer,
        theme.colorScheme.onSecondaryContainer,
      ),
      LlmRankingStatus.failed => (
        Icons.warning_amber_outlined,
        'LLM failed - heuristic fallback',
        theme.colorScheme.errorContainer,
        theme.colorScheme.onErrorContainer,
      ),
      LlmRankingStatus.notConfigured => (
        Icons.calculate_outlined,
        'Heuristic only',
        theme.colorScheme.surfaceContainerHighest,
        theme.colorScheme.onSurfaceVariant,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: onColor),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(color: onColor),
            ),
          ),
        ],
      ),
    );
  }
}
