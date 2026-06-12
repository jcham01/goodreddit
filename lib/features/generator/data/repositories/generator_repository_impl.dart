import 'package:dartz/dartz.dart';
import 'package:goodreddit/core/error/exceptions.dart';
import 'package:goodreddit/core/error/failures.dart';
import 'package:goodreddit/features/generator/data/datasources/llm_generator_datasource.dart';
import 'package:goodreddit/features/generator/domain/repositories/generator_repository.dart';
import 'package:goodreddit/features/scraper/domain/entities/comment.dart';
import 'package:goodreddit/features/scraper/domain/entities/post.dart';
import 'package:goodreddit/features/search/domain/entities/subreddit.dart';
import 'package:goodreddit/features/settings/data/datasources/settings_local_datasource.dart';

class GeneratorRepositoryImpl implements GeneratorRepository {
  final LlmGeneratorDataSource llmDataSource;
  final SettingsLocalDataSource settingsDataSource;

  GeneratorRepositoryImpl({
    required this.llmDataSource,
    required this.settingsDataSource,
  });

  @override
  Future<Either<Failure, String>> generateMemoryFile({
    required Subreddit subreddit,
    required List<Post> posts,
    required List<Comment> comments,
  }) {
    return _generate(_buildMemoryPrompt(subreddit, posts, comments));
  }

  @override
  Future<Either<Failure, String>> generateSkillFile({
    required Subreddit subreddit,
    required List<Post> posts,
    required List<Comment> comments,
  }) {
    return _generate(_buildSkillPrompt(subreddit, posts));
  }

  Future<Either<Failure, String>> _generate(String prompt) async {
    try {
      final config = await settingsDataSource.getConfig();
      if (!config.isConfigured) {
        return const Left(ConfigFailure('LLM API key not configured'));
      }
      final content = await llmDataSource.generateContent(
        prompt: prompt,
        config: config,
      );
      return Right(content);
    } on LlmException catch (e) {
      return Left(LlmFailure(e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  String _buildMemoryPrompt(
    Subreddit subreddit,
    List<Post> posts,
    List<Comment> comments,
  ) {
    final topPosts = posts
        .take(10)
        .map((p) {
          final excerpt = p.selfText.isNotEmpty
              ? '\n  ${p.selfText.substring(0, p.selfText.length.clamp(0, 200))}...'
              : '';
          return '- [${p.score} upvotes] "${p.title}" by u/${p.author}$excerpt';
        })
        .join('\n');

    final topComments = comments
        .where((c) => c.score > 5)
        .take(15)
        .map(
          (c) =>
              '- [${c.score}] u/${c.author}: "${c.body.substring(0, c.body.length.clamp(0, 150))}"',
        )
        .join('\n');

    return '''Generate a MEMORY.md file for an AI agent specialized in the subreddit r/${subreddit.name}.

## Subreddit Info:
- Name: r/${subreddit.name}
- Title: ${subreddit.title}
- Description: ${subreddit.description}
- Subscribers: ${subreddit.subscribers}
- Active Users: ${subreddit.activeUsers}

## Top Posts (this week):
$topPosts

## Notable Comments:
$topComments

## Instructions:
Create a comprehensive MEMORY.md that includes:
1. **Subreddit Identity**: What this community is about, its culture and values
2. **Key Topics & Themes**: Recurring discussion themes from the posts
3. **Community Vocabulary**: Specific jargon, acronyms, memes used
4. **Notable Members**: Active/influential contributors
5. **Content Patterns**: Types of posts that get engagement
6. **Community Rules & Norms**: Unwritten rules visible from interactions
7. **Current Hot Topics**: What the community is discussing right now
8. **Sentiment & Tone**: Overall mood and communication style

Format as clean Markdown. Be specific and data-driven based on the content provided.''';
  }

  String _buildSkillPrompt(Subreddit subreddit, List<Post> posts) {
    final topPosts = posts
        .take(10)
        .map(
          (p) =>
              '- [${p.score} upvotes] "${p.title}" (${p.numComments} comments)',
        )
        .join('\n');

    return '''Generate a SKILL.md file that configures an AI agent to be a specialist for r/${subreddit.name}.

## Subreddit Context:
- Name: r/${subreddit.name}
- Title: ${subreddit.title}
- Description: ${subreddit.description}
- Subscribers: ${subreddit.subscribers}

## Top Posts (this week):
$topPosts

## Instructions:
Create a SKILL.md that defines:
1. **Agent Role**: Clear definition of what this agent does
2. **Expertise Areas**: Specific knowledge domains the agent should cover
3. **Communication Style**: How the agent should write (matching community tone)
4. **Response Templates**: Common response patterns for typical questions
5. **Do's and Don'ts**: Behavioral guidelines based on community norms
6. **Knowledge Sources**: Where to find authoritative info for this topic
7. **Engagement Strategies**: How to create valuable content for this community
8. **Prompt Templates**: Ready-to-use prompts for common tasks

Format as clean Markdown with clear sections. The file should be directly usable as an agent configuration.''';
  }
}
