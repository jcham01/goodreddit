import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goodreddit/core/bloc/safe_cubit.dart';
import 'package:goodreddit/core/error/failures.dart';
import 'package:goodreddit/features/reader/domain/entities/subreddit_about.dart';
import 'package:goodreddit/features/reader/domain/entities/subreddit_sort.dart';
import 'package:goodreddit/features/reader/domain/usecases/get_subreddit_about.dart';
import 'package:goodreddit/features/reader/domain/usecases/get_subreddit_feed.dart';
import 'package:goodreddit/features/scraper/domain/entities/post.dart';

part 'subreddit_state.dart';

/// Loads one subreddit: its "about" header (best-effort) and a paginated,
/// sortable listing. Generation-counter cancellation mirrors FeedCubit.
class SubredditCubit extends Cubit<SubredditState> with SafeEmit<SubredditState> {
  final GetSubredditFeed getFeed;
  final GetSubredditAbout getAbout;

  int _gen = 0;
  bool _aboutInFlight = false;

  SubredditCubit({
    required this.getFeed,
    required this.getAbout,
    required String name,
  }) : super(SubredditState(name: name));

  Future<void> load() async {
    _ensureAbout();
    await _loadFeed();
  }

  Future<void> refresh() => load();

  void setSort(SubredditSort sort) {
    if (sort == state.sort && state.status != SubredditStatus.error) return;
    _loadFeed(sort: sort);
  }

  Future<void> loadMore() async {
    if (state.loadingMore ||
        !state.hasMore ||
        state.status != SubredditStatus.loaded) {
      return;
    }
    final gen = _gen; // not bumped: a refresh/setSort supersedes us
    safeEmit(state.copyWith(loadingMore: true));
    final result = await getFeed(
      SubredditFeedParams(
        subreddit: state.name,
        sort: state.sort,
        after: state.after,
      ),
    );
    if (gen != _gen || isClosed) return;
    result.fold(
      (_) => safeEmit(state.copyWith(loadingMore: false)),
      (page) => safeEmit(
        state.copyWith(
          posts: [...state.posts, ...page.posts],
          after: page.after,
          hasMore: page.hasMore,
          loadingMore: false,
        ),
      ),
    );
  }

  /// Fetches the about header at most once: it is static and sort-independent,
  /// so a re-sort or pull-to-refresh must not refetch it, and the in-flight
  /// guard prevents two concurrent fetches racing to last-writer-wins.
  Future<void> _ensureAbout() async {
    if (state.about != null || _aboutInFlight) return;
    _aboutInFlight = true;
    final result = await getAbout(state.name);
    _aboutInFlight = false;
    if (isClosed) return;
    result.fold(
      (_) {}, // header is best-effort; the listing carries the real error
      (about) => safeEmit(state.copyWith(about: about)),
    );
  }

  Future<void> _loadFeed({SubredditSort? sort}) async {
    final s = sort ?? state.sort;
    final gen = ++_gen;
    safeEmit(
      state.copyWith(
        status: SubredditStatus.loading,
        sort: s,
        loadingMore: false,
        errorMessage: null,
        needsAuth: false,
      ),
    );
    final result = await getFeed(
      SubredditFeedParams(subreddit: state.name, sort: s),
    );
    if (gen != _gen || isClosed) return;
    result.fold(
      (f) => safeEmit(
        state.copyWith(
          status: SubredditStatus.error,
          errorMessage: f.message,
          needsAuth: f is NotAuthenticatedFailure,
        ),
      ),
      (page) => safeEmit(
        state.copyWith(
          status: SubredditStatus.loaded,
          posts: page.posts,
          after: page.after,
          hasMore: page.hasMore,
        ),
      ),
    );
  }

  @override
  Future<void> close() {
    _gen++;
    return super.close();
  }
}
