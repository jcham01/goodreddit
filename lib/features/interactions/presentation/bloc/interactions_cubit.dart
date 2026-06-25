import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goodreddit/core/bloc/safe_cubit.dart';
import 'package:goodreddit/core/util/vote_math.dart';
import 'package:goodreddit/features/interactions/domain/entities/post_interaction.dart';
import 'package:goodreddit/features/interactions/domain/entities/sub_interaction.dart';
import 'package:goodreddit/features/interactions/domain/usecases/cast_vote.dart';
import 'package:goodreddit/features/interactions/domain/usecases/set_saved.dart';
import 'package:goodreddit/features/interactions/domain/usecases/set_subscribed.dart';
import 'package:goodreddit/features/reader/domain/entities/subreddit_about.dart';
import 'package:goodreddit/features/scraper/domain/entities/post.dart';

part 'interactions_state.dart';

/// App-wide source of truth for Reddit write actions (vote/save/subscribe).
///
/// One lazy-singleton, provided at the app root. The same post — shown in the
/// home feed, a subreddit listing, AND a pushed detail page at once — stays in
/// sync by construction: every surface reads this store through a per-key
/// [BlocSelector]. Writes apply an optimistic overlay then confirm or roll back.
/// The store is NEVER closed, so a write begun on a screen that is then popped
/// still settles correctly (no emit-after-close, no phantom vote).
class InteractionsCubit extends Cubit<InteractionsState>
    with SafeEmit<InteractionsState> {
  final CastVote castVote;
  final SetSaved setSaved;
  final SetSubscribed setSubscribed;

  /// Per-(field) supersede tokens. The singleton never closes and there is no
  /// global generation, so a stale async result is dropped by comparing the
  /// token captured before the await with the latest for that key. Vote, save,
  /// and subscribe use DISTINCT keys so an in-flight save and an in-flight vote
  /// on the same post never supersede one another.
  final Map<String, int> _tokens = {};

  InteractionsCubit({
    required this.castVote,
    required this.setSaved,
    required this.setSubscribed,
  }) : super(const InteractionsState());

  // ---- Seeding (called by the read cubits — never an emit-in-build) ----

  /// Inserts a baseline for [post] if absent. Idempotent: a later page load or
  /// the detail seed never clobbers an existing overlay (first baseline wins).
  void seedPost(Post post) {
    final key = post.fullname;
    if (state.posts.containsKey(key)) return;
    safeEmit(
      state.copyWith(posts: {...state.posts, key: PostInteraction.seed(post)}),
    );
  }

  void seedPosts(Iterable<Post> posts) {
    final next = {...state.posts};
    var changed = false;
    for (final p in posts) {
      final key = p.fullname;
      if (next.containsKey(key)) continue;
      next[key] = PostInteraction.seed(p);
      changed = true;
    }
    if (changed) safeEmit(state.copyWith(posts: next));
  }

  /// Refreshes the server baseline from a more authoritative load (the detail
  /// page) ONLY when there is no pending write and no divergent overlay, so it
  /// never drops a just-made or in-flight user action.
  void reconcileBaseline(Post post) {
    final key = post.fullname;
    final existing = state.posts[key];
    if (existing == null) {
      seedPost(post);
      return;
    }
    if (existing.pending || existing.diverges) return;
    final fresh = PostInteraction.seed(post);
    if (fresh == existing) return;
    safeEmit(state.copyWith(posts: {...state.posts, key: fresh}));
  }

  void seedSub(SubredditAbout about) {
    final key = about.name.toLowerCase();
    if (state.subs.containsKey(key)) return;
    safeEmit(
      state.copyWith(subs: {...state.subs, key: SubInteraction.seed(about)}),
    );
  }

  // ---- Writes (optimistic overlay + per-field rollback) ----

  Future<void> toggleVote(String fullname, VoteDir tapped) async {
    final prev = state.posts[fullname];
    if (prev == null) return; // a surface showing controls always seeds first
    final prevDir = prev.voteDir;
    final next = nextVote(prevDir, tapped);
    _putPost(fullname, prev.copyWith(voteDir: next, pending: true));

    final token = _bump('vote:$fullname');
    final res = await castVote(CastVoteParams(fullname: fullname, dir: next));
    if (isClosed || _tokens['vote:$fullname'] != token) return;
    res.fold(
      (_) => _rollbackVote(fullname, prevDir),
      (_) => _settleVote(fullname),
    );
  }

  Future<void> toggleSaved(String fullname) async {
    final prev = state.posts[fullname];
    if (prev == null) return;
    final prevSaved = prev.saved;
    final next = !prevSaved;
    _putPost(fullname, prev.copyWith(saved: next, pending: true));

    final token = _bump('save:$fullname');
    final res = await setSaved(SetSavedParams(fullname: fullname, saved: next));
    if (isClosed || _tokens['save:$fullname'] != token) return;
    res.fold(
      (_) => _rollbackSave(fullname, prevSaved),
      (_) => _settleSave(fullname),
    );
  }

  Future<void> toggleSubscribed(String srName) async {
    final key = srName.toLowerCase();
    final prev = state.subs[key];
    if (prev == null) return;
    final prevSubscribed = prev.subscribed;
    final next = !prevSubscribed;
    _putSub(key, prev.copyWith(subscribed: next, pending: true));

    final tokenKey = 'sub:$key';
    final token = _bump(tokenKey);
    final res = await setSubscribed(
      SetSubscribedParams(
        srName: prev.srName,
        fullname: prev.fullname,
        subscribe: next,
      ),
    );
    if (isClosed || _tokens[tokenKey] != token) return;
    res.fold(
      (_) => _rollbackSub(key, prevSubscribed),
      (_) => _settleSub(key),
    );
  }

  /// Wipes all interaction state — called on sign-out so a different account
  /// never inherits the previous user's votes/saves/subscriptions.
  void clear() {
    _tokens.clear();
    safeEmit(const InteractionsState());
  }

  // ---- helpers ----

  int _bump(String key) => _tokens[key] = (_tokens[key] ?? 0) + 1;

  void _putPost(String key, PostInteraction value) =>
      safeEmit(state.copyWith(posts: {...state.posts, key: value}));

  void _putSub(String key, SubInteraction value) =>
      safeEmit(state.copyWith(subs: {...state.subs, key: value}));

  /// Fold the confirmed vote into the baseline: the overlay IS the server state
  /// now, so absorbing it leaves [PostInteraction.displayScore] unchanged while
  /// clearing divergence (letting a later reconcile pick up server score drift).
  /// Only the vote fields are folded, so a concurrent in-flight save is intact.
  void _settleVote(String key) {
    final cur = state.posts[key];
    if (cur == null) return;
    _putPost(
      key,
      cur.copyWith(
        baseScore: cur.displayScore,
        baseDir: cur.voteDir,
        pending: false,
      ),
    );
  }

  void _rollbackVote(String key, VoteDir prevDir) {
    final cur = state.posts[key];
    if (cur == null) return;
    _putPost(key, cur.copyWith(voteDir: prevDir, pending: false));
  }

  void _settleSave(String key) {
    final cur = state.posts[key];
    if (cur == null) return;
    _putPost(key, cur.copyWith(baseSaved: cur.saved, pending: false));
  }

  void _rollbackSave(String key, bool prevSaved) {
    final cur = state.posts[key];
    if (cur == null) return;
    _putPost(key, cur.copyWith(saved: prevSaved, pending: false));
  }

  void _settleSub(String key) {
    final cur = state.subs[key];
    if (cur == null) return;
    _putSub(
      key,
      cur.copyWith(
        baseSubscribers: cur.displaySubscribers,
        baseSubscribed: cur.subscribed,
        pending: false,
      ),
    );
  }

  void _rollbackSub(String key, bool prevSubscribed) {
    final cur = state.subs[key];
    if (cur == null) return;
    _putSub(key, cur.copyWith(subscribed: prevSubscribed, pending: false));
  }
}
