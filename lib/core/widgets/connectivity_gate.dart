import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';

import '../providers/connectivity_provider.dart';

/// Puts a "No internet" screen over the whole app while the device is offline.
///
/// The app underneath is only covered, never replaced, so the current screen,
/// scroll position and anything typed are exactly as they were when the
/// connection comes back.
class ConnectivityGate extends ConsumerWidget {
  final Widget child;

  const ConnectivityGate({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Treat "not known yet" as online so start-up never flashes the screen.
    final online = ref.watch(isOnlineProvider).value ?? true;

    return Stack(
      children: [
        child,
        Positioned.fill(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: online
                ? const SizedBox.shrink(key: ValueKey('online'))
                : _OfflineScreen(
                    key: const ValueKey('offline'),
                    onRetry: () => ref.invalidate(isOnlineProvider),
                  ),
          ),
        ),
      ],
    );
  }
}

class _OfflineScreen extends StatelessWidget {
  final VoidCallback onRetry;

  const _OfflineScreen({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final animate = !MediaQuery.of(context).disableAnimations;

    // Material supplies the opaque backdrop and text style, and swallows taps
    // so nothing underneath can be used while offline.
    return Material(
      color: theme.scaffoldBackgroundColor,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Lottie.asset(
                  'assets/animations/no_internet.json',
                  width: 220,
                  height: 220,
                  animate: animate,
                  repeat: true,
                ),
                const SizedBox(height: 8),
                Text(
                  'No internet connection',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  "Check your Wi-Fi or mobile data. We'll take you right back "
                  "to where you were as soon as you're online.",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                OutlinedButton(
                  onPressed: onRetry,
                  child: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
