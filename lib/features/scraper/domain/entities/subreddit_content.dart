import 'package:equatable/equatable.dart';
import 'package:goodreddit/features/scraper/domain/entities/comment.dart';
import 'package:goodreddit/features/scraper/domain/entities/post.dart';

/// The scraped material for a subreddit: its top posts plus the comments from
/// the most popular of those posts.
class SubredditContent extends Equatable {
  final List<Post> posts;
  final List<Comment> comments;

  const SubredditContent({required this.posts, required this.comments});

  @override
  List<Object?> get props => [posts, comments];
}
