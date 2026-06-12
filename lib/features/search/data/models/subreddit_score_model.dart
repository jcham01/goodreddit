import 'dart:math' as math;

import 'package:goodreddit/features/search/data/models/subreddit_model.dart';
import 'package:goodreddit/features/search/domain/entities/subreddit.dart';
import 'package:goodreddit/features/search/domain/entities/subreddit_score.dart';

/// Composite ranking model.
///
/// Log scaling compensates for Reddit's power-law popularity distribution so
/// mid-sized subreddits aren't drowned out by mega-subreddits. The semantic
/// component (0..1) is supplied by an LLM when configured, else 0.
class SubredditScoreModel extends SubredditScore {
  const SubredditScoreModel({
    required super.subreddit,
    required super.activityScore,
    required super.subscriberScore,
    required super.relevanceScore,
    super.semanticScore,
    required super.totalScore,
    super.llmReasoning,
  });

  factory SubredditScoreModel.compute({
    required Subreddit subreddit,
    required String query,
    double semanticScore = 0.0,
    String? llmReasoning,
  }) {
    // Activity score: normalised log of active users (0-1), capped at 10k.
    final activityScore = subreddit.activeUsers > 0
        ? math.min(1.0, math.log(subreddit.activeUsers + 1) / math.log(10000))
        : 0.0;

    // Subscriber score: normalised log of subscribers (0-1), capped at 10M.
    final subscriberScore = subreddit.subscribers > 0
        ? math.min(
            1.0,
            math.log(subreddit.subscribers + 1) / math.log(10000000),
          )
        : 0.0;

    // Keyword relevance: fraction of query words found in name/title/desc.
    final queryWords = query.toLowerCase().split(RegExp(r'\s+'));
    final haystack =
        '${subreddit.name} ${subreddit.title} ${subreddit.description}'
            .toLowerCase();
    final matchCount = queryWords
        .where((w) => w.isNotEmpty && haystack.contains(w))
        .length;
    final relevanceScore = queryWords.isNotEmpty
        ? math.min(1.0, matchCount / queryWords.length)
        : 0.0;

    final totalScore =
        (activityScore * 0.2) +
        (subscriberScore * 0.2) +
        (relevanceScore * 0.3) +
        (semanticScore * 0.3);

    return SubredditScoreModel(
      subreddit: subreddit,
      activityScore: activityScore,
      subscriberScore: subscriberScore,
      relevanceScore: relevanceScore,
      semanticScore: semanticScore,
      totalScore: totalScore,
      llmReasoning: llmReasoning,
    );
  }

  factory SubredditScoreModel.fromJsonStored(Map<String, dynamic> json) {
    return SubredditScoreModel(
      subreddit: SubredditModel.fromJson(json['subreddit']),
      activityScore: (json['activityScore'] as num).toDouble(),
      subscriberScore: (json['subscriberScore'] as num).toDouble(),
      relevanceScore: (json['relevanceScore'] as num).toDouble(),
      semanticScore: (json['semanticScore'] as num?)?.toDouble() ?? 0.0,
      totalScore: (json['totalScore'] as num).toDouble(),
      llmReasoning: json['llmReasoning'],
    );
  }

  Map<String, dynamic> toJson() {
    final subredditJson = subreddit is SubredditModel
        ? (subreddit as SubredditModel).toJson()
        : {
            'display_name': subreddit.name,
            'display_name_prefixed': subreddit.displayName,
            'title': subreddit.title,
            'public_description': subreddit.description,
            'subscribers': subreddit.subscribers,
            'accounts_active': subreddit.activeUsers,
            'url': subreddit.url,
            'created_utc': subreddit.createdAt != null
                ? subreddit.createdAt!.millisecondsSinceEpoch ~/ 1000
                : null,
            'over18': subreddit.isNsfw,
          };
    return {
      'subreddit': subredditJson,
      'activityScore': activityScore,
      'subscriberScore': subscriberScore,
      'relevanceScore': relevanceScore,
      'semanticScore': semanticScore,
      'totalScore': totalScore,
      'llmReasoning': llmReasoning,
    };
  }
}
