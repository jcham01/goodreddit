import 'package:equatable/equatable.dart';
import 'package:goodreddit/features/search/domain/entities/subreddit.dart';

/// A subreddit together with its composite relevance score for a given query.
class SubredditScore extends Equatable {
  final Subreddit subreddit;
  final double activityScore;
  final double subscriberScore;
  final double relevanceScore;
  final double semanticScore;
  final double totalScore;
  final String? llmReasoning;

  const SubredditScore({
    required this.subreddit,
    required this.activityScore,
    required this.subscriberScore,
    required this.relevanceScore,
    this.semanticScore = 0.0,
    required this.totalScore,
    this.llmReasoning,
  });

  @override
  List<Object?> get props => [
        subreddit,
        activityScore,
        subscriberScore,
        relevanceScore,
        semanticScore,
        totalScore,
        llmReasoning,
      ];
}
