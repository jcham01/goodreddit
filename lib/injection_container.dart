import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:goodreddit/core/network/chatgpt_web_client.dart';
import 'package:goodreddit/core/network/reddit_web_client.dart';
import 'package:goodreddit/features/auth/data/datasources/reddit_auth_datasource.dart';
import 'package:goodreddit/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:goodreddit/features/auth/domain/repositories/auth_repository.dart';
import 'package:goodreddit/features/auth/domain/usecases/get_auth_status.dart';
import 'package:goodreddit/features/auth/domain/usecases/logout.dart';
import 'package:goodreddit/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:goodreddit/features/generator/data/datasources/file_exporter.dart';
import 'package:goodreddit/features/generator/data/datasources/llm_generator_datasource.dart';
import 'package:goodreddit/features/generator/data/repositories/generator_repository_impl.dart';
import 'package:goodreddit/features/generator/domain/repositories/generator_repository.dart';
import 'package:goodreddit/features/generator/domain/usecases/generate_memory_file.dart';
import 'package:goodreddit/features/generator/domain/usecases/generate_skill_file.dart';
import 'package:goodreddit/features/generator/presentation/bloc/generator_cubit.dart';
import 'package:goodreddit/features/history/data/datasources/session_local_datasource.dart';
import 'package:goodreddit/features/history/data/repositories/history_repository_impl.dart';
import 'package:goodreddit/features/history/domain/repositories/history_repository.dart';
import 'package:goodreddit/features/history/domain/usecases/delete_session.dart';
import 'package:goodreddit/features/history/domain/usecases/get_all_sessions.dart';
import 'package:goodreddit/features/history/domain/usecases/save_session.dart';
import 'package:goodreddit/features/history/presentation/bloc/history_cubit.dart';
import 'package:goodreddit/features/interactions/data/datasources/reddit_interactions_datasource.dart';
import 'package:goodreddit/features/interactions/data/repositories/interactions_repository_impl.dart';
import 'package:goodreddit/features/interactions/domain/repositories/interactions_repository.dart';
import 'package:goodreddit/features/interactions/domain/usecases/cast_vote.dart';
import 'package:goodreddit/features/interactions/domain/usecases/set_saved.dart';
import 'package:goodreddit/features/interactions/domain/usecases/set_subscribed.dart';
import 'package:goodreddit/features/interactions/presentation/bloc/interactions_cubit.dart';
import 'package:goodreddit/features/reader/data/datasources/reddit_reader_datasource.dart';
import 'package:goodreddit/features/reader/data/repositories/reader_repository_impl.dart';
import 'package:goodreddit/features/reader/domain/repositories/reader_repository.dart';
import 'package:goodreddit/features/reader/domain/usecases/get_feed.dart';
import 'package:goodreddit/features/reader/domain/usecases/get_post_detail.dart';
import 'package:goodreddit/features/reader/domain/usecases/get_subreddit_about.dart';
import 'package:goodreddit/features/reader/domain/usecases/get_subreddit_feed.dart';
import 'package:goodreddit/features/reader/presentation/bloc/feed_cubit.dart';
import 'package:goodreddit/features/reader/presentation/bloc/post_detail_cubit.dart';
import 'package:goodreddit/features/reader/presentation/bloc/subreddit_cubit.dart';
import 'package:goodreddit/features/scraper/data/datasources/reddit_scraper_datasource.dart';
import 'package:goodreddit/features/scraper/domain/entities/post.dart';
import 'package:goodreddit/features/scraper/data/repositories/scraper_repository_impl.dart';
import 'package:goodreddit/features/scraper/domain/repositories/scraper_repository.dart';
import 'package:goodreddit/features/scraper/domain/usecases/scrape_subreddit_content.dart';
import 'package:goodreddit/features/scraper/presentation/bloc/scraper_cubit.dart';
import 'package:goodreddit/features/search/data/datasources/llm_ranking_datasource.dart';
import 'package:goodreddit/features/search/data/datasources/reddit_search_datasource.dart';
import 'package:goodreddit/features/search/data/repositories/subreddit_repository_impl.dart';
import 'package:goodreddit/features/search/domain/repositories/subreddit_repository.dart';
import 'package:goodreddit/features/search/domain/usecases/search_and_rank_subreddits.dart';
import 'package:goodreddit/features/search/presentation/bloc/search_cubit.dart';
import 'package:goodreddit/features/settings/data/datasources/codex_auth_datasource.dart';
import 'package:goodreddit/features/settings/data/datasources/model_catalog_datasource.dart';
import 'package:goodreddit/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:goodreddit/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:goodreddit/features/settings/domain/repositories/settings_repository.dart';
import 'package:goodreddit/features/settings/domain/usecases/get_config.dart';
import 'package:goodreddit/features/settings/domain/usecases/list_models.dart';
import 'package:goodreddit/features/settings/domain/usecases/save_config.dart';
import 'package:goodreddit/features/settings/presentation/bloc/settings_cubit.dart';
import 'package:goodreddit/features/update/data/datasources/github_release_datasource.dart';
import 'package:goodreddit/features/update/data/repositories/update_repository_impl.dart';
import 'package:goodreddit/features/update/domain/repositories/update_repository.dart';
import 'package:goodreddit/features/update/domain/usecases/check_for_update.dart';
import 'package:goodreddit/features/update/presentation/bloc/update_cubit.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // ---- External / core ----
  await Hive.initFlutter();
  final sessionBox = await Hive.openBox<String>(
    SessionLocalDataSourceImpl.boxName,
  );

  sl
    ..registerLazySingleton(() => Dio())
    ..registerLazySingleton(() => const FlutterSecureStorage())
    ..registerLazySingleton(() => const Uuid())
    ..registerLazySingleton(() => FileExporter())
    ..registerLazySingleton<Box<String>>(() => sessionBox)
    ..registerLazySingleton(() => RedditWebClient())
    ..registerLazySingleton(() => ChatGptWebClient());

  // Codex "Sign in with ChatGPT": one instance, exposed both as the concrete
  // type (the Settings panel needs sign-in/probe) and as the narrow CodexCaller
  // the generator/ranking/catalog datasources depend on.
  sl
    ..registerLazySingleton(
      () => CodexAuthDataSource(
        secureStorage: sl(),
        uuid: sl(),
        chatGptWebClient: sl(),
        dio: sl(),
      ),
    )
    ..registerLazySingleton<CodexCaller>(() => sl<CodexAuthDataSource>());

  // ---- Datasources ----
  sl
    ..registerLazySingleton<RedditAuthDataSource>(
      () => RedditAuthDataSourceImpl(webClient: sl()),
    )
    ..registerLazySingleton<RedditSearchDataSource>(
      () => RedditSearchDataSourceImpl(webClient: sl()),
    )
    ..registerLazySingleton<RedditScraperDataSource>(
      () => RedditScraperDataSourceImpl(webClient: sl()),
    )
    ..registerLazySingleton<RedditReaderDataSource>(
      () => RedditReaderDataSourceImpl(webClient: sl()),
    )
    ..registerLazySingleton<RedditInteractionsDataSource>(
      () => RedditInteractionsDataSourceImpl(webClient: sl()),
    )
    ..registerLazySingleton<LlmRankingDataSource>(
      () => LlmRankingDataSourceImpl(dio: sl(), codex: sl()),
    )
    ..registerLazySingleton<LlmGeneratorDataSource>(
      () => LlmGeneratorDataSourceImpl(dio: sl(), codex: sl()),
    )
    ..registerLazySingleton<SettingsLocalDataSource>(
      () => SettingsLocalDataSourceImpl(secureStorage: sl()),
    )
    ..registerLazySingleton<ModelCatalogDataSource>(
      () => ModelCatalogDataSourceImpl(dio: sl(), codex: sl()),
    )
    ..registerLazySingleton<SessionLocalDataSource>(
      () => SessionLocalDataSourceImpl(box: sl()),
    )
    ..registerLazySingleton<GithubReleaseDataSource>(
      () => GithubReleaseDataSourceImpl(dio: sl()),
    );

  // ---- Repositories ----
  sl
    ..registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(dataSource: sl()),
    )
    ..registerLazySingleton<SubredditRepository>(
      () => SubredditRepositoryImpl(
        searchDataSource: sl(),
        llmRankingDataSource: sl(),
        settingsDataSource: sl(),
      ),
    )
    ..registerLazySingleton<ScraperRepository>(
      () => ScraperRepositoryImpl(dataSource: sl()),
    )
    ..registerLazySingleton<ReaderRepository>(
      () => ReaderRepositoryImpl(dataSource: sl()),
    )
    ..registerLazySingleton<InteractionsRepository>(
      () => InteractionsRepositoryImpl(dataSource: sl()),
    )
    ..registerLazySingleton<GeneratorRepository>(
      () => GeneratorRepositoryImpl(
        llmDataSource: sl(),
        settingsDataSource: sl(),
      ),
    )
    ..registerLazySingleton<SettingsRepository>(
      () => SettingsRepositoryImpl(
        dataSource: sl(),
        modelCatalogDataSource: sl(),
      ),
    )
    ..registerLazySingleton<HistoryRepository>(
      () => HistoryRepositoryImpl(dataSource: sl()),
    )
    ..registerLazySingleton<UpdateRepository>(
      () => UpdateRepositoryImpl(dataSource: sl()),
    );

  // ---- Use cases ----
  sl
    ..registerLazySingleton(() => GetAuthStatus(sl()))
    ..registerLazySingleton(() => Logout(sl()))
    ..registerLazySingleton(() => SearchAndRankSubreddits(sl()))
    ..registerLazySingleton(() => ScrapeSubredditContent(sl()))
    ..registerLazySingleton(() => GetFeed(sl()))
    ..registerLazySingleton(() => GetPostDetail(sl()))
    ..registerLazySingleton(() => GetSubredditFeed(sl()))
    ..registerLazySingleton(() => GetSubredditAbout(sl()))
    ..registerLazySingleton(() => CastVote(sl()))
    ..registerLazySingleton(() => SetSaved(sl()))
    ..registerLazySingleton(() => SetSubscribed(sl()))
    ..registerLazySingleton(() => GenerateMemoryFile(sl()))
    ..registerLazySingleton(() => GenerateSkillFile(sl()))
    ..registerLazySingleton(() => GetConfig(sl()))
    ..registerLazySingleton(() => SaveConfig(sl()))
    ..registerLazySingleton(() => ListModels(sl()))
    ..registerLazySingleton(() => GetAllSessions(sl()))
    ..registerLazySingleton(() => SaveSession(sl()))
    ..registerLazySingleton(() => DeleteSession(sl()))
    ..registerLazySingleton(() => CheckForUpdate(sl()));

  // ---- Cubits ----
  sl
    // Single app-wide write/interaction store (vote/save/subscribe), shared by
    // the feed, subreddit, and detail surfaces.
    ..registerLazySingleton(
      () => InteractionsCubit(castVote: sl(), setSaved: sl(), setSubscribed: sl()),
    )
    ..registerLazySingleton(
      () => AuthCubit(getAuthStatus: sl(), logout: sl(), interactions: sl()),
    )
    ..registerLazySingleton(() => UpdateCubit(checkForUpdate: sl()))
    ..registerFactory(() => SearchCubit(searchAndRank: sl(), saveSession: sl()))
    ..registerFactory(() => ScraperCubit(scrapeContent: sl()))
    ..registerFactory(() => FeedCubit(getFeed: sl(), interactions: sl()))
    ..registerFactoryParam<PostDetailCubit, Post, void>(
      (post, _) =>
          PostDetailCubit(getPostDetail: sl(), interactions: sl(), seed: post),
    )
    ..registerFactoryParam<SubredditCubit, String, void>(
      (name, _) => SubredditCubit(
        getFeed: sl(),
        getAbout: sl(),
        interactions: sl(),
        name: name,
      ),
    )
    ..registerFactory(
      () => GeneratorCubit(
        generateMemory: sl(),
        generateSkill: sl(),
        fileExporter: sl(),
        saveSession: sl(),
        getAllSessions: sl(),
      ),
    )
    ..registerFactory(
      () => SettingsCubit(getConfig: sl(), saveConfig: sl(), listModels: sl()),
    )
    ..registerFactory(
      () => HistoryCubit(getAllSessions: sl(), deleteSession: sl()),
    );
}
