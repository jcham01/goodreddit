import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goodreddit/features/generator/data/datasources/data_export_helper.dart';
import 'package:goodreddit/features/generator/data/datasources/file_exporter.dart';
import 'package:goodreddit/features/generator/domain/usecases/generate_memory_file.dart';
import 'package:goodreddit/features/generator/domain/usecases/generate_skill_file.dart';
import 'package:goodreddit/features/scraper/domain/entities/comment.dart';
import 'package:goodreddit/features/scraper/domain/entities/post.dart';
import 'package:goodreddit/features/search/domain/entities/subreddit.dart';

part 'generator_state.dart';

class GeneratorCubit extends Cubit<GeneratorState> {
  final GenerateMemoryFile generateMemory;
  final GenerateSkillFile generateSkill;
  final FileExporter fileExporter;

  GeneratorCubit({
    required this.generateMemory,
    required this.generateSkill,
    required this.fileExporter,
  }) : super(const GeneratorState());

  Future<void> runMemory({
    required Subreddit subreddit,
    required List<Post> posts,
    required List<Comment> comments,
  }) async {
    emit(
      state.copyWith(
        status: GeneratorStatus.generating,
        kind: GenerationKind.memory,
      ),
    );
    final result = await generateMemory(
      GenerationParams(subreddit: subreddit, posts: posts, comments: comments),
    );
    result.fold(
      (f) => emit(
        state.copyWith(status: GeneratorStatus.error, errorMessage: f.message),
      ),
      (content) => emit(
        state.copyWith(status: GeneratorStatus.done, memoryContent: content),
      ),
    );
  }

  Future<void> runSkill({
    required Subreddit subreddit,
    required List<Post> posts,
    required List<Comment> comments,
  }) async {
    emit(
      state.copyWith(
        status: GeneratorStatus.generating,
        kind: GenerationKind.skill,
      ),
    );
    final result = await generateSkill(
      GenerationParams(subreddit: subreddit, posts: posts, comments: comments),
    );
    result.fold(
      (f) => emit(
        state.copyWith(status: GeneratorStatus.error, errorMessage: f.message),
      ),
      (content) => emit(
        state.copyWith(status: GeneratorStatus.done, skillContent: content),
      ),
    );
  }

  Future<void> exportPostsJson(String subreddit, List<Post> posts) =>
      fileExporter.shareText(
        fileName: '${subreddit}_posts.json',
        content: DataExportHelper.postsToJson(posts),
      );

  Future<void> exportPostsCsv(String subreddit, List<Post> posts) =>
      fileExporter.shareText(
        fileName: '${subreddit}_posts.csv',
        content: DataExportHelper.postsToCsv(posts),
      );

  Future<void> exportCommentsJson(String subreddit, List<Comment> comments) =>
      fileExporter.shareText(
        fileName: '${subreddit}_comments.json',
        content: DataExportHelper.commentsToJson(comments),
      );

  Future<void> shareMarkdown(String name, String content) =>
      fileExporter.shareText(fileName: name, content: content);
}
