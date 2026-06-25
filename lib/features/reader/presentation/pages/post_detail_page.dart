import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:goodreddit/core/util/thread.dart';
import 'package:goodreddit/core/widgets/reader_state_views.dart';
import 'package:goodreddit/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:goodreddit/features/auth/presentation/pages/login_page.dart';
import 'package:goodreddit/features/reader/domain/entities/comment_sort.dart';
import 'package:goodreddit/features/reader/domain/entities/thread_item.dart';
import 'package:goodreddit/features/reader/presentation/bloc/post_detail_cubit.dart';
import 'package:goodreddit/features/reader/presentation/widgets/comment_skeleton.dart';
import 'package:goodreddit/features/reader/presentation/widgets/comment_tile.dart';
import 'package:goodreddit/features/reader/presentation/widgets/more_comments_tile.dart';
import 'package:goodreddit/features/reader/presentation/widgets/post_header.dart';
import 'package:goodreddit/features/reader/presentation/widgets/post_media_view.dart';
import 'package:goodreddit/features/reader/presentation/widgets/reddit_markdown.dart';
import 'package:goodreddit/features/scraper/domain/entities/post.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// In-app post detail: header, media, self-text, and a threaded comment list.
class PostDetailPage extends StatelessWidget {
  final Post post;

  const PostDetailPage({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GetIt.I<PostDetailCubit>(param1: post)..load(),
      child: const _DetailView(),
    );
  }
}

class _DetailView extends StatefulWidget {
  const _DetailView();

  @override
  State<_DetailView> createState() => _DetailViewState();
}

class _DetailViewState extends State<_DetailView> {
  final Set<String> _collapsed = {};

  // Descendant counts are memoized: recomputed only when the thread changes,
  // not on every collapse/sort/refresh rebuild.
  List<ThreadItem>? _countsThread;
  Map<String, int> _countsCache = const {};

  Map<String, int> _hiddenCountsFor(List<ThreadItem> thread) {
    if (!identical(thread, _countsThread)) {
      _countsThread = thread;
      _countsCache = descendantCounts(thread);
    }
    return _countsCache;
  }

  void _toggle(String id) {
    setState(() {
      if (!_collapsed.remove(id)) _collapsed.add(id);
    });
  }

  Future<void> _openExternal(Post post) async {
    final uri = Uri.tryParse(post.fullPermalink);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _openLogin() async {
    final ok = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const LoginPage()));
    if (ok == true && mounted) {
      await context.read<AuthCubit>().refresh();
      if (mounted) context.read<PostDetailCubit>().refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PostDetailCubit, PostDetailState>(
      // Surface a transient error when comments are already shown (a failed
      // re-sort / refresh) — the inline error view only covers the first load.
      listenWhen: (prev, curr) =>
          curr.status == PostDetailStatus.error &&
          curr.detail != null &&
          prev.status != PostDetailStatus.error,
      listener: (context, state) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Impossible de mettre à jour les commentaires.'),
            ),
          );
      },
      builder: (context, state) {
        final post = state.post;
        final cubit = context.read<PostDetailCubit>();
        return Scaffold(
          appBar: AppBar(
            title: Text('r/${post.subreddit}'),
            actions: [
              PopupMenuButton<CommentSort>(
                icon: const Icon(Icons.sort),
                tooltip: 'Trier les commentaires',
                initialValue: state.sort,
                onSelected: cubit.setSort,
                itemBuilder: (_) => [
                  for (final s in CommentSort.values)
                    PopupMenuItem(value: s, child: Text(s.label)),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.share_outlined),
                tooltip: 'Partager',
                onPressed: () =>
                    Share.share(post.fullPermalink, subject: post.title),
              ),
              IconButton(
                icon: const Icon(Icons.open_in_browser),
                tooltip: 'Ouvrir dans le navigateur',
                onPressed: () => _openExternal(post),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: cubit.refresh,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _PostBody(state: state, onNeedsAuth: _openLogin),
                ),
                ..._commentsSlivers(context, state),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _commentsSlivers(BuildContext context, PostDetailState state) {
    final detail = state.detail;

    // First load still in flight.
    if (detail == null) {
      if (state.status == PostDetailStatus.error) {
        return [
          SliverFillRemaining(
            hasScrollBody: false,
            child: ReaderErrorView(
              message: state.needsAuth
                  ? 'Connectez-vous pour afficher ce post.'
                  : 'Impossible de charger les commentaires.',
              onRetry: () => context.read<PostDetailCubit>().load(),
              needsAuth: state.needsAuth,
              onSignIn: _openLogin,
            ),
          ),
        ];
      }
      return const [SliverToBoxAdapter(child: CommentSkeletonList())];
    }

    final thread = detail.thread;
    if (thread.isEmpty) {
      return const [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: ReaderEmptyView(
              icon: Icons.mode_comment_outlined,
              title: 'Aucun commentaire',
              subtitle: 'Soyez le premier à lancer la discussion.',
            ),
          ),
        ),
      ];
    }

    // Descendant counts (over the full thread) label collapsed comments.
    final hiddenCounts = _hiddenCountsFor(thread);
    final visible = visibleThread(thread, _collapsed);
    return [
      SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final item = visible[index];
          return switch (item) {
            CommentNode() => CommentTile(
              key: ValueKey(item.id),
              node: item,
              collapsed: _collapsed.contains(item.id),
              hiddenCount: hiddenCounts[item.id] ?? 0,
              onToggle: () => _toggle(item.id),
            ),
            MoreNode() => MoreCommentsTile(
              node: item,
              onTap: () => _openExternal(state.post),
            ),
          };
        }, childCount: visible.length),
      ),
    ];
  }
}

/// Header + media + self-text + the "Commentaires" separator.
class _PostBody extends StatelessWidget {
  final PostDetailState state;
  final VoidCallback onNeedsAuth;

  const _PostBody({required this.state, required this.onNeedsAuth});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final post = state.post;
    final detail = state.detail;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PostHeader(post: post, onNeedsAuth: onNeedsAuth),
        if (detail != null)
          PostMediaView(post: post, media: detail.media),
        if (post.selfText.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: RedditMarkdown(data: post.selfText),
          ),
        const Divider(height: 24),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          child: Row(
            children: [
              Text(
                'Commentaires',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (detail != null) ...[
                const SizedBox(width: 6),
                Text(
                  '· ${detail.commentCount}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const Spacer(),
              if (state.status == PostDetailStatus.loading && detail != null)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}
