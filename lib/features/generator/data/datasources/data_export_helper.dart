import 'dart:convert';

import 'package:goodreddit/features/scraper/data/models/comment_model.dart';
import 'package:goodreddit/features/scraper/data/models/post_model.dart';
import 'package:goodreddit/features/scraper/domain/entities/comment.dart';
import 'package:goodreddit/features/scraper/domain/entities/post.dart';

/// Serialises scraped posts/comments to JSON or RFC 4180 CSV.
class DataExportHelper {
  const DataExportHelper._();

  static String postsToJson(List<Post> posts) {
    final data = posts.map(_postToModel).map((p) => p.toJson()).toList();
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  static String commentsToJson(List<Comment> comments) {
    final data =
        comments.map(_commentToModel).map((c) => c.toJson()).toList();
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  static String postsToCsv(List<Post> posts) {
    final buffer = StringBuffer()
      ..writeln('id,title,author,score,num_comments,flair,created_at,url');
    for (final p in posts) {
      buffer.writeln([
        _esc(p.id),
        _esc(p.title),
        _esc(p.author),
        p.score,
        p.numComments,
        _esc(p.flair ?? ''),
        p.createdAt.toIso8601String(),
        _esc(p.url),
      ].join(','));
    }
    return buffer.toString();
  }

  static String commentsToCsv(List<Comment> comments) {
    final buffer = StringBuffer()
      ..writeln('id,post_id,author,score,depth,created_at,body');
    for (final c in comments) {
      buffer.writeln([
        _esc(c.id),
        _esc(c.postId),
        _esc(c.author),
        c.score,
        c.depth,
        c.createdAt.toIso8601String(),
        _esc(c.body),
      ].join(','));
    }
    return buffer.toString();
  }

  static PostModel _postToModel(Post p) => p is PostModel
      ? p
      : PostModel(
          id: p.id,
          title: p.title,
          selfText: p.selfText,
          author: p.author,
          score: p.score,
          numComments: p.numComments,
          url: p.url,
          permalink: p.permalink,
          createdAt: p.createdAt,
          flair: p.flair,
          isStickied: p.isStickied,
        );

  static CommentModel _commentToModel(Comment c) => c is CommentModel
      ? c
      : CommentModel(
          id: c.id,
          body: c.body,
          author: c.author,
          score: c.score,
          createdAt: c.createdAt,
          postId: c.postId,
          depth: c.depth,
        );

  static String _esc(String value) {
    if (value.contains(',') ||
        value.contains('"') ||
        value.contains('\n') ||
        value.contains('\r')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}
