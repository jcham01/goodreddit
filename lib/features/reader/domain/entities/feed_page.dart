import 'package:equatable/equatable.dart';
import 'package:goodreddit/features/scraper/domain/entities/post.dart';

/// One page of a paginated feed: the posts plus Reddit's opaque `after` cursor
/// for fetching the next page (null when there are no more).
class FeedPage extends Equatable {
  final List<Post> posts;
  final String? after;

  const FeedPage({required this.posts, this.after});

  bool get hasMore => after != null && after!.isNotEmpty;

  @override
  List<Object?> get props => [posts, after];
}
