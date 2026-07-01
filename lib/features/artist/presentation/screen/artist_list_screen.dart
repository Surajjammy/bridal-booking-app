import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:makeup_booking_app/features/artist/presentation/screen/artist_detail_screen.dart';
import 'package:makeup_booking_app/utils/app_text_styles.dart';
import 'package:makeup_booking_app/utils/color_resource.dart';

import '../provider/artist_provider.dart';

class ArtistListScreen extends ConsumerWidget {
  const ArtistListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artistsAsync = ref.watch(artistProvider);

    return Scaffold(
      backgroundColor: ColorResource.colorBg,
      appBar: AppBar(
        title: const Text(
          "Makeup Artists",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: Colors.black,
      ),
      body: artistsAsync.when(
        data: (artists) {
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: artists.length,
            itemBuilder: (context, index) {
              final artist = artists[index];

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: ColorResource.colorCards,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(10),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      "assets/images/${artist.image}.jpg",
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  ),
                  title: Text(
                    artist.name,
                    style: AppTextStyles.artistName,
                  ),
                  subtitle: Text(
                    "₹${artist.price}",
                    style: const TextStyle(color: ColorResource.colorSoftText),
                  ),
                  trailing: Text(
                    "⭐ ${artist.rating}",
                    style: const TextStyle(
                        color: ColorResource.colorPrimaryAccent),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ArtistDetailScreen(artist: artist),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: Colors.green),
        ),
        error: (e, _) => Center(
          child: Text(
            "Something went wrong",
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}
