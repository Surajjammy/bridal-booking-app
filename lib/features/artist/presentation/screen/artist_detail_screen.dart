import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:makeup_booking_app/core/utils/formatters.dart';
import 'package:makeup_booking_app/core/widgets/app_network_image.dart';
import 'package:makeup_booking_app/features/auth/presentation/auth_guard.dart';
import 'package:makeup_booking_app/features/booking/presentation/screen/booking_screen.dart';
import 'package:makeup_booking_app/features/portfolio/presentation/portfolio_screen.dart';
import 'package:makeup_booking_app/utils/app_text_styles.dart';
import 'package:makeup_booking_app/utils/color_resource.dart';

import '../../domain/entity/artist.dart';
import '../provider/artist_provider.dart';

class ArtistDetailScreen extends ConsumerWidget {
  final Artist artist;

  const ArtistDetailScreen({super.key, required this.artist});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final portfolioAsync = ref.watch(portfolioProvider(artist.id));

    return Scaffold(
      appBar: AppBar(title: Text(artist.name)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(30),
                  ),
                  child: AppNetworkImage(
                    url: artist.imageUrl,
                    width: double.infinity,
                    height: 320,
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(30),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.8),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    artist.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 18, color: ColorResource.colorPrimaryAccent),
                      const SizedBox(width: 4),
                      Text(
                        artist.reviewCount > 0
                            ? '${artist.rating.toStringAsFixed(1)} · ${artist.reviewCount} reviews'
                            : 'New on the platform',
                        style: const TextStyle(
                            color: ColorResource.colorPrimaryAccent),
                      ),
                      if (artist.city.isNotEmpty) ...[
                        const SizedBox(width: 12),
                        const Icon(Icons.location_on_outlined,
                            size: 16, color: ColorResource.colorSoftText),
                        const SizedBox(width: 2),
                        Text(artist.city, style: AppTextStyles.body),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: artist.serviceModes
                        .map((m) => Chip(label: Text(m.label)))
                        .toList(),
                  ),
                  if (artist.bio.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(artist.bio, style: AppTextStyles.body),
                  ],
                  const SizedBox(height: 24),
                  const _SectionTitle('Services'),
                  const SizedBox(height: 10),
                  if (artist.services.isEmpty)
                    Text('Services coming soon.', style: AppTextStyles.body)
                  else
                    ...artist.services.map(_ServiceTile.new),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const _SectionTitle('Portfolio'),
                      if ((portfolioAsync.value?.length ?? 0) > 0)
                        TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  PortfolioScreen(artistId: artist.id),
                            ),
                          ),
                          child: const Text('See all'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  portfolioAsync.when(
                    data: (items) => items.isEmpty
                        ? Text('No work added yet.', style: AppTextStyles.body)
                        : SizedBox(
                            height: 150,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: items.length > 6 ? 6 : items.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 10),
                              itemBuilder: (context, i) => ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: AppNetworkImage(
                                  url: items[i].imageUrl,
                                  width: 120,
                                  height: 150,
                                ),
                              ),
                            ),
                          ),
                    loading: () => const SizedBox(
                      height: 150,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (_, __) => TextButton(
                      onPressed: () =>
                          ref.invalidate(portfolioProvider(artist.id)),
                      child: const Text("Couldn't load portfolio. Retry"),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: artist.services.isEmpty
                ? null
                : () async {
                    final navigator = Navigator.of(context);
                    if (!await ensureLoggedIn(context, ref)) return;
                    navigator.push(
                      MaterialPageRoute(
                        builder: (_) => BookingScreen(artist: artist),
                      ),
                    );
                  },
            child: const Text('Book Now'),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  final ArtistService service;
  const _ServiceTile(this.service);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ColorResource.colorCards,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: ColorResource.colorPrimaryAccent.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.name,
                  style: const TextStyle(
                    color: ColorResource.colorSoftText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${service.durationMinutes ~/ 60}h ${service.durationMinutes % 60}m'
                      .replaceAll(' 0m', ''),
                  style: AppTextStyles.body.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            formatRupees(service.price),
            style: const TextStyle(
              color: ColorResource.colorPrimaryAccent,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
