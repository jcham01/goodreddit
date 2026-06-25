import 'package:equatable/equatable.dart';
import 'package:goodreddit/features/reader/domain/entities/post_media.dart';
import 'package:goodreddit/features/reader/domain/entities/thread_item.dart';
import 'package:goodreddit/features/scraper/domain/entities/post.dart';

/// A fully-loaded post: the authoritative post (full self-text/media), its
/// resolved media block, and a depth-flattened comment thread.
class PostDetail extends Equatable {
  final Post post;
  final PostMedia media;
  final List<ThreadItem> thread;

  const PostDetail({
    required this.post,
    required this.media,
    required this.thread,
  });

  /// Real comments in the thread (excludes "load more" markers).
  int get commentCount => thread.whereType<CommentNode>().length;

  @override
  List<Object?> get props => [post, media, thread];
}
