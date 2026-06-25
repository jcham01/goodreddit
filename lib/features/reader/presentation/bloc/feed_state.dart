part of 'feed_cubit.dart';

enum FeedStatus { initial, loading, loaded, error }

const Object _unset = Object();

class FeedState extends Equatable {
  final FeedStatus status;
  final FeedSource source;
  final List<Post> posts;
  final String? after;
  final bool hasMore;
  final bool loadingMore;
  final String? errorMessage;
  final bool needsAuth;

  const FeedState({
    this.status = FeedStatus.initial,
    this.source = FeedSource.home,
    this.posts = const [],
    this.after,
    this.hasMore = false,
    this.loadingMore = false,
    this.errorMessage,
    this.needsAuth = false,
  });

  FeedState copyWith({
    FeedStatus? status,
    FeedSource? source,
    List<Post>? posts,
    Object? after = _unset,
    bool? hasMore,
    bool? loadingMore,
    Object? errorMessage = _unset,
    bool? needsAuth,
  }) {
    return FeedState(
      status: status ?? this.status,
      source: source ?? this.source,
      posts: posts ?? this.posts,
      after: after == _unset ? this.after : after as String?,
      hasMore: hasMore ?? this.hasMore,
      loadingMore: loadingMore ?? this.loadingMore,
      errorMessage: errorMessage == _unset
          ? this.errorMessage
          : errorMessage as String?,
      needsAuth: needsAuth ?? this.needsAuth,
    );
  }

  @override
  List<Object?> get props => [
    status,
    source,
    posts,
    after,
    hasMore,
    loadingMore,
    errorMessage,
    needsAuth,
  ];
}
