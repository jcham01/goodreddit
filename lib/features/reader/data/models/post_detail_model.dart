import 'package:goodreddit/core/error/exceptions.dart';
import 'package:goodreddit/features/reader/domain/entities/post_detail.dart';
import 'package:goodreddit/features/reader/domain/entities/post_media.dart';
import 'package:goodreddit/features/reader/domain/entities/thread_item.dart';
import 'package:goodreddit/features/scraper/data/models/post_model.dart';

/// Builds a [PostDetail] from Reddit's comments endpoint response, which is a
/// 2-element array: `[post listing, comments listing]`.
class PostDetailModel extends PostDetail {
  const PostDetailModel({
    required super.post,
    required super.media,
    required super.thread,
  });

  factory PostDetailModel.fromResponse(dynamic data) {
    if (data is! List || data.isEmpty) {
      throw const RedditException('Unexpected comments response shape.');
    }
    final postChildren = _childrenOf(data[0]);
    if (postChildren.isEmpty) {
      throw const RedditException('Post not found in response.');
    }
    final firstChild = (postChildren.first as Map).cast<String, dynamic>();
    final post = PostModel.fromJson(firstChild);
    final postData = (firstChild['data'] as Map).cast<String, dynamic>();
    final media = _resolveMediaWithCrosspost(postData);
    final commentsListing = data.length > 1 ? data[1] : null;
    final thread = _flattenComments(commentsListing);
    return PostDetailModel(post: post, media: media, thread: thread);
  }

  // --------------------------------------------------------------------------
  // Comment tree → flat, depth-tagged list
  // --------------------------------------------------------------------------

  static List<ThreadItem> _flattenComments(dynamic commentsListing) {
    final out = <ThreadItem>[];
    _walk(_childrenOf(commentsListing), 0, out);
    return out;
  }

  static void _walk(List children, int depth, List<ThreadItem> out) {
    for (final child in children) {
      if (child is! Map) continue;
      final kind = child['kind'];
      final data = child['data'];
      if (data is! Map) continue;
      if (kind == 't1') {
        out.add(_commentNode(data, depth));
        final replies = data['replies'];
        if (replies is Map) {
          _walk(_childrenOf(replies), depth + 1, out);
        }
      } else if (kind == 'more') {
        final count = (data['count'] as num?)?.toInt() ?? 0;
        // count == 0 is the synthetic "continue this thread →" link; skip it.
        if (count > 0) out.add(MoreNode(count: count, depth: depth));
      }
    }
  }

