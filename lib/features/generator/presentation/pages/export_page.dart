import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:goodreddit/core/error/failures.dart';
import 'package:goodreddit/core/usecases/usecase.dart';
import 'package:goodreddit/core/widgets/model_badge.dart';
import 'package:goodreddit/features/generator/presentation/bloc/generator_cubit.dart';
import 'package:goodreddit/features/scraper/domain/entities/comment.dart';
import 'package:goodreddit/features/scraper/domain/entities/post.dart';
import 'package:goodreddit/features/search/domain/entities/subreddit.dart';
import 'package:goodreddit/features/settings/domain/entities/agent_config.dart';
import 'package:goodreddit/features/settings/domain/usecases/get_config.dart';

class ExportPage extends StatelessWidget {
  final Subreddit subreddit;
  final List<Post> posts;
  final List<Comment> comments;

  const ExportPage({
    super.key,
    required this.subreddit,
    required this.posts,
    required this.comments,
  });

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<GeneratorCubit>();
    return Scaffold(
      appBar: AppBar(title: Text('Generate · ${subreddit.displayName}')),
      body: BlocConsumer<GeneratorCubit, GeneratorState>(
        listener: (context, state) {
          if (state.status == GeneratorStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage ?? 'Error')),
            );
          }
        },
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'AI agent files',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              FutureBuilder<Either<Failure, AgentConfig>>(
                future: GetIt.I<GetConfig>()(const NoParams()),
                builder: (context, snapshot) {
                  final config = snapshot.data?.fold((_) => null, (c) => c);
                  final configured = config?.isConfigured ?? false;
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: ModelBadge(
                      provider: configured ? config!.provider.label : null,
                      model: configured ? config!.effectiveModel : null,
                      prefix: 'Generates with',
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: state.status == GeneratorStatus.generating
                        ? null
                        : () => cubit.runMemory(
                            subreddit: subreddit,
                            posts: posts,
                            comments: comments,
                          ),
                    icon: const Icon(Icons.psychology_outlined),
                    label: const Text('MEMORY.md'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: state.status == GeneratorStatus.generating
                        ? null
                        : () => cubit.runSkill(
                            subreddit: subreddit,
                            posts: posts,
                            comments: comments,
                          ),
                    icon: const Icon(Icons.handyman_outlined),
                    label: const Text('SKILL.md'),
                  ),
                ],
              ),
              if (state.status == GeneratorStatus.generating)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
              if (state.memoryContent != null)
                _GeneratedBlock(
                  title: 'MEMORY.md',
                  content: state.memoryContent!,
                  onShare: () =>
                      cubit.shareMarkdown('MEMORY.md', state.memoryContent!),
                ),
              if (state.skillContent != null)
                _GeneratedBlock(
                  title: 'SKILL.md',
                  content: state.skillContent!,
                  onShare: () =>
                      cubit.shareMarkdown('SKILL.md', state.skillContent!),
                ),
              const Divider(height: 32),
              Text(
                'Raw data export',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () =>
                        cubit.exportPostsJson(subreddit.name, posts),
                    icon: const Icon(Icons.data_object),
                    label: const Text('Posts JSON'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () =>
                        cubit.exportPostsCsv(subreddit.name, posts),
                    icon: const Icon(Icons.table_chart_outlined),
                    label: const Text('Posts CSV'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () =>
                        cubit.exportCommentsJson(subreddit.name, comments),
                    icon: const Icon(Icons.data_object),
                    label: const Text('Comments JSON'),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _GeneratedBlock extends StatelessWidget {
  final String title;
  final String content;
  final VoidCallback onShare;

  const _GeneratedBlock({
    required this.title,
    required this.content,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                const Spacer(),
                IconButton(icon: const Icon(Icons.share), onPressed: onShare),
              ],
            ),
            SelectableText(
              content,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
