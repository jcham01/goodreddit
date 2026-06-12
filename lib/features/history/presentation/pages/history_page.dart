import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:goodreddit/features/history/domain/entities/research_session.dart';
import 'package:goodreddit/features/history/presentation/bloc/history_cubit.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GetIt.I<HistoryCubit>()..load(),
      child: const _HistoryView(),
    );
  }
}

class _HistoryView extends StatelessWidget {
  const _HistoryView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search history')),
      body: BlocBuilder<HistoryCubit, HistoryState>(
        builder: (context, state) {
          switch (state.status) {
            case HistoryStatus.loading:
            case HistoryStatus.initial:
              return const Center(child: CircularProgressIndicator());
            case HistoryStatus.error:
              return Center(child: Text(state.errorMessage ?? 'Error'));
            case HistoryStatus.loaded:
              if (state.sessions.isEmpty) {
                return const Center(child: Text('No saved searches yet.'));
              }
              return ListView.separated(
                itemCount: state.sessions.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final s = state.sessions[i];
                  return _SessionTile(session: s);
                },
              );
          }
        },
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  final ResearchSession session;
  const _SessionTile({required this.session});

  @override
  Widget build(BuildContext context) {
    final top = session.rankedResults.isNotEmpty
        ? session.rankedResults.first.subreddit.displayName
        : null;
    return ListTile(
      leading: const Icon(Icons.search),
      title: Text(session.query),
      subtitle: Text([
        '${session.rankedResults.length} results',
        if (top != null) 'top: $top',
        _formatDate(session.updatedAt),
      ].join(' · ')),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        onPressed: () => context.read<HistoryCubit>().remove(session.id),
      ),
    );
  }

  static String _formatDate(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)} ${two(d.hour)}:${two(d.minute)}';
  }
}
