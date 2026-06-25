import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goodreddit/core/bloc/safe_cubit.dart';
import 'package:goodreddit/core/error/failures.dart';
import 'package:goodreddit/features/interactions/presentation/bloc/interactions_cubit.dart';
import 'package:goodreddit/features/reader/domain/entities/feed_source.dart';
import 'package:goodreddit/features/reader/domain/usecases/get_feed.dart';
import 'package:goodreddit/features/scraper/domain/entities/post.dart';

part 'feed_state.dart';

class FeedCubit extends Cubit<FeedState> with SafeEmit<FeedState> {
  final GetFeed getFeed;

  /// Shared interaction store: each loaded page seeds vote/save baselines so the
  /// post cards' [VoteControls] render live from the first frame.
  final InteractionsCubit interactions;

  // Monotonic generation: each load captures it before awaiting and drops its
  // result if a newer load (or close) superseded it. Cheap logical cancellation
  // over the non-cancelable in-WebView fetch.
  int _gen = 0;

  FeedCubit({required this.getFeed, required this.interactions})
    : super(const FeedState());

  Future<void> load({FeedSource? source}) async {
    final src = source ?? state.source;
    final gen = ++_gen;
    safeEmit(
      state.copyWith(
        status: FeedStatus.loading,
        source: src,
        loadingMore: false,
        errorMessage: null,
        needsAuth: false,
      ),
    );
    final result = await getFeed(FeedParams(source: src));
    if (gen != _gen || isClosed) return;
    result.fold(
      (f) => safeEmit(
        state.copyWith(
          status: FeedStatus.error,
          errorMessage: f.message,
          needsAuth: f is NotAuthenticatedFailure,
        ),
      ),
      (page) {
        interactions.seedPosts(page.posts);
        safeEmit(
          state.copyWith(
            status: FeedStatus.loaded,
            posts: page.posts,
            after: page.after,
            hasMore: page.hasMore,
          ),
        );
      },
    );
  }

  Future<void> refresh() => load();

  void setSource(FeedSource source) {
    if (source == state.source && state.status != FeedStatus.error) return;
    load(source: source);
  }

  Future<void> loadMore() async {
    if (state.loadingMore ||
        !state.hasMore ||
        state.status != FeedStatus.loaded) {
      return;
    }
    final gen = _gen; // not bumped: a refresh/setSource supersedes us
    safeEmit(state.copyWith(loadingMore: true));
    final result = await getFeed(
      FeedParams(source: state.source, after: state.after),
    );
    if (gen != _gen || isClosed) return;
    result.fold(
      (_) => safeEmit(state.copyWith(loadingMore: false)),
      (page) {
        interactions.seedPosts(page.posts);
        safeEmit(
          state.copyWith(
            posts: [...state.posts, ...page.posts],
            after: page.after,
            hasMore: page.hasMore,
            loadingMore: false,
          ),
        );
      },
    );
  }

  @override
  Future<void> close() {
    _gen++; // invalidate any in-flight load
    return super.close();
  }
}
