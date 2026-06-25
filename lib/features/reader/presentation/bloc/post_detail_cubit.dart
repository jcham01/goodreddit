import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goodreddit/core/bloc/safe_cubit.dart';
import 'package:goodreddit/core/error/failures.dart';
import 'package:goodreddit/features/interactions/presentation/bloc/interactions_cubit.dart';
import 'package:goodreddit/features/reader/domain/entities/comment_sort.dart';
import 'package:goodreddit/features/reader/domain/entities/post_detail.dart';
import 'package:goodreddit/features/reader/domain/usecases/get_post_detail.dart';
import 'package:goodreddit/features/scraper/domain/entities/post.dart';

part 'post_detail_state.dart';

/// Loads a single post + its comment thread. Seeded with the feed [Post] so the
/// header renders instantly while comments stream in.
class PostDetailCubit extends Cubit<PostDetailState>
    with SafeEmit<PostDetailState> {
  final GetPostDetail getPostDetail;

  /// Shared store: seed the header's [VoteControls] from frame zero, then
  /// reconcile its baseline with the authoritative detail load.
  final InteractionsCubit interactions;

  // Same logical-cancellation token as FeedCubit: a re-sort or close supersedes
  // an in-flight load over the non-cancelable in-WebView fetch.
  int _gen = 0;

  PostDetailCubit({
    required this.getPostDetail,
    required this.interactions,
    required Post seed,
  }) : super(PostDetailState(seedPost: seed)) {
    interactions.seedPost(seed);
  }

  Future<void> load() async {
    final gen = ++_gen;
    safeEmit(
      state.copyWith(
        status: PostDetailStatus.loading,
        errorMessage: null,
        needsAuth: false,
      ),
    );
    final result = await getPostDetail(
      PostDetailParams(
        subreddit: state.seedPost.subreddit,
        postId: state.seedPost.id,
        sort: state.sort,
      ),
    );
    if (gen != _gen || isClosed) return;
    result.fold(
      (f) => safeEmit(
        state.copyWith(
          status: PostDetailStatus.error,
          errorMessage: f.message,
          needsAuth: f is NotAuthenticatedFailure,
          // A failed re-sort keeps the old comments on screen; revert the menu
          // so it matches what is actually shown.
          sort: state.loadedSort,
        ),
      ),
      (detail) {
        interactions.reconcileBaseline(detail.post);
        safeEmit(
          state.copyWith(
            status: PostDetailStatus.loaded,
            detail: detail,
            loadedSort: state.sort,
          ),
        );
      },
    );
  }

  Future<void> refresh() => load();

  void setSort(CommentSort sort) {
    if (sort == state.sort) return;
    safeEmit(state.copyWith(sort: sort));
    load();
  }

  @override
  Future<void> close() {
    _gen++; // invalidate any in-flight load
    return super.close();
  }
}
