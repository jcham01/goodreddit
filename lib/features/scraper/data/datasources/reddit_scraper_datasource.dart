import 'package:goodreddit/core/constants/api_constants.dart';
import 'package:goodreddit/core/error/exceptions.dart';
import 'package:goodreddit/core/network/reddit_web_client.dart';
import 'package:goodreddit/features/scraper/data/models/comment_model.dart';
import 'package:goodreddit/features/scraper/data/models/post_model.dart';

abstract class RedditScraperDataSource {
  Future<List<PostModel>> getTopPosts(
    String subredditName, {
    String timeFilter = ApiConstants.defaultTimeFilter,
    int limit = ApiConstants.defaultPostLimit,
  });

  Future<List<CommentModel>> getPostComments(
    String subredditName,
    String postId, {
    int limit = ApiConstants.defaultCommentLimit,
  });
}

class RedditScraperDataSourceImpl implements RedditScraperDataSource {
  final RedditWebClient webClient;

  RedditScraperDataSourceImpl({required this.webClient});

  @override
  Future<List<PostModel>> getTopPosts(
    String subredditName, {
    String timeFilter = ApiConstants.defaultTimeFilter,
    int limit = ApiConstants.defaultPostLimit,
  }) async {
    final data = await webClient.getJson(
      ApiConstants.subredditTopPath(subredditName),
      query: {'t': timeFilter, 'limit': limit},
    );
    try {
      final children = (data['data']?['children'] as List?) ?? const [];
      return children
          .map((c) => PostModel.fromJson(c as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw RedditException('Failed to parse posts: $e');
    }
  }

  @override
  Future<List<CommentModel>> getPostComments(
    String subredditName,
    String postId, {
    int limit = ApiConstants.defaultCommentLimit,
  }) async {
    final data = await webClient.getJson(
      ApiConstants.postCommentsPath(subredditName, postId),
      query: {'limit': limit, 'sort': 'top'},
    );
    try {
      // Reddit returns a 2-element array: [post listing, comments listing].
      final commentListing = (data as List)[1];
      final children =
          (commentListing['data']?['children'] as List?) ?? const [];
      return children
          .where((child) => child['kind'] == 't1') // t1 = actual comment
          .map((c) => CommentModel.fromJson(c as Map<String, dynamic>, postId))
          .toList();
    } catch (e) {
      throw RedditException('Failed to parse comments: $e');
    }
  }
}
