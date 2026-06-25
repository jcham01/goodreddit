import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:goodreddit/core/constants/api_constants.dart';
import 'package:goodreddit/core/error/failures.dart';
import 'package:goodreddit/core/usecases/usecase.dart';
import 'package:goodreddit/features/reader/domain/entities/feed_page.dart';
import 'package:goodreddit/features/reader/domain/entities/subreddit_sort.dart';
import 'package:goodreddit/features/reader/domain/repositories/reader_repository.dart';

class GetSubredditFeed implements UseCase<FeedPage, SubredditFeedParams> {
  final ReaderRepository repository;

  GetSubredditFeed(this.repository);

  @override
  Future<Either<Failure, FeedPage>> call(SubredditFeedParams params) {
    return repository.getSubredditFeed(
      subreddit: params.subreddit,
      sort: params.sort,
      after: params.after,
      limit: params.limit,
    );
  }
}

class SubredditFeedParams extends Equatable {
  final String subreddit;
  final SubredditSort sort;
  final String? after;
  final int limit;

  const SubredditFeedParams({
    required this.subreddit,
    this.sort = SubredditSort.hot,
    this.after,
    this.limit = ApiConstants.defaultFeedLimit,
  });

  @override
  List<Object?> get props => [subreddit, sort, after, limit];
}
