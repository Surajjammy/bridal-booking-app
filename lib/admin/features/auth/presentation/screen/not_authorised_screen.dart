import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/admin_colors.dart';
import '../provider/admin_auth_provider.dart';

/// Shown to someone who signed in successfully but is not on the admins list.
class NotAuthorisedScreen extends ConsumerWidget {
  const NotAuthorisedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final email = ref.watch(adminUserProvider).value?.email ?? '';

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline,
                    size: 44, color: AdminColors.primary),
                const SizedBox(height: 16),
                Text('Not authorised', style: text.headlineSmall),
                const SizedBox(height: 8),
                Text(
                  '$email is not an administrator of this panel. '
                  'Ask an existing admin to add you.',
                  textAlign: TextAlign.center,
                  style: text.bodyMedium?.copyWith(
                    color: AdminColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                OutlinedButton(
                  onPressed: () =>
                      ref.read(adminAuthRepositoryProvider).signOut(),
                  child: const Text('Sign out'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
