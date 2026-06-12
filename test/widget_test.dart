// Smoke test for the GoodReddit composite scoring algorithm.

import 'package:flutter_test/flutter_test.dart';
import 'package:goodreddit/features/search/data/models/subreddit_model.dart';
import 'package:goodreddit/features/search/data/models/subreddit_score_model.dart';

void main() {
  test('composite score rewards keyword relevance', () {
    const relevant = SubredditModel(
      name: 'flutterdev',
      displayName: 'r/flutterdev',
      title: 'Flutter Development',
      description: 'A subreddit about the Flutter framework',
      subscribers: 200000,
      activeUsers: 500,
      url: '/r/flutterdev',
    );
    const irrelevant = SubredditModel(
      name: 'cooking',
      displayName: 'r/cooking',
      title: 'Cooking',
      description: 'Recipes and food',
      subscribers: 200000,
      activeUsers: 500,
      url: '/r/cooking',
    );

    final a = SubredditScoreModel.compute(subreddit: relevant, query: 'flutter');
    final b =
        SubredditScoreModel.compute(subreddit: irrelevant, query: 'flutter');

    expect(a.totalScore, greaterThan(b.totalScore));
    expect(a.relevanceScore, 1.0);
    expect(b.relevanceScore, 0.0);
  });
}
