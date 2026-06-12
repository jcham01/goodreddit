import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:goodreddit/features/generator/presentation/bloc/generator_cubit.dart';
import 'package:goodreddit/features/generator/presentation/pages/export_page.dart';
import 'package:goodreddit/features/scraper/domain/entities/comment.dart';
import 'package:goodreddit/features/scraper/domain/entities/post.dart';
import 'package:goodreddit/features/scraper/presentation/bloc/scraper_cubit.dart';
import 'package:goodreddit/features/scraper/presentation/widgets/comment_card.dart';
import 'package:goodreddit/features/scraper/presentation/widgets/post_card.dart';
import 'package:goodreddit/features/search/domain/entities/subreddit.dart';

class SubredditDetailPage extends StatelessWidget {
  final Subreddit subreddit;

  const SubredditDetailPage({super.key, required this.subreddit});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GetIt.I<ScraperCubit>()..scrape(subreddit.name),
      child: _DetailView(subreddit: subreddit),
    );
  }
}

class _DetailView extends StatefulWidget {
  final Subreddit subreddit;
  const _DetailView({required this.subreddit});

  @override
  State<_DetailView> createState() => _DetailViewState();
}

class _DetailViewState extends State<_DetailView> {
  final _filterController = TextEditingController();
  String _filter = '';

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  List<Post> _filterPosts(List<Post> posts) {
    final filter = _filter.trim().toLowerCase();
    if (filter.isEmpty) return posts;
    return posts
        .where(
          (p) =>
              p.title.toLowerCase().contains(filter) ||
              p.selfText.toLowerCase().contains(filter) ||
              p.author.toLowerCase().contains(filter),
        )
        .toList();
  }

  List<Comment> _filterComments(List<Comment> comments) {
    final filter = _filter.trim().toLowerCase();
    if (filter.isEmpty) return comments;
    return comments
        .where(
          (c) =>
              c.body.toLowerCase().contains(filter) ||
              c.author.toLowerCase().contains(filter),
        )
        .toList();
  }

  void _openPost(Post post, List<Comment> allComments) {
    final postComments = allComments.where((c) => c.postId == post.id).toList();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            Text(
              post.title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'u/${post.author} · ${post.score} points · '
              '${post.numComments} comments',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (post.selfText.isNotEmpty) ...[
              const SizedBox(height: 12),
              SelectableText(
                post.selfText,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            const Divider(height: 32),
            Text(
              postComments.isEmpty
                  ? 'No scraped comments for this post.'
                  : 'Comments (${postComments.length})',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            for (final c in postComments) CommentCard(comment: c),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.subreddit.displayName),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Posts'),
              Tab(text: 'Comments'),
            ],
          ),
        ),
        floatingActionButton: BlocBuilder<ScraperCubit, ScraperState>(
          builder: (context, state) {
            if (state.status != ScraperStatus.loaded) {
              return const SizedBox.shrink();
            }
            return FloatingActionButton.extended(
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Generate'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => BlocProvider(
                    create: (_) => GetIt.I<GeneratorCubit>(),
                    child: ExportPage(
                      subreddit: widget.subreddit,
                      posts: state.posts,
                      comments: state.comments,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        body: BlocBuilder<ScraperCubit, ScraperState>(
          builder: (context, state) {
            switch (state.status) {
              case ScraperStatus.loading:
              case ScraperStatus.initial:
                return const Center(child: CircularProgressIndicator());
              case ScraperStatus.error:
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      state.errorMessage ?? 'Failed to load content',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              case ScraperStatus.loaded:
                final posts = _filterPosts(state.posts);
                final comments = _filterComments(state.comments);
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                      child: TextField(
                        controller: _filterController,
                        decoration: InputDecoration(
                          hintText: 'Filter posts and comments…',
                          prefixIcon: const Icon(Icons.filter_list),
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          suffixIcon: _filter.isEmpty
                              ? null
                              : IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _filterController.clear();
                                    setState(() => _filter = '');
                                  },
                                ),
                        ),
                        onChanged: (v) => setState(() => _filter = v),
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          posts.isEmpty
                              ? const Center(child: Text('No posts.'))
                              : ListView.builder(
                                  itemCount: posts.length,
                                  itemBuilder: (_, i) => PostCard(
                                    post: posts[i],
                                    onTap: () =>
                                        _openPost(posts[i], state.comments),
                                  ),
                                ),
                          comments.isEmpty
                              ? const Center(child: Text('No comments.'))
                              : ListView.builder(
                                  itemCount: comments.length,
                                  itemBuilder: (_, i) =>
                                      CommentCard(comment: comments[i]),
                                ),
                        ],
                      ),
                    ),
                  ],
                );
            }
          },
        ),
      ),
    );
  }
}
