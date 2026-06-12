import 'package:equatable/equatable.dart';

class Post extends Equatable {
  final String id;
  final String title;
  final String selfText;
  final String author;
  final int score;
  final int numComments;
  final String url;
  final String permalink;
  final DateTime createdAt;
  final String? flair;
  final bool isStickied;

  const Post({
    required this.id,
    required this.title,
    required this.selfText,
    required this.author,
    required this.score,
    required this.numComments,
    required this.url,
    required this.permalink,
    required this.createdAt,
    this.flair,
    this.isStickied = false,
  });

  @override
  List<Object?> get props => [id, title, author, score, numComments];
}
