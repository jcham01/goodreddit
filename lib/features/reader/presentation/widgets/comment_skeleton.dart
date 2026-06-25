import 'package:flutter/material.dart';

/// Placeholder rows shown while a post's comment thread loads.
class CommentSkeletonList extends StatelessWidget {
  final int count;
  const CommentSkeletonList({super.key, this.count = 5});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(count, (i) => _SkeletonRow(indent: i.isOdd)),
    );
  }
}

class _SkeletonRow extends StatelessWidget {
  final bool indent;
  const _SkeletonRow({required this.indent});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    Widget bar(double width, double height) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(indent ? 32 : 16, 10, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          bar(120, 12),
          const SizedBox(height: 8),
          bar(double.infinity, 12),
          const SizedBox(height: 6),
          bar(220, 12),
        ],
      ),
    );
  }
}
