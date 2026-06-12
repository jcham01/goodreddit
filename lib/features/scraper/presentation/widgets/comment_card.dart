import 'package:flutter/material.dart';
import 'package:goodreddit/features/scraper/domain/entities/comment.dart';

class CommentCard extends StatelessWidget {
  final Comment comment;

  const CommentCard({super.key, required this.comment});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'u/${comment.author}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.arrow_upward, size: 13),
                const SizedBox(width: 2),
                Text('${comment.score}', style: theme.textTheme.labelSmall),
              ],
            ),
            const SizedBox(height: 4),
            Text(comment.body, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
