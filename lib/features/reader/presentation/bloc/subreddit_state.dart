part of 'subreddit_cubit.dart';

enum SubredditStatus { initial, loading, loaded, error }

const Object _unset = Object();

class SubredditState extends Equatable {
  final String name;
  final SubredditSort sort;
  final SubredditAbout? about;
  final SubredditStatus status;
  final List<Post> posts;
  final String? after;
  final bool hasMore;
  final bool loadingMore;
  final String? errorMessage;
  final bool needsAuth;

  const SubredditState({
    required this.name,
    this.sort = SubredditSort.hot,
    this.about,
    this.status = SubredditStatus.initial,
    this.posts = const [],
    this.after,
    this.hasMore = false,
    this.loadingMore = false,
    this.errorMessage,
    this.needsAuth = false,
  });

  SubredditState copyWith({
    String? name,
    SubredditSort? sort,
    SubredditAbout? about,
    SubredditStatus? status,
    List<Post>? posts,
    Object? after = _unset,
    bool? hasMore,
    bool? loadingMore,
    Object? errorMessage = _unset,
    bool? needsAuth,
  }) {
    return SubredditState(
      name: name ?? this.name,
      sort: sort ?? this.sort,
      about: about ?? this.about,
      status: status ?? this.status,
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
    name,
    sort,
    about,
    status,
    posts,
    after,
    hasMore,
    loadingMore,
    errorMessage,
    needsAuth,
  ];
}
