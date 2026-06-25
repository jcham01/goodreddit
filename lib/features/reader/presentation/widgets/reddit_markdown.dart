import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Renders Reddit markdown (post self-text and comment bodies) with themed
/// styling and external link handling. Shared so self-text and comments look
/// identical.
class RedditMarkdown extends StatelessWidget {
  final String data;
  final TextStyle? baseStyle;

  const RedditMarkdown({super.key, required this.data, this.baseStyle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final base = baseStyle ?? theme.textTheme.bodyMedium;
    return MarkdownBody(
      data: data,
      selectable: false,
      onTapLink: (text, href, title) async {
        if (href == null) return;
        final uri = Uri.tryParse(href);
        if (uri == null) return;
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      },
      styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
        p: base,
        a: TextStyle(
          color: scheme.primary,
          decoration: TextDecoration.underline,
          decorationColor: scheme.primary,
        ),
        code: TextStyle(
          backgroundColor: scheme.surfaceContainerHighest,
          fontFamily: 'monospace',
          fontSize: (base?.fontSize ?? 14) - 1,
        ),
        codeblockDecoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        blockquote: base?.copyWith(color: scheme.onSurfaceVariant),
        blockquoteDecoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(6),
          border: Border(left: BorderSide(color: scheme.primary, width: 3)),
        ),
        blockquotePadding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
      ),
    );
  }
}
