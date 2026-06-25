import 'package:flutter/material.dart';
import 'package:goodreddit/core/util/format.dart';
import 'package:goodreddit/features/reader/domain/entities/thread_item.dart';
import 'package:goodreddit/features/reader/presentation/widgets/reddit_markdown.dart';

const double _railGap = 10;

/// A single comment row. Nesting is shown with indentation guide rails (one per
/// depth level), painted behind the content so it never forces an intrinsic
/// height on the markdown body. Tapping the header collapses the comment and its
/// descendants.
class CommentTile extends StatelessWidget {
  final CommentNode node;
  final bool collapsed;
  final int hiddenCount;
  final VoidCallback onToggle;

  const CommentTile({
    super.key,
    required this.node,
    required this.collapsed,
    required this.hiddenCount,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = scheme.onSurfaceVariant;
    final visualDepth = node.depth > 6 ? 6 : node.depth;
    final leftPad = visualDepth == 0 ? 16.0 : visualDepth * _railGap + 8;

    return CustomPaint(
      painter: _RailsPainter(depth: visualDepth, color: scheme.outlineVariant),
      child: Padding(
        padding: EdgeInsets.fromLTRB(leftPad, 8, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    if (collapsed)
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Icon(
                          Icons.add_box_outlined,
                          size: 15,
                          color: muted,
                        ),
                      ),
                    Flexible(
                      child: Text(
                        'u/${node.author}',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: node.isSubmitter ? scheme.primary : null,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (node.isSubmitter) const _Tag('OP'),
                    if (node.isModerator) const _Tag('MOD', mod: true),
                    if (node.isAdmin) const _Tag('ADMIN', mod: true),
                    if (node.isStickied)
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Icon(Icons.push_pin, size: 12, color: muted),
                      ),
                    const SizedBox(width: 8),
                    Icon(Icons.arrow_upward, size: 12, color: muted),
                    const SizedBox(width: 2),
                    Text(
                      node.scoreHidden ? '—' : compactCount(node.score),
                      style: theme.textTheme.labelSmall?.copyWith(color: muted),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        collapsed && hiddenCount > 0
                            ? '· $hiddenCount commentaire${hiddenCount > 1 ? 's' : ''}'
                                  ' masqué${hiddenCount > 1 ? 's' : ''}'
                            : '· ${relativeTime(node.createdAt)}'
                                  '${node.edited ? ' · modifié' : ''}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: muted,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (!collapsed) ...[
              const SizedBox(height: 4),
              if (node.isDeleted)
                Text(
                  node.body.isEmpty ? '[supprimé]' : node.body,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: muted,
                  ),
                )
              else
                RedditMarkdown(
                  data: node.body,
                  baseStyle: theme.textTheme.bodyMedium,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Paints [depth] vertical guide rails behind a comment, full content height.
class _RailsPainter extends CustomPainter {
  final int depth;
  final Color color;

  const _RailsPainter({required this.depth, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5;
    for (var i = 0; i < depth; i++) {
      final x = 6.75 + i * _railGap;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(_RailsPainter old) =>
      old.depth != depth || old.color != color;
}

class _Tag extends StatelessWidget {
  final String label;
  final bool mod;
  const _Tag(this.label, {this.mod = false});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = mod ? scheme.tertiary : scheme.primary;
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 10,
          ),
        ),
      ),
    );
  }
}
