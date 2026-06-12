import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goodreddit/core/error/failures.dart';
import 'package:goodreddit/features/scraper/domain/entities/comment.dart';
import 'package:goodreddit/features/scraper/domain/entities/post.dart';
import 'package:goodreddit/features/scraper/domain/usecases/scrape_subreddit_content.dart';

part 'scraper_state.dart';

class ScraperCubit extends Cubit<ScraperState> {
  final ScrapeSubredditContent scrapeContent;

  ScraperCubit({required this.scrapeContent}) : super(const ScraperState());

  Future<void> scrape(String subredditName) async {
    emit(state.copyWith(status: ScraperStatus.loading));
    final result = await scrapeContent(ScrapeParams(subredditName));
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: ScraperStatus.error,
          errorMessage: failure.message,
          needsAuth: failure is NotAuthenticatedFailure,
        ),
      ),
      (content) => emit(
        state.copyWith(
          status: ScraperStatus.loaded,
          posts: content.posts,
          comments: content.comments,
        ),
      ),
    );
  }
}
