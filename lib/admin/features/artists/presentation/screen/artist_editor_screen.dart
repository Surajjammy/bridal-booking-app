import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:makeup_booking_app/core/widgets/async_states.dart';

import '../provider/admin_artist_providers.dart';
import '../widgets/artist_form.dart';

/// Add a new artist (no [artistId]) or edit an existing one.
class ArtistEditorScreen extends ConsumerWidget {
  final String? artistId;

  const ArtistEditorScreen({super.key, this.artistId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = artistId;
    if (id == null) return const ArtistForm();

    final dataAsync = ref.watch(artistEditorDataProvider(id));

    return dataAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => ErrorRetry(
        onRetry: () => ref.invalidate(artistEditorDataProvider(id)),
      ),
      data: (data) => data == null
          ? const EmptyState(message: 'This artist no longer exists.')
          : ArtistForm(key: ValueKey(id), initial: data),
    );
  }
}
