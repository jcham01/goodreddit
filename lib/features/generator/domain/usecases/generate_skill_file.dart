import 'package:dartz/dartz.dart';
import 'package:goodreddit/core/error/failures.dart';
import 'package:goodreddit/core/usecases/usecase.dart';
import 'package:goodreddit/features/generator/domain/repositories/generator_repository.dart';
import 'package:goodreddit/features/generator/domain/usecases/generate_memory_file.dart'
    show GenerationParams;

class GenerateSkillFile implements UseCase<String, GenerationParams> {
  final GeneratorRepository repository;

  GenerateSkillFile(this.repository);

  @override
  Future<Either<Failure, String>> call(GenerationParams params) {
    return repository.generateSkillFile(
      subreddit: params.subreddit,
      posts: params.posts,
      comments: params.comments,
    );
  }
}
