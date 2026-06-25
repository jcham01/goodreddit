import 'package:flutter/material.dart';
import 'package:goodreddit/core/util/reddit_text.dart';
import 'package:goodreddit/features/reader/presentation/pages/subreddit_page.dart';

/// The "r/sub" label. Tappable (→ [SubredditPage]) for real subreddits; a plain
/// muted label for user-profile pseudo-subs (`u_…`) and empty names, which have
/// no `/r/<name>` endpoint.
class SubredditLink extends StatelessWidget {
  final String subreddit;
  final TextStyle? style;

  const SubredditLink({super.key, required this.subreddit, this.style});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final browsable = isBrowsableSubreddit(subreddit);
    final label = subreddit.startsWith('u_')
        ? 'u/${subreddit.substring(2)}'
        : 'r/$subreddit';
    final text = Text(
      label,
      style: (style ?? theme.textTheme.labelMedium)?.copyWith(
        color: browsable
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w600,
      ),
    );
    if (!browsable) return text;
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => SubredditPage(name: subreddit)),
      ),
      child: text,
    );
  }
}
