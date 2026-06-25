import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goodreddit/core/util/format.dart';
import 'package:goodreddit/core/util/vote_math.dart';
import 'package:goodreddit/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:goodreddit/features/interactions/domain/entities/post_interaction.dart';
import 'package:goodreddit/features/interactions/presentation/bloc/interactions_cubit.dart';

/// Up/down vote + save controls, bound to the shared interactions store by
/// [fullname]. Only this widget rebuilds when the post's vote/save state
/// changes — not the surrounding card or header. Falls back to [baseScore] /
/// neutral until the store has seeded an entry.
class VoteControls extends StatelessWidget {
  final String fullname;
  final int baseScore;
  final bool scoreHidden;
  final VoidCallback onNeedsAuth;
  final bool compact;

  const VoteControls({
    super.key,
    required this.fullname,
    required this.baseScore,
    required this.onNeedsAuth,
    this.scoreHidden = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final size = compact ? 18.0 : 22.0;

    return BlocSelector<InteractionsCubit, InteractionsState, PostInteraction?>(
      selector: (s) => s.postFor(fullname),
      builder: (context, pi) {
        final dir = pi?.voteDir ?? VoteDir.none;
        final saved = pi?.saved ?? false;
        final hidden = pi?.scoreHidden ?? scoreHidden;
        final score = pi?.displayScore ?? baseScore;

        // Pre-check auth so an anonymous tap opens login without an optimistic
        // flash; only fire the write when signed in.
        void act(void Function(InteractionsCubit c) run) {
          if (context.read<AuthCubit>().state.status !=
              AuthStatus.authenticated) {
            onNeedsAuth();
            return;
          }
          run(context.read<InteractionsCubit>());
        }

        final scoreColor = switch (dir) {
          VoteDir.up => theme.colorScheme.primary,
          VoteDir.down => theme.colorScheme.tertiary,
          VoteDir.none => null,
        };

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _IconBtn(
              icon: Icons.arrow_upward,
              size: size,
              color: dir == VoteDir.up ? theme.colorScheme.primary : muted,
              tooltip: 'Voter pour',
              onTap: () => act((c) => c.toggleVote(fullname, VoteDir.up)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text(
                hidden ? '•' : compactCount(score),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scoreColor,
                  fontWeight: dir == VoteDir.none ? null : FontWeight.w600,
                ),
              ),
            ),
            _IconBtn(
              icon: Icons.arrow_downward,
              size: size,
              color: dir == VoteDir.down ? theme.colorScheme.tertiary : muted,
              tooltip: 'Voter contre',
              onTap: () => act((c) => c.toggleVote(fullname, VoteDir.down)),
            ),
            SizedBox(width: compact ? 8 : 14),
            _IconBtn(
              icon: saved ? Icons.bookmark : Icons.bookmark_border,
              size: size,
              color: saved ? theme.colorScheme.primary : muted,
              tooltip: saved ? 'Retirer des enregistrés' : 'Enregistrer',
              onTap: () => act((c) => c.toggleSaved(fullname)),
            ),
          ],
        );
      },
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color? color;
  final String tooltip;
  final VoidCallback onTap;

  const _IconBtn({
    required this.icon,
    required this.size,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: size + 8,
      child: Tooltip(
        message: tooltip,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: size, color: color),
        ),
      ),
    );
  }
}
