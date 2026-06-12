import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:goodreddit/core/error/failures.dart';
import 'package:goodreddit/core/usecases/usecase.dart';
import 'package:goodreddit/features/scraper/domain/entities/subreddit_content.dart';
import 'package:goodreddit/features/scraper/domain/repositories/scraper_repository.dart';

class ScrapeSubredditContent
    implements UseCase<SubredditContent, ScrapeParams> {
  final ScraperRepository repository;

  ScrapeSubredditContent(this.repository);

  @override
  Future<Either<Failure, SubredditContent>> call(ScrapeParams params) {
    return repository.scrapeContent(
      params.subredditName,
      timeFilter: params.timeFilter,
    );
  }
}

class ScrapeParams extends Equatable {
  final String subredditName;
  final String timeFilter;

  const ScrapeParams(this.subredditName, {this.timeFilter = 'week'});

  @override
  List<Object?> get props => [subredditName, timeFilter];
}
