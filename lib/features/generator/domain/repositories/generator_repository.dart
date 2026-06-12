import 'package:dartz/dartz.dart';
import 'package:goodreddit/core/error/failures.dart';
import 'package:goodreddit/features/scraper/domain/entities/comment.dart';
import 'package:goodreddit/features/scraper/domain/entities/post.dart';
import 'package:goodreddit/features/search/domain/entities/subreddit.dart';

abstract class GeneratorRepository {
  Future<Either<Failure, String>> generateMemoryFile({
    required Subreddit subreddit,
    required List<Post> posts,
    required List<Comment> comments,
  });

  Future<Either<Failure, String>> generateSkillFile({
    required Subreddit subreddit,
    required List<Post> posts,
    required List<Comment> comments,
  });
}
