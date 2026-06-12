import 'package:goodreddit/features/scraper/domain/entities/comment.dart';

class CommentModel extends Comment {
  const CommentModel({
    required super.id,
    required super.body,
    required super.author,
    required super.score,
    required super.createdAt,
    required super.postId,
    super.depth,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json, String postId) {
    final data = json['data'] ?? json;
    return CommentModel(
      id: data['id'] ?? '',
      body: data['body'] ?? '',
      author: data['author'] ?? '[deleted]',
      score: data['score'] ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        ((data['created_utc'] ?? 0) as num).toInt() * 1000,
      ),
      postId: postId,
      depth: data['depth'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'body': body,
      'author': author,
      'score': score,
      'created_utc': createdAt.millisecondsSinceEpoch ~/ 1000,
      'postId': postId,
      'depth': depth,
    };
  }
}
