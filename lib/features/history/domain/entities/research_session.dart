import 'package:equatable/equatable.dart';
import 'package:goodreddit/features/search/domain/entities/subreddit_score.dart';

/// A saved research session: a query and its ranked subreddit results, plus any
/// scraped content and generated files associated with it.
class ResearchSession extends Equatable {
  final String id;
  final String query;
  final List<SubredditScore> rankedResults;
  final String? selectedSubredditName;
  final String? memoryContent;
  final String? skillContent;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ResearchSession({
    required this.id,
    required this.query,
    required this.rankedResults,
    this.selectedSubredditName,
    this.memoryContent,
    this.skillContent,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [id, query, createdAt, updatedAt];
}
