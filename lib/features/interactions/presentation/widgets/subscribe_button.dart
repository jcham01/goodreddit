import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goodreddit/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:goodreddit/features/interactions/domain/entities/sub_interaction.dart';
import 'package:goodreddit/features/interactions/presentation/bloc/interactions_cubit.dart';

/// Join / Joined toggle for a subreddit, bound to the shared store by [srName].
/// Renders nothing until the store has a baseline (seeded by SubredditCubit),
/// shows a spinner while the write is in flight, and reverts on failure.
class SubscribeButton extends StatelessWidget {
  final String srName;
  final VoidCallback onNeedsAuth;

  const SubscribeButton({
    super.key,
    required this.srName,
    required this.onNeedsAuth,
  });

  @override
  Widget build(BuildContext context) {
    return BlocSelector<InteractionsCubit, InteractionsState, SubInteraction?>(
      selector: (s) => s.subFor(srName),
      builder: (context, si) {
        if (si == null) return const SizedBox.shrink();

        void toggle() {
          if (context.read<AuthCubit>().state.status !=
              AuthStatus.authenticated) {
            onNeedsAuth();
            return;
          }
          context.read<InteractionsCubit>().toggleSubscribed(srName);
        }

        final onPressed = si.pending ? null : toggle;
        final child = si.pending
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(si.subscribed ? 'Abonné' : 'S\'abonner');

        return si.subscribed
            ? OutlinedButton(onPressed: onPressed, child: child)
            : FilledButton(onPressed: onPressed, child: child);
      },
    );
  }
}
