import 'package:goodreddit/core/constants/api_constants.dart';
import 'package:goodreddit/core/error/exceptions.dart';
import 'package:goodreddit/core/network/reddit_web_client.dart';
import 'package:goodreddit/features/reader/data/models/feed_page_model.dart';
import 'package:goodreddit/features/reader/data/models/post_detail_model.dart';

abstract class RedditReaderDataSource {
  Future<FeedPageModel> getFeed({
    required String path,
    String? after,
    int limit = ApiConstants.defaultFeedLimit,
  });

  Future<PostDetailModel> getPostDetail({
    required String subreddit,
    required String postId,
    required String sort,
    int limit = ApiConstants.defaultCommentLimit,
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

  @override
  Future<PostDetailModel> getPostDetail({
    required String subreddit,
    required String postId,
    required String sort,
    int limit = ApiConstants.defaultCommentLimit,
  }) async {
    final data = await webClient.getJson(
      ApiConstants.postCommentsPath(subreddit, postId),
      query: {'limit': limit, 'sort': sort, 'raw_json': 1},
    );
    try {
      return PostDetailModel.fromResponse(data);
    } on RedditException {
      rethrow;
    } catch (e) {
      throw RedditException('Failed to parse post detail: $e');
    }
  }
}
