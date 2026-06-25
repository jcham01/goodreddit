import 'package:flutter/material.dart';

/// Static placeholder list shown while the first page loads (no shimmer dep).
class PostSkeletonList extends StatelessWidget {
  final int count;
  const PostSkeletonList({super.key, this.count = 6});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      itemBuilder: (_, __) => const _SkeletonCard(),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme.surfaceContainerHighest;
    Widget bar(double w, double h) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: c,
        borderRadius: BorderRadius.circular(4),
      ),
    );
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            bar(120, 12),
            const SizedBox(height: 12),
            bar(double.infinity, 16),
            const SizedBox(height: 8),
            bar(220, 16),
            const SizedBox(height: 16),
            bar(90, 12),
          ],
        ),
      ),
    );
  }
}
