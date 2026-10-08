import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:makeup_booking_app/core/utils/formatters.dart';
import 'package:makeup_booking_app/core/widgets/app_network_image.dart';
import 'package:makeup_booking_app/core/widgets/async_states.dart';
import 'package:makeup_booking_app/features/artist/domain/entity/artist.dart';

import '../../../../app/admin_routes.dart';
import '../../../../core/theme/admin_colors.dart';
import '../../../../core/widgets/page_header.dart';
import '../../../../core/widgets/status_pill.dart';
import '../provider/admin_artist_providers.dart';

class ArtistsListScreen extends ConsumerWidget {
  const ArtistsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artistsAsync = ref.watch(filteredAdminArtistsProvider);
    final total = ref.watch(adminArtistsProvider).value?.length;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'Artists',
            subtitle: total == null ? null : '$total in total',
            actions: [
              FilledButton.icon(
                onPressed: () => context.push(AdminRoutes.newArtist),
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Add artist'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: TextField(
              onChanged: ref.read(artistSearchQueryProvider.notifier).update,
              decoration: const InputDecoration(
                hintText: 'Search by name or city',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: artistsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => ErrorRetry(
                onRetry: () => ref.invalidate(adminArtistsProvider),
              ),
              data: (artists) => artists.isEmpty
                  ? EmptyState(
                      message: ref.watch(artistSearchQueryProvider).isEmpty
                          ? 'No artists yet. Add the first one.'
                          : 'No artists match your search.',
                    )
                  : _ArtistTable(artists: artists),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArtistTable extends StatelessWidget {
  final List<Artist> artists;

  const _ArtistTable({required this.artists});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      // Rows are built lazily, so the list stays fast with hundreds of artists.
      child: ListView.separated(
        itemCount: artists.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) => _ArtistRow(artist: artists[index]),
      ),
    );
  }
}

class _ArtistRow extends ConsumerWidget {
  static const double _wideBreakpoint = 720;

  final Artist artist;

  const _ArtistRow({required this.artist});

  Future<void> _toggle(BuildContext context, WidgetRef ref, bool value) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await ref
        .read(artistAdminControllerProvider.notifier)
        .setActive(artist.id, isActive: value);
    if (!ok) {
      messenger.showSnackBar(
        const SnackBar(content: Text("Couldn't update. Please try again.")),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final from = artist.startingPrice;

    return InkWell(
      onTap: () => context.push(AdminRoutes.editArtist(artist.id)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= _wideBreakpoint;

            return Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: AppNetworkImage(
                    url: artist.imageUrl,
                    width: 48,
                    height: 48,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        artist.name.isEmpty ? '(no name)' : artist.name,
                        overflow: TextOverflow.ellipsis,
                        style: text.titleMedium,
                      ),
                      Text(
                        artist.city.isEmpty ? 'No city set' : artist.city,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (wide) ...[
                  Expanded(
                    flex: 2,
                    child: Text(
                      from == null ? 'No services' : 'From ${formatRupees(from)}',
                      style: text.bodyMedium?.copyWith(
                        color: AdminColors.textSecondary,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: StatusPill.active(artist.isActive),
                    ),
                  ),
                ],
                Tooltip(
                  message: artist.isActive
                      ? 'Hide from customers'
                      : 'Show to customers',
                  child: Switch(
                    value: artist.isActive,
                    onChanged: (value) => _toggle(context, ref, value),
                  ),
                ),
                const Icon(Icons.chevron_right,
                    color: AdminColors.textSecondary),
              ],
            );
          },
        ),
      ),
    );
  }
}
