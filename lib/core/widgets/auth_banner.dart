import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goodreddit/features/auth/presentation/bloc/auth_cubit.dart';

/// Slim banner shown only while browsing anonymously, inviting sign-in.
/// Hidden entirely once authenticated (no "signed in as…" noise).
class AuthBanner extends StatelessWidget {
  final VoidCallback onSignIn;
  const AuthBanner({super.key, required this.onSignIn});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      buildWhen: (a, b) => a.isAuthenticated != b.isAuthenticated,
      builder: (context, state) {
        if (state.isAuthenticated) return const SizedBox.shrink();
        return MaterialBanner(
          content: const Text(
            'Navigation anonyme. Connectez-vous pour votre fil personnalisé.',
          ),
          leading: const Icon(Icons.info_outline),
          actions: [
            TextButton(onPressed: onSignIn, child: const Text('SE CONNECTER')),
          ],
        );
      },
    );
  }
}
