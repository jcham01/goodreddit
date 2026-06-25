import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goodreddit/core/error/failures.dart';
import 'package:goodreddit/core/util/vote_math.dart';
import 'package:goodreddit/features/auth/domain/entities/reddit_session.dart';
import 'package:goodreddit/features/auth/domain/repositories/auth_repository.dart';
import 'package:goodreddit/features/auth/domain/usecases/get_auth_status.dart';
import 'package:goodreddit/features/auth/domain/usecases/logout.dart';
import 'package:goodreddit/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:goodreddit/features/interactions/domain/repositories/interactions_repository.dart';
import 'package:goodreddit/features/interactions/domain/usecases/cast_vote.dart';
import 'package:goodreddit/features/interactions/domain/usecases/set_saved.dart';
import 'package:goodreddit/features/interactions/domain/usecases/set_subscribed.dart';
import 'package:goodreddit/features/interactions/presentation/bloc/interactions_cubit.dart';
import 'package:goodreddit/features/interactions/presentation/widgets/vote_controls.dart';
import 'package:goodreddit/features/scraper/domain/entities/post.dart';

Post _post(String id, {int score = 10}) => Post(
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
);

void main() {
  testWidgets(
    'two VoteControls with the same fullname stay in sync (cross-screen)',
    (tester) async {
      final intRepo = _OkInteractionsRepository();
      final store = InteractionsCubit(
        castVote: CastVote(intRepo),
        setSaved: SetSaved(intRepo),
        setSubscribed: SetSubscribed(intRepo),
      );
      store.seedPost(_post('a', score: 10));

      final auth = AuthCubit(
        getAuthStatus: GetAuthStatus(_AuthedRepo()),
        logout: Logout(_AuthedRepo()),
        interactions: store,
      );
      await auth.refresh(); // → authenticated

      await tester.pumpWidget(
        MaterialApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider<InteractionsCubit>.value(value: store),
              BlocProvider<AuthCubit>.value(value: auth),
            ],
            child: Scaffold(
              body: Column(
                children: [
                  VoteControls(fullname: 't3_a', baseScore: 10, onNeedsAuth: () {}),
                  VoteControls(fullname: 't3_a', baseScore: 10, onNeedsAuth: () {}),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('10'), findsNWidgets(2));

      await tester.tap(find.byTooltip('Voter pour').first);
      await tester.pumpAndSettle();

      // Both controls — though only one was tapped — reflect the new score.
      expect(find.text('11'), findsNWidgets(2));
      expect(find.text('10'), findsNothing);
    },
  );

  testWidgets('an anonymous tap calls onNeedsAuth and does not vote', (
    tester,
  ) async {
    final intRepo = _OkInteractionsRepository();
    final store = InteractionsCubit(
      castVote: CastVote(intRepo),
      setSaved: SetSaved(intRepo),
      setSubscribed: SetSubscribed(intRepo),
    );
    store.seedPost(_post('a', score: 10));

    final auth = AuthCubit(
      getAuthStatus: GetAuthStatus(_AnonRepo()),
      logout: Logout(_AnonRepo()),
      interactions: store,
    );
    await auth.refresh(); // → anonymous

    var prompted = false;
    await tester.pumpWidget(
      MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider<InteractionsCubit>.value(value: store),
            BlocProvider<AuthCubit>.value(value: auth),
          ],
          child: Scaffold(
            body: VoteControls(
              fullname: 't3_a',
              baseScore: 10,
              onNeedsAuth: () => prompted = true,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Voter pour'));
    await tester.pumpAndSettle();

    expect(prompted, isTrue);
    expect(store.state.postFor('t3_a')!.voteDir, VoteDir.none); // unchanged
  });
}

class _OkInteractionsRepository implements InteractionsRepository {
  @override
  Future<Either<Failure, Unit>> vote({
    required String fullname,
    required VoteDir dir,
  }) async => const Right(unit);

  @override
  Future<Either<Failure, Unit>> setSaved({
    required String fullname,
    required bool saved,
  }) async => const Right(unit);

  @override
  Future<Either<Failure, Unit>> setSubscribed({
    required String srName,
    String? fullname,
    required bool subscribe,
  }) async => const Right(unit);
}

class _AuthedRepo implements AuthRepository {
  @override
  Future<Either<Failure, RedditSession>> currentSession() async =>
      const Right(RedditSession(isAuthenticated: true, username: 'u'));

  @override
  Future<Either<Failure, Unit>> logout() async => const Right(unit);
}

class _AnonRepo implements AuthRepository {
  @override
  Future<Either<Failure, RedditSession>> currentSession() async =>
      const Right(RedditSession.anonymous());

  @override
  Future<Either<Failure, Unit>> logout() async => const Right(unit);
}
