import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:goodreddit/core/error/failures.dart';
import 'package:goodreddit/core/usecases/usecase.dart';
import 'package:goodreddit/features/generator/domain/repositories/generator_repository.dart';
import 'package:goodreddit/features/scraper/domain/entities/comment.dart';
import 'package:goodreddit/features/scraper/domain/entities/post.dart';
import 'package:goodreddit/features/search/domain/entities/subreddit.dart';

class GenerateMemoryFile implements UseCase<String, GenerationParams> {
  final GeneratorRepository repository;

  GenerateMemoryFile(this.repository);

  @override
  Future<Either<Failure, String>> call(GenerationParams params) {
    return repository.generateMemoryFile(
      subreddit: params.subreddit,
      posts: params.posts,
      comments: params.comments,
    );
  }
}

class GenerationParams extends Equatable {
  final Subreddit subreddit;
  final List<Post> posts;
  final List<Comment> comments;

  const GenerationParams({
    required this.subreddit,
    required this.posts,
    required this.comments,
  });

  @override
  List<Object?> get props => [subreddit, posts, comments];
}
