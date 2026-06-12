import 'package:goodreddit/core/constants/api_constants.dart';
import 'package:goodreddit/core/error/exceptions.dart';
import 'package:goodreddit/core/network/reddit_web_client.dart';
import 'package:goodreddit/features/search/data/models/subreddit_model.dart';

abstract class RedditSearchDataSource {
  Future<List<SubredditModel>> searchSubreddits(String query);
}

class RedditSearchDataSourceImpl implements RedditSearchDataSource {
  final RedditWebClient webClient;

  RedditSearchDataSourceImpl({required this.webClient});

  @override
  Future<List<SubredditModel>> searchSubreddits(String query) async {
    final data = await webClient.getJson(
      ApiConstants.subredditSearchPath,
      query: {
        'q': query,
        'limit': ApiConstants.defaultSearchLimit,
        'type': 'sr',
        'sort': 'relevance',
      },
    );

    try {
      final children = (data['data']?['children'] as List?) ?? const [];
      return children
          .map((child) => SubredditModel.fromJson(child as Map<String, dynamic>))
          .where((sub) => !sub.isNsfw)
          .toList();
    } catch (e) {
      throw RedditException('Failed to parse search results: $e');
    }
  }
}
