import 'package:goodreddit/core/constants/api_constants.dart';
import 'package:goodreddit/core/error/exceptions.dart';
import 'package:goodreddit/core/network/reddit_web_client.dart';
import 'package:goodreddit/features/reader/data/models/feed_page_model.dart';

abstract class RedditReaderDataSource {
  Future<FeedPageModel> getFeed({
    required String path,
    String? after,
    int limit = ApiConstants.defaultFeedLimit,
  });
}

class RedditReaderDataSourceImpl implements RedditReaderDataSource {
  final RedditWebClient webClient;

  RedditReaderDataSourceImpl({required this.webClient});

  @override
  Future<FeedPageModel> getFeed({
    required String path,
    String? after,
    int limit = ApiConstants.defaultFeedLimit,
  }) async {
    final data = await webClient.getJson(
      path,
      query: {
        'limit': limit,
        'raw_json': 1,
        if (after != null && after.isNotEmpty) 'after': after,
      },
    );
    try {
      return FeedPageModel.fromListing(data as Map<String, dynamic>);
    } catch (e) {
      throw RedditException('Failed to parse feed: $e');
    }
  }
}
