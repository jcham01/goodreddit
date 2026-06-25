import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:goodreddit/core/constants/api_constants.dart';
import 'package:goodreddit/core/error/failures.dart';
import 'package:goodreddit/core/usecases/usecase.dart';
import 'package:goodreddit/features/reader/domain/entities/feed_page.dart';
import 'package:goodreddit/features/reader/domain/entities/feed_source.dart';
import 'package:goodreddit/features/reader/domain/repositories/reader_repository.dart';

class GetFeed implements UseCase<FeedPage, FeedParams> {
  final ReaderRepository repository;

  GetFeed(this.repository);

  @override
  Future<Either<Failure, FeedPage>> call(FeedParams params) {
    return repository.getFeed(
      source: params.source,
      after: params.after,
      limit: params.limit,
    );
  }
}

class FeedParams extends Equatable {
  final FeedSource source;
  final String? after;
  final int limit;

  const FeedParams({
    required this.source,
    this.after,
    this.limit = ApiConstants.defaultFeedLimit,
  });

  @override
  List<Object?> get props => [source, after, limit];
}
