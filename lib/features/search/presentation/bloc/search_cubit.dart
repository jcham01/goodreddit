import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goodreddit/core/error/failures.dart';
import 'package:goodreddit/features/history/domain/entities/research_session.dart';
import 'package:goodreddit/features/history/domain/usecases/save_session.dart';
import 'package:goodreddit/features/search/domain/entities/subreddit_score.dart';
import 'package:goodreddit/features/search/domain/usecases/search_and_rank_subreddits.dart';
import 'package:uuid/uuid.dart';

part 'search_state.dart';

class SearchCubit extends Cubit<SearchState> {
  final SearchAndRankSubreddits searchAndRank;
  final SaveSession saveSession;
  final Uuid uuid;

  SearchCubit({
    required this.searchAndRank,
    required this.saveSession,
    Uuid? uuid,
  })  : uuid = uuid ?? const Uuid(),
        super(const SearchState());

  Future<void> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    emit(state.copyWith(status: SearchStatus.loading, query: trimmed));

    final result = await searchAndRank(SearchParams(trimmed));
    await result.fold(
      (failure) async => emit(state.copyWith(
        status: SearchStatus.error,
        errorMessage: failure.message,
        needsAuth: failure is NotAuthenticatedFailure,
      )),
      (scores) async {
        emit(state.copyWith(
          status: scores.isEmpty ? SearchStatus.empty : SearchStatus.loaded,
          results: scores,
        ));
        if (scores.isNotEmpty) {
          await _persist(trimmed, scores);
        }
      },
    );
  }

  Future<void> _persist(String query, List<SubredditScore> scores) async {
    final now = DateTime.now();
    // Persistence is best-effort: never surface a storage error over results.
    await saveSession(ResearchSession(
      id: uuid.v4(),
      query: query,
      rankedResults: scores,
      createdAt: now,
      updatedAt: now,
    ));
  }

  void reset() => emit(const SearchState());
}
