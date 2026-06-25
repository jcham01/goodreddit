import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goodreddit/core/bloc/safe_cubit.dart';
import 'package:goodreddit/core/usecases/usecase.dart';
import 'package:goodreddit/features/generator/data/datasources/data_export_helper.dart';
import 'package:goodreddit/features/generator/data/datasources/file_exporter.dart';
import 'package:goodreddit/features/generator/domain/usecases/generate_memory_file.dart';
import 'package:goodreddit/features/generator/domain/usecases/generate_skill_file.dart';
import 'package:goodreddit/features/history/domain/entities/research_session.dart';
import 'package:goodreddit/features/history/domain/usecases/get_all_sessions.dart';
import 'package:goodreddit/features/history/domain/usecases/save_session.dart';
import 'package:goodreddit/features/scraper/domain/entities/comment.dart';
import 'package:goodreddit/features/scraper/domain/entities/post.dart';
import 'package:goodreddit/features/search/domain/entities/subreddit.dart';
import 'package:uuid/uuid.dart';

part 'generator_state.dart';

class GeneratorCubit extends Cubit<GeneratorState> with SafeEmit<GeneratorState> {
  final GenerateMemoryFile generateMemory;
  final GenerateSkillFile generateSkill;
  final FileExporter fileExporter;
  final SaveSession saveSession;
  final GetAllSessions getAllSessions;
  final Uuid uuid;

  GeneratorCubit({
    required this.generateMemory,
    required this.generateSkill,
    required this.fileExporter,
    required this.saveSession,
    required this.getAllSessions,
    Uuid? uuid,
  }) : uuid = uuid ?? const Uuid(),
       super(const GeneratorState());

  Future<void> runMemory({
    required Subreddit subreddit,
    required List<Post> posts,
    required List<Comment> comments,
  }) async {
    safeEmit(
      state.copyWith(
        status: GeneratorStatus.generating,
        kind: GenerationKind.memory,
      ),
    );
    final result = await generateMemory(
      GenerationParams(subreddit: subreddit, posts: posts, comments: comments),
    );
    await result.fold(
      (f) async => safeEmit(
        state.copyWith(status: GeneratorStatus.error, errorMessage: f.message),
      ),
      (content) async {
        safeEmit(
          state.copyWith(status: GeneratorStatus.done, memoryContent: content),
        );
        await _persistGenerated(subreddit, memory: content);
      },
    );
  }

  Future<void> runSkill({
    required Subreddit subreddit,
    required List<Post> posts,
    required List<Comment> comments,
  }) async {
    safeEmit(
      state.copyWith(
        status: GeneratorStatus.generating,
        kind: GenerationKind.skill,
      ),
    );
    final result = await generateSkill(
      GenerationParams(subreddit: subreddit, posts: posts, comments: comments),
    );
    await result.fold(
      (f) async => safeEmit(
        state.copyWith(status: GeneratorStatus.error, errorMessage: f.message),
      ),
      (content) async {
        safeEmit(
          state.copyWith(status: GeneratorStatus.done, skillContent: content),
        );
        await _persistGenerated(subreddit, skill: content);
      },
    );
  }

  /// Persists a generated file into the Library so it survives the back stack
  /// (fixes the lost-payoff bug). Best-effort: a storage error must never
  /// override a successful generation. Attaches to the research session that
  /// surfaced this subreddit when one exists, otherwise creates a session
  /// keyed by the subreddit.
  Future<void> _persistGenerated(
    Subreddit subreddit, {
    String? memory,
    String? skill,
  }) async {
    try {
      final now = DateTime.now();
      final existing = (await getAllSessions(const NoParams())).fold<
        ResearchSession?
      >((_) => null, (sessions) => _matchSession(sessions, subreddit.name));
      final session =
          existing?.copyWith(
            selectedSubredditName: subreddit.name,
            memoryContent: memory,
            skillContent: skill,
            updatedAt: now,
          ) ??
          ResearchSession(
            id: uuid.v4(),
            query: 'r/${subreddit.name}',
            rankedResults: const [],
            selectedSubredditName: subreddit.name,
            memoryContent: memory,
            skillContent: skill,
            createdAt: now,
            updatedAt: now,
          );
      await saveSession(session);
    } catch (_) {
      // Best-effort persistence.
    }
  }

  ResearchSession? _matchSession(
    List<ResearchSession> sessions,
    String subredditName,
  ) {
    for (final s in sessions) {
      if (s.selectedSubredditName == subredditName) return s;
    }
    for (final s in sessions) {
      if (s.rankedResults.any((r) => r.subreddit.name == subredditName)) {
        return s;
      }
    }
    return null;
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
