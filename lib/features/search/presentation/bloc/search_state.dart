part of 'search_cubit.dart';

enum SearchStatus { initial, loading, loaded, empty, error }

const _unset = Object();

class SearchState extends Equatable {
  final SearchStatus status;
  final String query;
  final List<SubredditScore> results;

  /// Truthful source information for the current ranking. [modelUsed] is set
  /// only when an LLM call was actually attempted for this result set.
  final LlmRankingStatus llmStatus;
  final String? modelUsed;
  final String? llmErrorMessage;
  final String? errorMessage;
  final bool needsAuth;

  const SearchState({
    this.status = SearchStatus.initial,
    this.query = '',
    this.results = const [],
    this.llmStatus = LlmRankingStatus.notConfigured,
    this.modelUsed,
    this.llmErrorMessage,
    this.errorMessage,
    this.needsAuth = false,
  });

  SearchState copyWith({
    SearchStatus? status,
    String? query,
    List<SubredditScore>? results,
    LlmRankingStatus? llmStatus,
    Object? modelUsed = _unset,
    Object? llmErrorMessage = _unset,
    String? errorMessage,
    bool? needsAuth,
  }) {
    return SearchState(
      status: status ?? this.status,
      query: query ?? this.query,
      results: results ?? this.results,
      llmStatus: llmStatus ?? this.llmStatus,
      modelUsed: modelUsed == _unset ? this.modelUsed : modelUsed as String?,
      llmErrorMessage: llmErrorMessage == _unset
          ? this.llmErrorMessage
          : llmErrorMessage as String?,
      errorMessage: errorMessage,
      needsAuth: needsAuth ?? false,
    );
  }

  @override
  List<Object?> get props => [
    status,
    query,
    results,
    llmStatus,
    modelUsed,
    llmErrorMessage,
    errorMessage,
    needsAuth,
  ];
}
