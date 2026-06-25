import 'package:equatable/equatable.dart';

/// What kind of media a post carries, resolved from the raw listing.
enum MediaKind { none, image, gallery, link, video }

/// A single displayable image with its intrinsic size when known.
class MediaImage extends Equatable {
  final String url;
  final int? width;
  final int? height;

  const MediaImage({required this.url, this.width, this.height});

  double? get aspectRatio =>
      (width != null && height != null && height! > 0)
      ? width! / height!
      : null;

  @override
  List<Object?> get props => [url, width, height];
}

/// The media block shown above the post body. Resolved once, in the data layer,
/// so the UI never inspects raw Reddit JSON.
class PostMedia extends Equatable {
  final MediaKind kind;
  final List<MediaImage> images; // image / gallery
  final String? externalUrl; // link / video target (opened externally)
  final String? previewUrl; // still image used as a video poster / link thumb

  const PostMedia({
    this.kind = MediaKind.none,
    this.images = const [],
    this.externalUrl,
    this.previewUrl,
  });

  static const PostMedia none = PostMedia();

  bool get hasImages => images.isNotEmpty;
  bool get isGallery => kind == MediaKind.gallery;

  @override
  List<Object?> get props => [kind, images, externalUrl, previewUrl];
}
