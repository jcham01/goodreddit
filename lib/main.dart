import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goodreddit/core/constants/app_theme.dart';
import 'package:goodreddit/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:goodreddit/features/search/presentation/bloc/search_cubit.dart';
import 'package:goodreddit/features/search/presentation/pages/search_page.dart';
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
        BlocProvider<AuthCubit>(create: (_) => di.sl<AuthCubit>()),
        BlocProvider<SearchCubit>(create: (_) => di.sl<SearchCubit>()),
        BlocProvider<UpdateCubit>(create: (_) => di.sl<UpdateCubit>()),
      ],
      child: MaterialApp(
        title: 'GoodReddit',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        home: const UpdateGate(child: SearchPage()),
      ),
    );
  }
}
