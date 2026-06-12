part of 'search_cubit.dart';

enum SearchStatus { initial, loading, loaded, empty, error }

class SearchState extends Equatable {
  final SearchStatus status;
  final String query;
  final List<SubredditScore> results;

  /// Model id used for the LLM ranking of [results]; null when no LLM is
  /// configured (heuristic ranking only).
  final String? modelUsed;
  final String? errorMessage;
  final bool needsAuth;

  const SearchState({
    this.status = SearchStatus.initial,
    this.query = '',
    this.results = const [],
    this.modelUsed,
    this.errorMessage,
    this.needsAuth = false,
  });

  SearchState copyWith({
    SearchStatus? status,
    String? query,
    List<SubredditScore>? results,
    String? modelUsed,
    String? errorMessage,
    bool? needsAuth,
  }) {
    return SearchState(
      status: status ?? this.status,
      query: query ?? this.query,
      results: results ?? this.results,
      modelUsed: modelUsed ?? this.modelUsed,
      errorMessage: errorMessage,
      needsAuth: needsAuth ?? false,
    );
  }

  @override
  List<Object?> get props => [
    status,
    query,
    results,
    modelUsed,
    errorMessage,
    needsAuth,
  ];
}
