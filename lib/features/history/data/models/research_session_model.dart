import 'package:goodreddit/features/history/domain/entities/research_session.dart';
import 'package:goodreddit/features/search/data/models/subreddit_score_model.dart';
import 'package:goodreddit/features/search/domain/entities/subreddit_score.dart';

class ResearchSessionModel extends ResearchSession {
  const ResearchSessionModel({
    required super.id,
    required super.query,
    required super.rankedResults,
    super.selectedSubredditName,
    super.memoryContent,
    super.skillContent,
    required super.createdAt,
    required super.updatedAt,
  });

  factory ResearchSessionModel.fromEntity(ResearchSession session) {
    return ResearchSessionModel(
      id: session.id,
      query: session.query,
      rankedResults: session.rankedResults,
      selectedSubredditName: session.selectedSubredditName,
      memoryContent: session.memoryContent,
      skillContent: session.skillContent,
      createdAt: session.createdAt,
      updatedAt: session.updatedAt,
    );
  }

  factory ResearchSessionModel.fromJson(Map<String, dynamic> json) {
    final results = (json['rankedResults'] as List? ?? [])
        .map(
          (e) => SubredditScoreModel.fromJsonStored(e as Map<String, dynamic>),
        )
        .cast<SubredditScore>()
        .toList();
    return ResearchSessionModel(
      id: json['id'] as String,
      query: json['query'] as String,
      rankedResults: results,
      selectedSubredditName: json['selectedSubredditName'] as String?,
      memoryContent: json['memoryContent'] as String?,
      skillContent: json['skillContent'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'query': query,
      'rankedResults': rankedResults
          .map(
            (s) => s is SubredditScoreModel
                ? s.toJson()
                : SubredditScoreModel(
                    subreddit: s.subreddit,
                    activityScore: s.activityScore,
                    subscriberScore: s.subscriberScore,
                    relevanceScore: s.relevanceScore,
                    semanticScore: s.semanticScore,
                    totalScore: s.totalScore,
                    llmReasoning: s.llmReasoning,
                  ).toJson(),
          )
          .toList(),
      'selectedSubredditName': selectedSubredditName,
      'memoryContent': memoryContent,
      'skillContent': skillContent,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
