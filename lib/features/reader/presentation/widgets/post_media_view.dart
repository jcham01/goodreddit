import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:goodreddit/features/reader/domain/entities/post_media.dart';
import 'package:goodreddit/features/reader/presentation/widgets/full_screen_gallery.dart';
import 'package:goodreddit/features/scraper/domain/entities/post.dart';
import 'package:url_launcher/url_launcher.dart';

/// The media block under the title: image, swipeable gallery, external-link
/// card, or video poster. NSFW / spoiler content is hidden behind a tap-to-show
/// gate so the image is never fetched until the user opts in.
class PostMediaView extends StatelessWidget {
  final Post post;
  final PostMedia media;

  const PostMediaView({super.key, required this.post, required this.media});

  @override
  Widget build(BuildContext context) {
    if (media.kind == MediaKind.none) return const SizedBox.shrink();

    final child = switch (media.kind) {
      MediaKind.image => _Image(image: media.images.first),
      MediaKind.gallery => _Gallery(images: media.images),
      MediaKind.video => _LinkCard(
        url: media.externalUrl,
        previewUrl: media.previewUrl,
        icon: Icons.play_circle_outline,
        title: 'Vidéo',
      ),
      MediaKind.link => _LinkCard(
        url: media.externalUrl,
        previewUrl: media.previewUrl,
        icon: Icons.open_in_new,
        title: _host(media.externalUrl) ?? 'Lien externe',
      ),
      MediaKind.none => const SizedBox.shrink(),
    };

    final sensitive = post.over18 || post.spoiler;
    final gated = sensitive
        ? _SensitiveGate(
            label: post.over18 ? 'Contenu sensible (NSFW)' : 'Spoiler',
            child: child,
          )
        : child;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: gated,
    );
  }

  static String? _host(String? url) {
    if (url == null) return null;
    final host = Uri.tryParse(url)?.host;
    if (host == null || host.isEmpty) return null;
    return host.startsWith('www.') ? host.substring(4) : host;
  }
}

Future<void> _open(String? url) async {
  if (url == null) return;
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

class _Image extends StatelessWidget {
  final MediaImage image;
  const _Image({required this.image});

  @override
  Widget build(BuildContext context) {
    final ratio = image.aspectRatio;
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => FullScreenGallery(images: [image]),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 480),
          child: AspectRatio(
            aspectRatio: (ratio == null || ratio <= 0) ? 16 / 9 : ratio,
            child: CachedNetworkImage(
              imageUrl: image.url,
              fit: BoxFit.cover,
              placeholder: (_, __) => const _ImagePlaceholder(),
              errorWidget: (_, __, ___) => const _ImageError(),
            ),
          ),
        ),
      ),
    );
  }
}

class _Gallery extends StatefulWidget {
  final List<MediaImage> images;
  const _Gallery({required this.images});

  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // One shared box from the first image's ratio (clamped), with BoxFit.contain
    // so mixed-orientation galleries letterbox instead of cropping.
    final ratios = widget.images
        .map((i) => i.aspectRatio)
        .whereType<double>()
        .toList();
    final ratio = (ratios.isEmpty ? 16 / 9 : ratios.first).clamp(0.5, 2.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: ratio,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: scheme.surfaceContainerHighest),
            PageView.builder(
              controller: _controller,
              itemCount: widget.images.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (_, i) => GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => FullScreenGallery(
                      images: widget.images,
                      initialIndex: i,
                    ),
                  ),
                ),
                child: CachedNetworkImage(
                  imageUrl: widget.images[i].url,
                  fit: BoxFit.contain,
                  placeholder: (_, __) => const _ImagePlaceholder(),
                  errorWidget: (_, __, ___) => const _ImageError(),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_index + 1} / ${widget.images.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LinkCard extends StatelessWidget {
  final String? url;
  final String? previewUrl;
  final IconData icon;
  final String title;

  const _LinkCard({
    required this.url,
    required this.previewUrl,
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => _open(url),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            if (previewUrl != null)
              CachedNetworkImage(
                imageUrl: previewUrl!,
                width: 96,
                height: 96,
                fit: BoxFit.cover,
                placeholder: (_, __) => const SizedBox(width: 96, height: 96),
                errorWidget: (_, __, ___) =>
                    const SizedBox(width: 96, height: 96),
              )
            else
              Container(
                width: 96,
                height: 96,
                color: theme.colorScheme.surfaceContainerHighest,
                child: Icon(icon, color: theme.colorScheme.onSurfaceVariant),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(icon, size: 14, color: theme.colorScheme.primary),
                        const SizedBox(width: 4),
                        Text(
                          'Ouvrir',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Hides sensitive media until the user taps "Afficher" (and only then fetches
/// the image).
class _SensitiveGate extends StatefulWidget {
  final String label;
  final Widget child;

  const _SensitiveGate({required this.label, required this.child});

  @override
  State<_SensitiveGate> createState() => _SensitiveGateState();
}

class _SensitiveGateState extends State<_SensitiveGate> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    if (_revealed) return widget.child;
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => setState(() => _revealed = true),
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.visibility_off_outlined,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Text(widget.label, style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            FilledButton.tonalIcon(
              onPressed: () => setState(() => _revealed = true),
              icon: const Icon(Icons.visibility_outlined, size: 18),
              label: const Text('Afficher'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

class _ImageError extends StatelessWidget {
  const _ImageError();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      color: scheme.surfaceContainerHighest,
      child: Center(
        child: Icon(Icons.broken_image_outlined, color: scheme.onSurfaceVariant),
      ),
    );
  }
}
