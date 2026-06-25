import 'package:flutter/material.dart';

/// Persistent, actionable error state (never a raw exception). Offers
/// "Se connecter" when the failure is an auth problem, otherwise "Réessayer".
class ReaderErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final bool needsAuth;
  final VoidCallback? onSignIn;

  const ReaderErrorView({
    super.key,
    required this.message,
    required this.onRetry,
    this.needsAuth = false,
    this.onSignIn,
  });

  @override
  Widget build(BuildContext context) {
    final showSignIn = needsAuth && onSignIn != null;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              needsAuth ? Icons.lock_outline : Icons.cloud_off,
              size: 40,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            if (showSignIn)
              FilledButton.icon(
                onPressed: onSignIn,
                icon: const Icon(Icons.login),
                label: const Text('Se connecter'),
              )
            else
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
          ],
        ),
      ),
    );
  }
}

/// Friendly empty state: icon + title + optional subtitle.
class ReaderEmptyView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  const ReaderEmptyView({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: muted),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: muted),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
