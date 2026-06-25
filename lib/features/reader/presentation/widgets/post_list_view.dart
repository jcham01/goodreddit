import 'package:flutter/material.dart';
import 'package:goodreddit/features/reader/presentation/widgets/post_card.dart';
import 'package:goodreddit/features/scraper/domain/entities/post.dart';

/// Reusable pull-to-refresh + infinite-scroll list of posts. The scroll
/// controller is owned by the host (which drives [loadMore]); this just renders
/// the posts and a trailing spinner while the next page loads.
class PostListView extends StatelessWidget {
  final List<Post> posts;
  final bool loadingMore;
  final ScrollController? controller;
  final Future<void> Function() onRefresh;

  /// Forwarded to each card so a vote/save tap while signed out opens login.
  final VoidCallback onNeedsAuth;

  const PostListView({
    super.key,
    required this.posts,
    required this.onRefresh,
    required this.onNeedsAuth,
    this.controller,
    this.loadingMore = false,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        controller: controller,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 16),
        itemCount: posts.length + (loadingMore ? 1 : 0),
        itemBuilder: (context, i) {
          if (i >= posts.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return PostCard(post: posts[i], onNeedsAuth: onNeedsAuth);
        },
      ),
    );
  }
}
