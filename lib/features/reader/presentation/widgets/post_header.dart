import 'package:flutter/material.dart';
import 'package:goodreddit/core/util/format.dart';
import 'package:goodreddit/features/scraper/domain/entities/post.dart';

/// Title block of a post detail: subreddit · author · time, title, flair, and
/// the score / comments / upvote-ratio stat row.
class PostHeader extends StatelessWidget {
  final Post post;

  const PostHeader({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'r/${post.subreddit}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(
                  text:
                      '  ·  u/${post.author}  ·  ${relativeTime(post.createdAt)}',
                  style: theme.textTheme.labelSmall?.copyWith(color: muted),
                ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(post.title, style: theme.textTheme.titleMedium),
          if ((post.flair ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            _Chip(post.flair!),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              if (post.over18) const _Badge('NSFW', danger: true),
              if (post.spoiler) const _Badge('SPOILER'),
              if (post.locked) const _Badge('Verrouillé'),
              if (post.isStickied) const _Badge('Épinglé'),
              const Spacer(),
              Icon(Icons.arrow_upward, size: 16, color: muted),
              const SizedBox(width: 2),
              Text(compactCount(post.score), style: theme.textTheme.labelMedium),
              if (post.upvoteRatio != null) ...[
                const SizedBox(width: 4),
                Text(
                  '(${(post.upvoteRatio! * 100).round()} %)',
                  style: theme.textTheme.labelSmall?.copyWith(color: muted),
                ),
              ],
              const SizedBox(width: 12),
              Icon(Icons.mode_comment_outlined, size: 15, color: muted),
              const SizedBox(width: 4),
              Text(
                compactCount(post.numComments),
                style: theme.textTheme.labelMedium,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip(this.label);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall,
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final bool danger;
  const _Badge(this.label, {this.danger = false});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = danger ? scheme.errorContainer : scheme.secondaryContainer;
    final fg = danger ? scheme.onErrorContainer : scheme.onSecondaryContainer;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: fg),
        ),
      ),
    );
  }
}
