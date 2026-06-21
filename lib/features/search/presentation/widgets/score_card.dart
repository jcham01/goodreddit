import 'package:flutter/material.dart';
import 'package:goodreddit/features/search/domain/entities/subreddit_score.dart';

class ScoreCard extends StatelessWidget {
  final SubredditScore score;
  final VoidCallback? onTap;

  const ScoreCard({super.key, required this.score, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sub = score.subreddit;
    final pct = (score.totalScore * 100).round();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      sub.displayName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _ScoreBadge(pct: pct),
                ],
              ),
              if (sub.title.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(sub.title, style: theme.textTheme.bodyMedium),
              ],
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  _Stat(
                    icon: Icons.people_outline,
                    label: _compact(sub.subscribers),
                  ),
                  _Stat(
                    icon: Icons.bolt_outlined,
                    label: '${_compact(sub.activeUsers)} active',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _ScorePart(label: 'Activity', value: score.activityScore),
                  _ScorePart(label: 'Size', value: score.subscriberScore),
                  _ScorePart(label: 'Keyword', value: score.relevanceScore),
                  _ScorePart(label: 'LLM', value: score.semanticScore),
                ],
              ),
              if (score.llmReasoning != null &&
                  score.llmReasoning!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.auto_awesome, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          score.llmReasoning!,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static String _compact(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }
}

class _ScorePart extends StatelessWidget {
  final String label;
  final double value;

  const _ScorePart({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pct = (value * 100).round();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text('$label $pct%', style: theme.textTheme.labelSmall),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  final int pct;
  const _ScoreBadge({required this.pct});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$pct%',
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Stat({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.outline),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
