import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goodreddit/core/widgets/auth_banner.dart';
import 'package:goodreddit/core/widgets/reader_state_views.dart';
import 'package:goodreddit/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:goodreddit/features/auth/presentation/pages/login_page.dart';
import 'package:goodreddit/features/reader/domain/entities/feed_source.dart';
import 'package:goodreddit/features/reader/presentation/bloc/feed_cubit.dart';
import 'package:goodreddit/features/reader/presentation/widgets/post_list_view.dart';
import 'package:goodreddit/features/reader/presentation/widgets/post_skeleton.dart';

/// Home feed (read-only): a paginated Reddit listing with Home/Popular sources.
class FeedTab extends StatefulWidget {
  const FeedTab({super.key});

  @override
  State<FeedTab> createState() => _FeedTabState();
}

class _FeedTabState extends State<FeedTab> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    context.read<FeedCubit>().load();
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
      context.read<FeedCubit>().loadMore();
    }
  }

  Future<void> _openLogin() async {
    final ok = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const LoginPage()));
    if (ok == true && mounted) {
      await context.read<AuthCubit>().refresh();
      if (mounted) context.read<FeedCubit>().refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: BlocSelector<FeedCubit, FeedState, FeedSource>(
            selector: (state) => state.source,
            builder: (context, source) {
              return SegmentedButton<FeedSource>(
                segments: const [
                  ButtonSegment(
                    value: FeedSource.home,
                    label: Text('Accueil'),
                    icon: Icon(Icons.home_outlined),
                  ),
                  ButtonSegment(
                    value: FeedSource.popular,
                    label: Text('Populaire'),
                    icon: Icon(Icons.trending_up),
                  ),
                ],
                selected: {source},
                onSelectionChanged: (s) =>
                    context.read<FeedCubit>().setSource(s.first),
              );
            },
          ),
        ),
        AuthBanner(onSignIn: _openLogin),
        Expanded(
          child: BlocBuilder<FeedCubit, FeedState>(
            builder: (context, state) {
              if (state.posts.isEmpty) {
                switch (state.status) {
                  case FeedStatus.initial:
                  case FeedStatus.loading:
                    return const PostSkeletonList();
                  case FeedStatus.error:
                    return ReaderErrorView(
                      message: state.needsAuth
                          ? 'Connectez-vous pour afficher votre fil personnalisé.'
                          : 'Impossible de charger le fil.',
                      onRetry: () => context.read<FeedCubit>().load(),
                      needsAuth: state.needsAuth,
                      onSignIn: _openLogin,
                    );
                  case FeedStatus.loaded:
                    return ReaderEmptyView(
                      icon: Icons.inbox_outlined,
                      title: 'Rien à afficher',
                      subtitle: 'Essayez « Populaire » ou réessayez plus tard.',
                    );
                }
              }
              return PostListView(
                posts: state.posts,
                loadingMore: state.loadingMore,
                controller: _scroll,
                onRefresh: () => context.read<FeedCubit>().refresh(),
              );
            },
          ),
        ),
      ],
    );
  }
}
