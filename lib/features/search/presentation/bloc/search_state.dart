part of 'search_cubit.dart';

enum SearchStatus { initial, loading, loaded, empty, error }

class SearchState extends Equatable {
  final SearchStatus status;
  final String query;
  final List<SubredditScore> results;
  final String? errorMessage;
  final bool needsAuth;

  const SearchState({
    this.status = SearchStatus.initial,
    this.query = '',
    this.results = const [],
    this.errorMessage,
    this.needsAuth = false,
  });

  SearchState copyWith({
    SearchStatus? status,
    String? query,
    List<SubredditScore>? results,
    String? errorMessage,
    bool? needsAuth,
  }) {
    return SearchState(
      status: status ?? this.status,
      query: query ?? this.query,
      results: results ?? this.results,
      errorMessage: errorMessage,
      needsAuth: needsAuth ?? false,
    );
  }

  @override
  List<Object?> get props => [status, query, results, errorMessage, needsAuth];
}
