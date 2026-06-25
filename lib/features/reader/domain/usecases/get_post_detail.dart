import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:goodreddit/core/constants/api_constants.dart';
import 'package:goodreddit/core/error/failures.dart';
import 'package:goodreddit/core/usecases/usecase.dart';
import 'package:goodreddit/features/reader/domain/entities/comment_sort.dart';
import 'package:goodreddit/features/reader/domain/entities/post_detail.dart';
import 'package:goodreddit/features/reader/domain/repositories/reader_repository.dart';

class GetPostDetail implements UseCase<PostDetail, PostDetailParams> {
  final ReaderRepository repository;

  GetPostDetail(this.repository);

  @override
  Future<Either<Failure, PostDetail>> call(PostDetailParams params) {
    return repository.getPostDetail(
      subreddit: params.subreddit,
      postId: params.postId,
      sort: params.sort,
      limit: params.limit,
    );
  }
}

class PostDetailParams extends Equatable {
  final String subreddit;
  final String postId;
  final CommentSort sort;
  final int limit;

  const PostDetailParams({
    required this.subreddit,
    required this.postId,
    this.sort = CommentSort.best,
    this.limit = ApiConstants.defaultCommentLimit,
  });

  @override
  List<Object?> get props => [subreddit, postId, sort, limit];
}
