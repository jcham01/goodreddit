import 'package:flutter/material.dart';
import 'package:goodreddit/core/util/format.dart';
import 'package:goodreddit/features/interactions/presentation/widgets/vote_controls.dart';
import 'package:goodreddit/features/reader/presentation/pages/post_detail_page.dart';
import 'package:goodreddit/features/reader/presentation/widgets/subreddit_link.dart';
import 'package:goodreddit/features/scraper/domain/entities/post.dart';

/// Feed card for a single post. Tapping opens the in-app detail (comments,
/// media, self-text); the score row carries live vote + save controls.
class PostCard extends StatelessWidget {
  final Post post;

  /// Invoked when an anonymous user taps a vote/save control (opens login).
  final VoidCallback onNeedsAuth;

  const PostCard({super.key, required this.post, required this.onNeedsAuth});

  void _open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PostDetailPage(post: post)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final showThumb = post.thumbnailUrl != null && !post.over18;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: InkWell(
        onTap: () => _open(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: r/sub · u/author · time
              Row(
                children: [
                  SubredditLink(subreddit: post.subreddit),
                  Expanded(
                    child: Text(
                      '  ·  u/${post.author}  ·  ${relativeTime(post.createdAt)}',
                      style: theme.textTheme.labelSmall?.copyWith(color: muted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Title + optional thumbnail
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      post.title,
                      style: theme.textTheme.titleSmall,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (showThumb) ...[
                    const SizedBox(width: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        post.thumbnailUrl!,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              // Badges + score + comments
              Row(
                children: [
                  if (post.over18) const _Badge('NSFW', danger: true),
                  if (post.spoiler) const _Badge('SPOILER'),
                  if (post.locked) const _Badge('Verrouillé'),
                  if (post.isStickied) const _Badge('Épinglé'),
                  const Spacer(),
                  VoteControls(
                    fullname: post.fullname,
                    baseScore: post.score,
                    scoreHidden: post.scoreHidden,
                    onNeedsAuth: onNeedsAuth,
                    compact: true,
                  ),
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
        ),
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
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: fg),
        ),
      ),
    );
  }
}
