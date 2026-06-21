import 'package:equatable/equatable.dart';
import 'package:goodreddit/features/search/domain/entities/subreddit_score.dart';

enum LlmRankingStatus { notConfigured, applied, failed }

class SearchRankingResult extends Equatable {
  final List<SubredditScore> scores;
  final LlmRankingStatus llmStatus;
  final String? modelUsed;
  final String? llmErrorMessage;

  const SearchRankingResult({
    required this.scores,
    required this.llmStatus,
    this.modelUsed,
    this.llmErrorMessage,
  });

  const SearchRankingResult.empty()
    : scores = const [],
      llmStatus = LlmRankingStatus.notConfigured,
      modelUsed = null,
      llmErrorMessage = null;

  bool get usedLlm => llmStatus == LlmRankingStatus.applied;

  @override
  List<Object?> get props => [scores, llmStatus, modelUsed, llmErrorMessage];
}
