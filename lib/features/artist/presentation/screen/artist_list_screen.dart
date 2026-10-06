import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:makeup_booking_app/core/utils/formatters.dart';
import 'package:makeup_booking_app/core/widgets/app_network_image.dart';
import 'package:makeup_booking_app/core/widgets/async_states.dart';
import 'package:makeup_booking_app/utils/app_text_styles.dart';
import 'package:makeup_booking_app/utils/color_resource.dart';

import '../../domain/entity/artist.dart';
import '../provider/artist_provider.dart';
import 'artist_detail_screen.dart';

class ArtistListScreen extends ConsumerWidget {
  const ArtistListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artistsAsync = ref.watch(artistsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Makeup Artists')),
      body: artistsAsync.when(
        data: (artists) {
          if (artists.isEmpty) {
            return const EmptyState(message: 'No artists available yet.');
          }
          return RefreshIndicator(
            onRefresh: () => ref.refresh(artistsProvider.future),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: artists.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) =>
                  _ArtistCard(artist: artists[index]),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => ErrorRetry(
          onRetry: () => ref.invalidate(artistsProvider),
        ),
      ),
    );
  }
}

class _ArtistCard extends StatelessWidget {
  final Artist artist;
  const _ArtistCard({required this.artist});

  @override
  Widget build(BuildContext context) {
    final from = artist.startingPrice;

    return Material(
      color: ColorResource.colorCards,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ArtistDetailScreen(artist: artist),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AppNetworkImage(
                  url: artist.imageUrl,
                  width: 76,
                  height: 76,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      artist.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.artistName,
                    ),
                    if (artist.city.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          artist.city,
                          style: AppTextStyles.body.copyWith(
                            color: ColorResource.colorSoftText
                                .withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 16, color: ColorResource.colorPrimaryAccent),
                        const SizedBox(width: 4),
                        Text(
                          artist.reviewCount > 0
                              ? '${artist.rating.toStringAsFixed(1)} (${artist.reviewCount})'
                              : artist.rating > 0
                                  ? artist.rating.toStringAsFixed(1)
                                  : 'New',
                          style: const TextStyle(
                            color: ColorResource.colorPrimaryAccent,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (from != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'From',
                      style: AppTextStyles.body.copyWith(
                        fontSize: 11,
                        color:
                            ColorResource.colorSoftText.withValues(alpha: 0.6),
                      ),
                    ),
                    Text(
                      formatRupees(from),
                      style: const TextStyle(
                        color: ColorResource.colorSoftText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
