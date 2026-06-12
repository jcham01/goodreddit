import 'package:flutter/material.dart';
import 'package:goodreddit/features/scraper/domain/entities/post.dart';

class PostCard extends StatelessWidget {
  final Post post;
  final VoidCallback? onTap;

  const PostCard({super.key, required this.post, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                  if (post.isStickied)
                    const Padding(
                      padding: EdgeInsets.only(right: 6),
                      child: Icon(
                        Icons.push_pin,
                        size: 16,
                        color: Colors.green,
                      ),
                    ),
                  Expanded(
                    child: Text(
                      post.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              if (post.flair != null && post.flair!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Chip(
                  label: Text(post.flair!, style: theme.textTheme.labelSmall),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
              if (post.selfText.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  post.selfText,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.arrow_upward, size: 14),
                  const SizedBox(width: 2),
                  Text('${post.score}', style: theme.textTheme.bodySmall),
                  const SizedBox(width: 12),
                  const Icon(Icons.comment_outlined, size: 14),
                  const SizedBox(width: 2),
                  Text('${post.numComments}', style: theme.textTheme.bodySmall),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'u/${post.author}',
                      textAlign: TextAlign.end,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
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
