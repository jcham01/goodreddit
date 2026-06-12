import 'package:flutter/material.dart';
import 'package:goodreddit/features/history/domain/entities/research_session.dart';
import 'package:goodreddit/features/scraper/presentation/pages/subreddit_detail_page.dart';
import 'package:goodreddit/features/search/presentation/widgets/score_card.dart';

/// Read-only view of a saved research session: its query and the ranked
/// results as they were at search time. Each result opens the live subreddit.
class SessionDetailPage extends StatelessWidget {
  final ResearchSession session;

  const SessionDetailPage({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(session.query)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              '${session.rankedResults.length} results · '
              'saved ${_formatDate(session.updatedAt)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          for (final score in session.rankedResults)
            ScoreCard(
              score: score,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      SubredditDetailPage(subreddit: score.subreddit),
                ),
              ),
            ),
          if (session.memoryContent != null)
            _ContentBlock(title: 'MEMORY.md', content: session.memoryContent!),
          if (session.skillContent != null)
            _ContentBlock(title: 'SKILL.md', content: session.skillContent!),
        ],
      ),
    );
  }

  static String _formatDate(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)} ${two(d.hour)}:${two(d.minute)}';
  }
}

class _ContentBlock extends StatelessWidget {
  final String title;
  final String content;

  const _ContentBlock({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
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
