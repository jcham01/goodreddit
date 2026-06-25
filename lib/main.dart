import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goodreddit/core/constants/app_theme.dart';
import 'package:goodreddit/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:goodreddit/features/history/presentation/bloc/history_cubit.dart';
import 'package:goodreddit/features/interactions/presentation/bloc/interactions_cubit.dart';
import 'package:goodreddit/features/reader/presentation/bloc/feed_cubit.dart';
import 'package:goodreddit/features/search/presentation/bloc/search_cubit.dart';
import 'package:goodreddit/features/shell/presentation/pages/home_shell.dart';
import 'package:goodreddit/features/update/presentation/bloc/update_cubit.dart';
import 'package:goodreddit/features/update/presentation/widgets/update_gate.dart';
import 'package:goodreddit/injection_container.dart' as di;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.initDependencies();
  runApp(const GoodRedditApp());
}

class GoodRedditApp extends StatelessWidget {
  const GoodRedditApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // The interaction store sits above everything (tabs + every pushed
        // detail/subreddit route) so vote/save/subscribe stay in sync app-wide.
        BlocProvider<InteractionsCubit>(
          create: (_) => di.sl<InteractionsCubit>(),
        ),
        BlocProvider<AuthCubit>(create: (_) => di.sl<AuthCubit>()),
        BlocProvider<SearchCubit>(create: (_) => di.sl<SearchCubit>()),
        BlocProvider<FeedCubit>(create: (_) => di.sl<FeedCubit>()),
        BlocProvider<HistoryCubit>(create: (_) => di.sl<HistoryCubit>()..load()),
        BlocProvider<UpdateCubit>(create: (_) => di.sl<UpdateCubit>()),
      ],
      child: MaterialApp(
        title: 'GoodReddit',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        home: const UpdateGate(child: HomeShell()),
      ),
    );
  }
}
