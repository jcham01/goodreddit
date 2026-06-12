import 'package:equatable/equatable.dart';

class Comment extends Equatable {
  final String id;
  final String body;
  final String author;
  final int score;
  final DateTime createdAt;
  final String postId;
  final int depth;

  const Comment({
    required this.id,
    required this.body,
    required this.author,
    required this.score,
    required this.createdAt,
    required this.postId,
    this.depth = 0,
  });

  @override
  List<Object?> get props => [id, body, author, score];
}
