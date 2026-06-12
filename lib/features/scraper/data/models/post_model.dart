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
    );
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
    };
  }
}
