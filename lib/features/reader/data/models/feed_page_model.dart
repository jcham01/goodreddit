import 'package:goodreddit/features/reader/domain/entities/feed_page.dart';
import 'package:goodreddit/features/scraper/data/models/post_model.dart';

class FeedPageModel extends FeedPage {
  const FeedPageModel({required super.posts, super.after});

  /// Parses a Reddit "Listing" envelope: `{ data: { children: [...], after } }`.
  factory FeedPageModel.fromListing(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;
    final children = (data?['children'] as List?) ?? const [];
    final posts = children
        .whereType<Map>()
        .where((c) => c['kind'] == 't3') // t3 = link/post
        .map((c) => PostModel.fromJson(c.cast<String, dynamic>()))
        .toList();
    final after = data?['after'] as String?;
    return FeedPageModel(posts: posts, after: after);
  }
}
