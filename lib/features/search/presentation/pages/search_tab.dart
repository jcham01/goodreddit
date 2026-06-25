import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goodreddit/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:goodreddit/features/auth/presentation/pages/login_page.dart';
import 'package:goodreddit/features/scraper/presentation/pages/subreddit_detail_page.dart';
import 'package:goodreddit/features/search/domain/entities/search_ranking_result.dart';
import 'package:goodreddit/features/search/domain/entities/subreddit_score.dart';
import 'package:goodreddit/features/search/presentation/bloc/search_cubit.dart';
import 'package:goodreddit/features/search/presentation/widgets/ranking_badge.dart';
import 'package:goodreddit/features/search/presentation/widgets/score_card.dart';

/// Search-and-rank surface, hosted as a tab inside [HomeShell] (it no longer
/// owns a Scaffold/AppBar — the shell provides them).
class SearchTab extends StatefulWidget {
  const SearchTab({super.key});

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  final _controller = TextEditingController();
  final _filterController = TextEditingController();
  String _filter = '';

  @override
  void dispose() {
    _controller.dispose();
    _filterController.dispose();
    super.dispose();
  }

  List<SubredditScore> _applyFilter(List<SubredditScore> results) {
    final filter = _filter.trim().toLowerCase();
    if (filter.isEmpty) return results;
    return results.where((s) {
      final sub = s.subreddit;
      return sub.displayName.toLowerCase().contains(filter) ||
          sub.title.toLowerCase().contains(filter) ||
          sub.description.toLowerCase().contains(filter);
    }).toList();
  }

  Future<void> _openLogin() async {
    final ok = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const LoginPage()));
    if (ok == true && mounted) {
      await context.read<AuthCubit>().refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _AuthBanner(onSignIn: _openLogin),
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _controller,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Rechercher des subreddits…',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onSubmitted: (q) => context.read<SearchCubit>().search(q),
          ),
        ),
        Expanded(
          child: BlocBuilder<SearchCubit, SearchState>(
            builder: (context, state) {
              switch (state.status) {
                case SearchStatus.loading:
                  return const Center(child: CircularProgressIndicator());
                case SearchStatus.empty:
                  return const _Centered('Aucun subreddit trouvé.');
                case SearchStatus.error:
                  return _ErrorView(
                    message: state.errorMessage ?? 'Une erreur est survenue.',
                    needsAuth: state.needsAuth,
                    onSignIn: _openLogin,
                  );
                case SearchStatus.loaded:
                  final visible = _applyFilter(state.results);
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: TextField(
                          controller: _filterController,
                          decoration: InputDecoration(
                            hintText: 'Filtrer les résultats…',
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
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: Row(
                          children: [
                            Flexible(
                              child: RankingBadge(
                                status: state.llmStatus,
                                model: state.modelUsed,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${visible.length}/${state.results.length}',
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ],
                        ),
                      ),
                      if (state.llmStatus == LlmRankingStatus.failed &&
                          (state.llmErrorMessage?.isNotEmpty ?? false))
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'IA indisponible : ${state.llmErrorMessage}',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                            ),
                          ),
                        ),
                      Expanded(
                        child: visible.isEmpty
                            ? const _Centered('Aucun résultat ne correspond au filtre.')
                            : ListView.builder(
                                itemCount: visible.length,
                                itemBuilder: (context, i) {
                                  final score = visible[i];
                                  return ScoreCard(
                                    score: score,
                                    onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => SubredditDetailPage(
                                          subreddit: score.subreddit,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  );
                case SearchStatus.initial:
                  return const _Centered(
                    'Recherchez un subreddit pour commencer.',
                  );
              }
            },
          ),
        ),
      ],
    );
  }
}

class _AuthBanner extends StatelessWidget {
  final VoidCallback onSignIn;
  const _AuthBanner({required this.onSignIn});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        if (state.isAuthenticated) {
          return MaterialBanner(
            content: Text(
              'Connecté${state.username != null ? ' en u/${state.username}' : ''}',
            ),
            leading: const Icon(Icons.verified_user, color: Colors.green),
            actions: [
              TextButton(
                onPressed: () => context.read<AuthCubit>().signOut(),
                child: const Text('SE DÉCONNECTER'),
              ),
            ],
          );
        }
        return MaterialBanner(
          content: const Text(
            'Navigation anonyme. Connectez-vous pour un accès authentifié.',
          ),
          leading: const Icon(Icons.info_outline),
          actions: [
            TextButton(onPressed: onSignIn, child: const Text('SE CONNECTER')),
          ],
        );
      },
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final bool needsAuth;
  final VoidCallback onSignIn;
  const _ErrorView({
    required this.message,
    required this.needsAuth,
    required this.onSignIn,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            if (needsAuth) ...[
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onSignIn,
                child: const Text('Se connecter'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Centered extends StatelessWidget {
  final String text;
  const _Centered(this.text);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(text, textAlign: TextAlign.center),
      ),
    );
  }
}
