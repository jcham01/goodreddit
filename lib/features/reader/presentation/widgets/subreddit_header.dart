import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:goodreddit/core/util/format.dart';
import 'package:goodreddit/features/reader/domain/entities/subreddit_about.dart';

/// "About" block for a subreddit: icon, name, member/online counts, and the
/// public description. Degrades gracefully before [about] arrives.
class SubredditHeader extends StatelessWidget {
  final String name;
  final SubredditAbout? about;

  const SubredditHeader({super.key, required this.name, this.about});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final about = this.about;
    final description = about?.publicDescription.trim() ?? '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Avatar(iconUrl: about?.iconUrl, name: name),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'r/$name',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (about?.over18 ?? false)
                          Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: _Nsfw(),
                          ),
                      ],
                    ),
                    if (about != null)
                      Text(
                        _stats(about),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: muted,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              description,
              style: theme.textTheme.bodySmall,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  String _stats(SubredditAbout about) {
    final members = '${compactCount(about.subscribers)} membres';
    final active = about.activeUsers;
    if (active == null) return members;
    return '$members · ${compactCount(active)} en ligne';
  }
}

class _Avatar extends StatelessWidget {
  final String? iconUrl;
  final String name;
  const _Avatar({required this.iconUrl, required this.name});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final letter = name.isEmpty ? '?' : name[0].toUpperCase();
    final fallback = Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      color: scheme.primaryContainer,
      child: Text(
        letter,
        style: TextStyle(
          color: scheme.onPrimaryContainer,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    return ClipOval(
      child: iconUrl == null
          ? fallback
          : CachedNetworkImage(
              imageUrl: iconUrl!,
              width: 44,
              height: 44,
              fit: BoxFit.cover,
              placeholder: (_, __) => fallback,
              errorWidget: (_, __, ___) => fallback,
            ),
    );
  }
}

class _Nsfw extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'NSFW',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: scheme.onErrorContainer,
        ),
      ),
    );
  }
}
