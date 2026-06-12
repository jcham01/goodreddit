part of 'scraper_cubit.dart';

enum ScraperStatus { initial, loading, loaded, error }

class ScraperState extends Equatable {
  final ScraperStatus status;
  final List<Post> posts;
  final List<Comment> comments;
  final String? errorMessage;
  final bool needsAuth;

  const ScraperState({
    this.status = ScraperStatus.initial,
    this.posts = const [],
    this.comments = const [],
    this.errorMessage,
    this.needsAuth = false,
  });

  ScraperState copyWith({
    ScraperStatus? status,
    List<Post>? posts,
    List<Comment>? comments,
    String? errorMessage,
    bool? needsAuth,
  }) {
    return ScraperState(
      status: status ?? this.status,
      posts: posts ?? this.posts,
      comments: comments ?? this.comments,
      errorMessage: errorMessage,
      needsAuth: needsAuth ?? false,
    );
  }

  @override
  List<Object?> get props => [status, posts, comments, errorMessage, needsAuth];
}
