import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:goodreddit/core/error/failures.dart';
import 'package:goodreddit/core/usecases/usecase.dart';
import 'package:goodreddit/features/search/domain/entities/search_ranking_result.dart';
import 'package:goodreddit/features/search/domain/repositories/subreddit_repository.dart';

class SearchAndRankSubreddits
    implements UseCase<SearchRankingResult, SearchParams> {
  final SubredditRepository repository;

  SearchAndRankSubreddits(this.repository);

  @override
  Future<Either<Failure, SearchRankingResult>> call(SearchParams params) {
    return repository.searchAndRank(params.query);
  }
}

class SearchParams extends Equatable {
  final String query;

  const SearchParams(this.query);

  @override
  List<Object?> get props => [query];
}
