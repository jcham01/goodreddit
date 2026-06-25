import 'package:flutter/material.dart';
import 'package:goodreddit/features/reader/domain/entities/thread_item.dart';

/// A "load more comments" row. In Phase 3A it opens the full thread on
/// reddit.com (in-app expansion via /api/morechildren is a later step).
class MoreCommentsTile extends StatelessWidget {
  final MoreNode node;
  final VoidCallback onTap;

  const MoreCommentsTile({super.key, required this.node, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visualDepth = node.depth > 6 ? 6 : node.depth;
    final indent = (visualDepth * 10 + (visualDepth == 0 ? 16 : 8)).toDouble();

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.fromLTRB(indent, 8, 16, 8),
        child: Row(
          children: [
            Icon(
              Icons.subdirectory_arrow_right,
              size: 16,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Text(
              'Voir ${node.count} réponse${node.count > 1 ? 's' : ''} de plus',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
