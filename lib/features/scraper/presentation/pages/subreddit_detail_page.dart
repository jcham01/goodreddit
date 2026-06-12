import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:goodreddit/features/generator/presentation/bloc/generator_cubit.dart';
import 'package:goodreddit/features/generator/presentation/pages/export_page.dart';
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

class _DetailView extends StatelessWidget {
  final Subreddit subreddit;
  const _DetailView({required this.subreddit});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(subreddit.displayName),
          bottom: const TabBar(
            tabs: [Tab(text: 'Posts'), Tab(text: 'Comments')],
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
                      subreddit: subreddit,
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
                return TabBarView(
                  children: [
                    state.posts.isEmpty
                        ? const Center(child: Text('No posts.'))
                        : ListView.builder(
                            itemCount: state.posts.length,
                            itemBuilder: (_, i) =>
                                PostCard(post: state.posts[i]),
                          ),
                    state.comments.isEmpty
                        ? const Center(child: Text('No comments.'))
                        : ListView.builder(
                            itemCount: state.comments.length,
                            itemBuilder: (_, i) =>
                                CommentCard(comment: state.comments[i]),
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
