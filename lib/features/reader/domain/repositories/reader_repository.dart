import 'package:dartz/dartz.dart';
import 'package:goodreddit/core/constants/api_constants.dart';
import 'package:goodreddit/core/error/failures.dart';
import 'package:goodreddit/features/reader/domain/entities/feed_page.dart';
import 'package:goodreddit/features/reader/domain/entities/feed_source.dart';

abstract class ReaderRepository {
  Future<Either<Failure, FeedPage>> getFeed({
    required FeedSource source,
    String? after,
    int limit = ApiConstants.defaultFeedLimit,
  });
}
