import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:goodreddit/core/widgets/reader_state_views.dart';
import 'package:goodreddit/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:goodreddit/features/auth/presentation/pages/login_page.dart';
import 'package:goodreddit/features/reader/domain/entities/subreddit_about.dart';
import 'package:goodreddit/features/reader/domain/entities/subreddit_sort.dart';
import 'package:goodreddit/features/reader/presentation/bloc/subreddit_cubit.dart';
import 'package:goodreddit/features/reader/presentation/widgets/post_list_view.dart';
import 'package:goodreddit/features/reader/presentation/widgets/post_skeleton.dart';
import 'package:goodreddit/features/reader/presentation/widgets/subreddit_header.dart';

/// In-app subreddit browser: about header + a sortable, paginated listing.
class SubredditPage extends StatelessWidget {
  final String name;

  const SubredditPage({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GetIt.I<SubredditCubit>(param1: name)..load(),
      child: _SubredditView(name: name),
    );
  }
}

class _SubredditView extends StatefulWidget {
  final String name;
  const _SubredditView({required this.name});

  @override
  State<_SubredditView> createState() => _SubredditViewState();
}

class _SubredditViewState extends State<_SubredditView> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final pos = _scroll.position;
    if (pos.pixels >= pos.maxScrollExtent * 0.8) {
      context.read<SubredditCubit>().loadMore();
    }
  }

  Future<void> _openLogin() async {
    final ok = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const LoginPage()));
    if (ok == true && mounted) {
      await context.read<AuthCubit>().refresh();
      if (mounted) context.read<SubredditCubit>().refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('r/${widget.name}')),
      body: Column(
        children: [
          BlocSelector<SubredditCubit, SubredditState, SubredditAboutSel>(
            selector: (s) => SubredditAboutSel(s.name, s.about),
            builder: (context, sel) => SubredditHeader(
              name: sel.name,
              about: sel.about,
              onNeedsAuth: _openLogin,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
            child: BlocSelector<SubredditCubit, SubredditState, SubredditSort>(
              selector: (s) => s.sort,
              builder: (context, sort) => SizedBox(
                width: double.infinity,
                child: SegmentedButton<SubredditSort>(
                  showSelectedIcon: false,
                  segments: [
                    for (final s in SubredditSort.values)
                      ButtonSegment(value: s, label: Text(s.label)),
                  ],
                  selected: {sort},
                  onSelectionChanged: (s) =>
                      context.read<SubredditCubit>().setSort(s.first),
                ),
              ),
            ),
          ),
          Expanded(
            child: BlocBuilder<SubredditCubit, SubredditState>(
              builder: (context, state) {
                if (state.posts.isEmpty) {
                  switch (state.status) {
                    case SubredditStatus.initial:
                    case SubredditStatus.loading:
                      return const PostSkeletonList();
                    case SubredditStatus.error:
                      return ReaderErrorView(
                        message: state.needsAuth
                            ? 'Connectez-vous pour afficher ce subreddit.'
                            : 'Impossible de charger r/${widget.name}.',
                        onRetry: () => context.read<SubredditCubit>().refresh(),
                        needsAuth: state.needsAuth,
                        onSignIn: _openLogin,
                      );
                    case SubredditStatus.loaded:
                      return const ReaderEmptyView(
                        icon: Icons.inbox_outlined,
                        title: 'Rien à afficher',
                        subtitle: 'Aucun post pour ce tri.',
                      );
                  }
                }
                return PostListView(
                  posts: state.posts,
                  loadingMore: state.loadingMore,
                  controller: _scroll,
                  onRefresh: () => context.read<SubredditCubit>().refresh(),
                  onNeedsAuth: _openLogin,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Small selector tuple so the header only rebuilds when name/about change.
class SubredditAboutSel {
  final String name;
  final SubredditAbout? about;
  const SubredditAboutSel(this.name, this.about);

  @override
  bool operator ==(Object other) =>
      other is SubredditAboutSel && other.name == name && other.about == about;

  @override
  int get hashCode => Object.hash(name, about);
}
