import 'package:flutter/material.dart';

/// Shared by the customer app and the admin panel, so colours come from the
/// active [Theme] instead of being hardcoded for one of them.
class ErrorRetry extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ErrorRetry({
    super.key,
    this.message = "We couldn't load this. Please try again.",
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return _CenteredMessage(
      icon: Icons.cloud_off_outlined,
      message: message,
      action: OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
    );
  }
}

class EmptyState extends StatelessWidget {
  final String message;
  final IconData icon;

  const EmptyState({
    super.key,
    required this.message,
    this.icon = Icons.search_off_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return _CenteredMessage(icon: icon, message: message);
  }
}

class _CenteredMessage extends StatelessWidget {
  final IconData icon;
  final String message;
  final Widget? action;

  const _CenteredMessage({
    required this.icon,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: scheme.secondary, size: 40),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurface),
            ),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}
