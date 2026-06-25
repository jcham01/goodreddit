import 'package:goodreddit/features/scraper/domain/entities/post.dart';

class PostModel extends Post {
  const PostModel({
    required super.id,
    required super.title,
    required super.selfText,
    required super.author,
    required super.score,
    required super.numComments,
    required super.url,
    required super.permalink,
    required super.createdAt,
    super.flair,
    super.isStickied,
    super.subreddit,
    super.thumbnail,
    super.preview,
    super.isVideo,
    super.over18,
    super.spoiler,
    super.locked,
    super.upvoteRatio,
    super.name,
    super.likes,
    super.saved,
    super.scoreHidden,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    return PostModel(
      id: data['id'] ?? '',
      title: data['title'] ?? '',
      selfText: data['selftext'] ?? '',
      author: data['author'] ?? '[deleted]',
      score: data['score'] ?? 0,
      numComments: data['num_comments'] ?? 0,
      url: data['url'] ?? '',
      permalink: data['permalink'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        ((data['created_utc'] ?? 0) as num).toInt() * 1000,
      ),
      flair: data['link_flair_text'],
      isStickied: data['stickied'] ?? false,
      subreddit: data['subreddit'] ?? '',
      thumbnail: data['thumbnail'] as String?,
      preview: _parsePreview(data),
      isVideo: data['is_video'] ?? false,
      over18: data['over_18'] ?? false,
      spoiler: data['spoiler'] ?? false,
      locked: data['locked'] ?? false,
      upvoteRatio: (data['upvote_ratio'] as num?)?.toDouble(),
      name: data['name'] as String?,
      // Reddit sends a real tri-state bool here; keep null as "no vote".
      likes: data['likes'] as bool?,
      saved: data['saved'] == true,
      scoreHidden: data['score_hidden'] == true || data['hide_score'] == true,
    );
  }

  /// Reddit nests the preview as `preview.images[0].source.url`, HTML-entity
  /// encoded (`&amp;`) — left as-is it 403s. Parsed defensively (the shape is
  /// often absent).
  static String? _parsePreview(Map<String, dynamic> data) {
    final preview = data['preview'];
    if (preview is Map) {
      final images = preview['images'];
      if (images is List && images.isNotEmpty) {
        final first = images.first;
        if (first is Map) {
          final source = first['source'];
          if (source is Map && source['url'] is String) {
            return (source['url'] as String).replaceAll('&amp;', '&');
          }
        }
      }
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'selftext': selfText,
      'author': author,
      'score': score,
      'num_comments': numComments,
      'url': url,
      'permalink': permalink,
      'created_utc': createdAt.millisecondsSinceEpoch ~/ 1000,
      'link_flair_text': flair,
      'stickied': isStickied,
      'subreddit': subreddit,
      'thumbnail': thumbnail,
      'is_video': isVideo,
      'over_18': over18,
      'spoiler': spoiler,
      'locked': locked,
      'upvote_ratio': upvoteRatio,
      'name': name,
      'likes': likes,
      'saved': saved,
      'score_hidden': scoreHidden,
    };
  }
}
