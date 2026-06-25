import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goodreddit/features/history/domain/entities/research_session.dart';
import 'package:goodreddit/features/history/presentation/bloc/history_cubit.dart';
import 'package:goodreddit/features/history/presentation/pages/session_detail_page.dart';

/// Library tab: saved searches and the agent files generated from them.
/// Hosted inside [HomeShell]; the [HistoryCubit] is provided app-wide so the
/// shell can refresh it when this tab becomes visible.
class LibraryTab extends StatefulWidget {
  const LibraryTab({super.key});

  @override
  State<LibraryTab> createState() => _LibraryTabState();
}

class _LibraryTabState extends State<LibraryTab> {
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
    return BlocBuilder<HistoryCubit, HistoryState>(
      builder: (context, state) {
        switch (state.status) {
          case HistoryStatus.loading:
          case HistoryStatus.initial:
            return const Center(child: CircularProgressIndicator());
          case HistoryStatus.error:
            return Center(child: Text(state.errorMessage ?? 'Erreur'));
          case HistoryStatus.loaded:
            if (state.sessions.isEmpty) {
              return const _EmptyLibrary();
            }
            final sessions = _applyFilter(state.sessions);
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    controller: _filterController,
                    decoration: InputDecoration(
                      hintText: 'Filtrer par requête ou subreddit…',
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
                          child: Text('Aucun élément ne correspond au filtre.'),
                        )
                      : ListView.separated(
                          itemCount: sessions.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, i) =>
                              _SessionTile(session: sessions[i]),
                        ),
                ),
              ],
            );
        }
      },
    );
  }
}

class _EmptyLibrary extends StatelessWidget {
  const _EmptyLibrary();

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.library_books_outlined, size: 48, color: muted),
            const SizedBox(height: 16),
            Text(
              'Votre bibliothèque est vide',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Vos recherches et les fichiers MEMORY.md / SKILL.md générés '
              's’archivent automatiquement ici.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: muted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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
    final meta = [
      '${session.rankedResults.length} résultats',
      if (top != null) 'top : $top',
      _formatDate(session.updatedAt),
    ].join(' · ');
    final hasMemory = session.memoryContent != null;
    final hasSkill = session.skillContent != null;

    return ListTile(
      leading: const Icon(Icons.search),
      title: Text(session.query),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(meta),
          if (hasMemory || hasSkill)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Wrap(
                spacing: 6,
                children: [
                  if (hasMemory) const _FileTag('MEMORY.md'),
                  if (hasSkill) const _FileTag('SKILL.md'),
                ],
              ),
            ),
        ],
      ),
      isThreeLine: hasMemory || hasSkill,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => SessionDetailPage(session: session)),
      ),
      trailing: IconButton(
        tooltip: 'Supprimer cette recherche',
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

class _FileTag extends StatelessWidget {
  final String label;
  const _FileTag(this.label);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: scheme.onSecondaryContainer,
        ),
      ),
    );
  }
}
