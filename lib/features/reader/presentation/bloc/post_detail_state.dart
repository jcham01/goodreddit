part of 'post_detail_cubit.dart';

enum PostDetailStatus { initial, loading, loaded, error }

const Object _unset = Object();

class PostDetailState extends Equatable {
  final PostDetailStatus status;

  /// The feed post, shown in the header before the full detail arrives.
  final Post seedPost;

  /// Full detail (authoritative post + media + thread) once loaded.
  final PostDetail? detail;

  /// Sort the user has selected (may be ahead of [detail] mid-load).
  final CommentSort sort;

  /// Sort that actually produced the comments in [detail]. Used to revert the
  /// menu if a re-sort fails, keeping it consistent with the shown comments.
  final CommentSort loadedSort;

  final String? errorMessage;
  final bool needsAuth;

  const PostDetailState({
    required this.seedPost,
    this.status = PostDetailStatus.initial,
    this.detail,
    this.sort = CommentSort.best,
    this.loadedSort = CommentSort.best,
    this.errorMessage,
    this.needsAuth = false,
  });

  /// Authoritative post when loaded, else the feed seed.
  Post get post => detail?.post ?? seedPost;

  PostDetailState copyWith({
    PostDetailStatus? status,
    Post? seedPost,
    PostDetail? detail,
    CommentSort? sort,
    CommentSort? loadedSort,
    Object? errorMessage = _unset,
    bool? needsAuth,
  }) {
    return PostDetailState(
      status: status ?? this.status,
      seedPost: seedPost ?? this.seedPost,
      detail: detail ?? this.detail,
      sort: sort ?? this.sort,
      loadedSort: loadedSort ?? this.loadedSort,
      errorMessage: errorMessage == _unset
          ? this.errorMessage
          : errorMessage as String?,
      needsAuth: needsAuth ?? this.needsAuth,
    );
  }

  @override
  List<Object?> get props => [
    status,
    seedPost,
    detail,
    sort,
    loadedSort,
    errorMessage,
    needsAuth,
  ];
}
