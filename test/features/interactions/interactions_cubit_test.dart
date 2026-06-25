import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goodreddit/core/error/failures.dart';
import 'package:goodreddit/core/util/vote_math.dart';
import 'package:goodreddit/features/interactions/domain/repositories/interactions_repository.dart';
import 'package:goodreddit/features/interactions/domain/usecases/cast_vote.dart';
import 'package:goodreddit/features/interactions/domain/usecases/set_saved.dart';
import 'package:goodreddit/features/interactions/domain/usecases/set_subscribed.dart';
import 'package:goodreddit/features/interactions/presentation/bloc/interactions_cubit.dart';
import 'package:goodreddit/features/reader/domain/entities/subreddit_about.dart';
import 'package:goodreddit/features/scraper/domain/entities/post.dart';

Post _post(String id, {int score = 10, bool? likes, bool saved = false}) => Post(
  id: id,
  name: 't3_$id',
  title: 't',
  selfText: '',
  author: 'u',
  score: score,
  numComments: 0,
  url: '',
  permalink: '/p',
  createdAt: DateTime(2020),
  likes: likes,
  saved: saved,
);

void main() {
  late _FakeRepo repo;
  late InteractionsCubit cubit;

  setUp(() {
    repo = _FakeRepo();
    cubit = InteractionsCubit(
      castVote: CastVote(repo),
      setSaved: SetSaved(repo),
      setSubscribed: SetSubscribed(repo),
    );
  });

  tearDown(() => cubit.close());

  test('toggleVote emits the optimistic overlay, then settles on success', () async {
    cubit.seedPost(_post('a', score: 10));
    final future = cubit.toggleVote('t3_a', VoteDir.up);
    final mid = cubit.state.postFor('t3_a')!;
    expect(mid.voteDir, VoteDir.up);
    expect(mid.displayScore, 11);
    expect(mid.pending, isTrue);

    repo.completeAction(const Right(unit));
    await future;
    final done = cubit.state.postFor('t3_a')!;
    expect(done.pending, isFalse);
    expect(done.voteDir, VoteDir.up);
    expect(done.displayScore, 11);
  });

  test('toggleVote rolls the overlay back on failure', () async {
    cubit.seedPost(_post('a', score: 10));
    final future = cubit.toggleVote('t3_a', VoteDir.up);
    repo.completeAction(const Left(RedditFailure('nope')));
    await future;
    final pi = cubit.state.postFor('t3_a')!;
    expect(pi.voteDir, VoteDir.none);
    expect(pi.displayScore, 10);
    expect(pi.pending, isFalse);
  });

  test('tapping up twice clears the vote', () async {
    repo.autoComplete = const Right(unit);
    cubit.seedPost(_post('a', score: 10));
    await cubit.toggleVote('t3_a', VoteDir.up);
    expect(cubit.state.postFor('t3_a')!.voteDir, VoteDir.up);
    await cubit.toggleVote('t3_a', VoteDir.up);
    expect(cubit.state.postFor('t3_a')!.voteDir, VoteDir.none);
    expect(cubit.state.postFor('t3_a')!.displayScore, 10);
  });

  test('toggleSaved is optimistic and rolls back on failure', () async {
    cubit.seedPost(_post('a', saved: false));
    final future = cubit.toggleSaved('t3_a');
    expect(cubit.state.postFor('t3_a')!.saved, isTrue);
    expect(cubit.state.postFor('t3_a')!.pending, isTrue);
    repo.completeAction(const Left(RedditFailure('nope')));
    await future;
    expect(cubit.state.postFor('t3_a')!.saved, isFalse);
    expect(cubit.state.postFor('t3_a')!.pending, isFalse);
  });

  test('an in-flight save and vote on the same post settle independently', () async {
    cubit.seedPost(_post('a', score: 10));
    final fVote = cubit.toggleVote('t3_a', VoteDir.up); // token vote:…
    final fSave = cubit.toggleSaved('t3_a'); // token save:… (distinct)
    expect(cubit.state.postFor('t3_a')!.voteDir, VoteDir.up);
    expect(cubit.state.postFor('t3_a')!.saved, isTrue);

    // Resolve the save first; the vote must NOT be dropped or clobbered.
    repo.completeActionAt(1, const Right(unit));
    await fSave;
    expect(cubit.state.postFor('t3_a')!.saved, isTrue);
    expect(cubit.state.postFor('t3_a')!.voteDir, VoteDir.up); // still optimistic

    // Now fail the vote → only the vote field rolls back, save stays.
    repo.completeActionAt(0, const Left(RedditFailure('nope')));
    await fVote;
    expect(cubit.state.postFor('t3_a')!.voteDir, VoteDir.none);
    expect(cubit.state.postFor('t3_a')!.saved, isTrue); // untouched by vote rollback
  });

  test('re-seeding the same fullname never double-counts an applied vote', () async {
    repo.autoComplete = const Right(unit);
    cubit.seedPost(_post('a', score: 10));
    await cubit.toggleVote('t3_a', VoteDir.up); // display 11
    cubit.seedPost(_post('a', score: 50)); // another list, same post
    expect(cubit.state.postFor('t3_a')!.displayScore, 11); // NOT 51
  });

  test('reconcileBaseline upgrades when safe, ignored while a write is pending', () async {
    cubit.seedPost(_post('a', score: 10));
    cubit.reconcileBaseline(_post('a', score: 50)); // no overlay → upgrades
    expect(cubit.state.postFor('t3_a')!.displayScore, 50);

    final f = cubit.toggleVote('t3_a', VoteDir.up); // optimistic 51, pending
    cubit.reconcileBaseline(_post('a', score: 999)); // ignored — pending
    expect(cubit.state.postFor('t3_a')!.displayScore, 51);
    repo.completeAction(const Right(unit));
    await f;
  });

  test('after a settled vote, an authoritative reconcile refreshes the score', () async {
    repo.autoComplete = const Right(unit);
    cubit.seedPost(_post('a', score: 10));
    await cubit.toggleVote('t3_a', VoteDir.up); // settled → baseline folded
    expect(cubit.state.postFor('t3_a')!.diverges, isFalse);
    expect(cubit.state.postFor('t3_a')!.displayScore, 11);
    // A fresh authenticated detail load (likes:true reflects the user's vote).
    cubit.reconcileBaseline(_post('a', score: 80, likes: true));
    expect(cubit.state.postFor('t3_a')!.displayScore, 80);
  });

  test('double-tap supersede: only the latest result is applied', () async {
    cubit.seedPost(_post('a', score: 10));
    final f1 = cubit.toggleVote('t3_a', VoteDir.up);
    final f2 = cubit.toggleVote('t3_a', VoteDir.down);
    expect(cubit.state.postFor('t3_a')!.voteDir, VoteDir.down);

    // The stale first result must NOT clobber the newer overlay.
    repo.completeActionAt(0, const Left(RedditFailure('stale')));
    await f1;
    expect(cubit.state.postFor('t3_a')!.voteDir, VoteDir.down);

    repo.completeActionAt(1, const Right(unit));
    await f2;
    expect(cubit.state.postFor('t3_a')!.voteDir, VoteDir.down);
    expect(cubit.state.postFor('t3_a')!.pending, isFalse);
    expect(repo.actionCalls, 2);
  });

  test('toggleSubscribed flips the overlay + member delta, rolls back', () async {
    cubit.seedSub(
      const SubredditAbout(
        name: 'Flutter',
        subscribers: 100,
        userIsSubscriber: false,
        fullname: 't5_x',
      ),
    );
    final future = cubit.toggleSubscribed('flutter'); // case-insensitive key
    final mid = cubit.state.subFor('flutter')!;
    expect(mid.subscribed, isTrue);
    expect(mid.displaySubscribers, 101);
    expect(mid.pending, isTrue);

    repo.completeAction(const Left(RedditFailure('nope')));
    await future;
    final after = cubit.state.subFor('FLUTTER')!;
    expect(after.subscribed, isFalse);
    expect(after.displaySubscribers, 100);
    expect(after.pending, isFalse);
  });

  test('clear empties both maps', () async {
    cubit.seedPost(_post('a'));
    cubit.seedSub(const SubredditAbout(name: 'x', subscribers: 5));
    cubit.clear();
    expect(cubit.state.posts, isEmpty);
    expect(cubit.state.subs, isEmpty);
  });
}

/// Hand-written, Completer-driven fake matching the project's test idiom.
class _FakeRepo implements InteractionsRepository {
  Either<Failure, Unit>? autoComplete;
  final List<Completer<Either<Failure, Unit>>> _completers = [];
  int actionCalls = 0;

  void completeAction(Either<Failure, Unit> r) => _completers.last.complete(r);
  void completeActionAt(int i, Either<Failure, Unit> r) =>
      _completers[i].complete(r);

  Future<Either<Failure, Unit>> _run() {
    actionCalls++;
    final auto = autoComplete;
    if (auto != null) return Future.value(auto);
    final c = Completer<Either<Failure, Unit>>();
    _completers.add(c);
    return c.future;
  }

  @override
  Future<Either<Failure, Unit>> vote({
    required String fullname,
    required VoteDir dir,
  }) => _run();

  @override
  Future<Either<Failure, Unit>> setSaved({
    required String fullname,
    required bool saved,
  }) => _run();

  @override
  Future<Either<Failure, Unit>> setSubscribed({
    required String srName,
    String? fullname,
    required bool subscribe,
  }) => _run();
}