  static CommentNode _commentNode(Map data, int depth) {
    final edited = data['edited'];
    return CommentNode(
      id: (data['id'] ?? '') as String,
      author: (data['author'] ?? '[deleted]') as String,
      body: (data['body'] ?? '') as String,
      score: (data['score'] as num?)?.toInt() ?? 0,
      scoreHidden: data['score_hidden'] == true,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        ((data['created_utc'] ?? 0) as num).toInt() * 1000,
      ),
      depth: depth,
      isSubmitter: data['is_submitter'] == true,
      isStickied: data['stickied'] == true,
      distinguished: data['distinguished'] as String?,
      edited: edited is num && edited > 0,
    );
  }

  /// The `children` list of a Reddit "Listing" envelope (`{data:{children:[]}}`),
  /// or empty when the shape is absent (e.g. `replies` is the empty string).
  static List _childrenOf(dynamic listing) {
    if (listing is Map) {
      final data = listing['data'];
      if (data is Map) {
        final children = data['children'];
        if (children is List) return children;
      }
    }
    return const [];
  }

  // --------------------------------------------------------------------------
  // Media resolution
  // --------------------------------------------------------------------------

  /// Crossposts carry their media on `crosspost_parent_list[0]` while the outer
  /// post's `url` only points back at the original submission. Resolve from the
  /// parent when it yields media, else fall back to the post itself.
  static PostMedia _resolveMediaWithCrosspost(Map<String, dynamic> data) {
    final parents = data['crosspost_parent_list'];
    if (parents is List && parents.isNotEmpty && parents.first is Map) {
      final parent = (parents.first as Map).cast<String, dynamic>();
      final parentMedia = _resolveMedia(parent);
      if (parentMedia.kind != MediaKind.none) return parentMedia;
    }
    return _resolveMedia(data);
  }

  static PostMedia _resolveMedia(Map<String, dynamic> data) {
    // 1. Native gallery.
    if (data['is_gallery'] == true) {
      final items = _galleryImages(data);
      if (items.isNotEmpty) {
        return PostMedia(
          kind: MediaKind.gallery,
          images: items,
          previewUrl: items.first.url,
        );
      }
    }

    final preview = _previewSource(data);
    final url = (data['url'] ?? '') as String;
    final postHint = data['post_hint'] as String?;
    final isVideo = data['is_video'] == true;

    // 2. Video (Reddit-hosted or embedded). No in-app player yet → open out.
    if (isVideo || postHint == 'hosted:video' || postHint == 'rich:video') {
      return PostMedia(
        kind: MediaKind.video,
        externalUrl: url.isNotEmpty ? url : null,
        previewUrl: preview?.url,
      );
    }

    // 3. Direct image.
    if (postHint == 'image' || _looksLikeImage(url)) {
      // Reuse the preview's known dimensions so the image keeps its real aspect
      // ratio instead of falling back to a cropped 16/9 box.
      final image = _looksLikeImage(url)
          ? MediaImage(url: url, width: preview?.width, height: preview?.height)
          : preview;
      if (image != null) {
        return PostMedia(
          kind: MediaKind.image,
          images: [image],
          previewUrl: image.url,
        );
      }
    }

    // 4. Self post → no media (the body is the content).
    if (data['is_self'] == true) return PostMedia.none;

    // 5. External link, with a thumbnail when Reddit generated a preview.
    if (url.startsWith('http')) {
      return PostMedia(
        kind: MediaKind.link,
        externalUrl: url,
        previewUrl: preview?.url,
      );
    }

    return PostMedia.none;
  }

  static List<MediaImage> _galleryImages(Map<String, dynamic> data) {
    final result = <MediaImage>[];
    final galleryData = data['gallery_data'];
    final metadata = data['media_metadata'];
    if (galleryData is Map && metadata is Map) {
      final items = galleryData['items'];
      if (items is List) {
        for (final item in items) {
          if (item is! Map) continue;
          final meta = metadata[item['media_id']];
          if (meta is! Map) continue;
          final source = meta['s'];
          String? url;
          int? width;
          int? height;
          if (source is Map) {
            // 'u' = still image, 'gif' = animated (renders fine); 'mp4'-only
            // animated items have neither, so fall back to a still preview below.
            final raw = source['u'] ?? source['gif'];
            if (raw is String) url = raw;
            width = (source['x'] as num?)?.toInt();
            height = (source['y'] as num?)?.toInt();
          }
          if (url == null) {
            // mp4-only animated item: keep it in the gallery (so the order and
            // count stay correct) using the largest still preview frame.
            final previews = meta['p'];
            if (previews is List && previews.isNotEmpty) {
              final last = previews.last;
              if (last is Map && last['u'] is String) {
                url = last['u'] as String;
                width = (last['x'] as num?)?.toInt() ?? width;
                height = (last['y'] as num?)?.toInt() ?? height;
              }
            }
          }
          if (url != null) {
            result.add(
              MediaImage(
                url: url.replaceAll('&amp;', '&'),
                width: width,
                height: height,
              ),
            );
          }
        }
      }
    }
    return result;
  }

  static MediaImage? _previewSource(Map<String, dynamic> data) {
    final preview = data['preview'];
    if (preview is Map) {
      final images = preview['images'];
      if (images is List && images.isNotEmpty) {
        final first = images.first;
        if (first is Map) {
          final source = first['source'];
          if (source is Map && source['url'] is String) {
            return MediaImage(
              url: (source['url'] as String).replaceAll('&amp;', '&'),
              width: (source['width'] as num?)?.toInt(),
              height: (source['height'] as num?)?.toInt(),
            );
          }
        }
      }
    }
    return null;
  }

  static bool _looksLikeImage(String url) {
    final lower = url.toLowerCase();
    final path = lower.split('?').first;
    return path.endsWith('.jpg') ||
        path.endsWith('.jpeg') ||
        path.endsWith('.png') ||
        path.endsWith('.gif') ||
        path.endsWith('.webp') ||
        lower.contains('i.redd.it');
  }
}
