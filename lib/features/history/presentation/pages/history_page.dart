import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:goodreddit/features/history/domain/entities/research_session.dart';
import 'package:goodreddit/features/history/presentation/bloc/history_cubit.dart';
import 'package:goodreddit/features/history/presentation/pages/session_detail_page.dart';

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

class _HistoryView extends StatefulWidget {
  const _HistoryView();

  @override
  State<_HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<_HistoryView> {
  final _filterController = TextEditingController();
  String _filter = '';

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  List<ResearchSession> _applyFilter(List<ResearchSession> sessions) {
    final filter = _filter.trim().toLowerCase();
    if (filter.isEmpty) return sessions;
    return sessions.where((s) {
      if (s.query.toLowerCase().contains(filter)) return true;
      return s.rankedResults.any(
        (r) => r.subreddit.displayName.toLowerCase().contains(filter),
      );
    }).toList();
  }

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
              final sessions = _applyFilter(state.sessions);
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: TextField(
                      controller: _filterController,
                      decoration: InputDecoration(
                        hintText: 'Filter by query or subreddit…',
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
                    child: sessions.isEmpty
                        ? const Center(
                            child: Text('No session matches the filter.'),
                          )
                        : ListView.separated(
                            itemCount: sessions.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (context, i) {
                              final s = sessions[i];
                              return _SessionTile(session: s);
                            },
                          ),
                  ),
                ],
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
      subtitle: Text(
        [
          '${session.rankedResults.length} results',
          if (top != null) 'top: $top',
          _formatDate(session.updatedAt),
        ].join(' · '),
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => SessionDetailPage(session: session)),
      ),
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
