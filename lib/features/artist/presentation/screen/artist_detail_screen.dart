import 'package:flutter/material.dart';
import 'package:makeup_booking_app/features/booking/presentation/screen/booking_screen.dart';
import 'package:makeup_booking_app/features/portfolio/data/portfolio_model.dart';
import 'package:makeup_booking_app/features/portfolio/domain/portfolio_entity.dart';
import 'package:makeup_booking_app/utils/app_text_styles.dart';
import 'package:makeup_booking_app/utils/color_resource.dart';
import '../../domain/entity/artist.dart';

class ArtistDetailScreen extends StatelessWidget {
  final Artist artist;

  const ArtistDetailScreen({super.key, required this.artist});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorResource.colorBg,
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
          child: Icon(
            Icons.chevron_left,
            color: Colors.white,
          ),
        ),
        title: Text(
          artist.name,
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
        ),
        backgroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🔥 Big Image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                  child: Image.asset(
                    "assets/images/${artist.image}.jpg",
                    width: double.infinity,
                    height: 320,
                    fit: BoxFit.cover,
                  ),
                ),
                Container(
                  height: 320,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.8),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            /// 🔥 Name
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                artist.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 8),

            /// 🔥 Price + Rating
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "₹${artist.price}",
                    style: const TextStyle(
                      color: ColorResource.colorPrimaryAccent,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    "⭐ ${artist.rating}",
                    style: const TextStyle(
                        color: ColorResource.colorPrimaryAccent),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// 🔥 Services title
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "Services",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 10),

            /// 🔥 Services list
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _ServicesList(artist.services),
            ),

            SizedBox(height: 20),
            _RecentWorks(artist.portfolio ?? []),

            const SizedBox(height: 30),

            /// 🔥 Book Now Button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorResource.colorRoseGoldCTA,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BookingScreen(artist: artist),
                      ),
                    );
                  },
                  child: const Text("Book Now", style: AppTextStyles.button),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Recent works sections
class _RecentWorks extends StatelessWidget {
  final List<PortfolioEntity> portfolio;
  const _RecentWorks(this.portfolio);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const Text(
            "Recent Works",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 4,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.8,
              ),
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    /// Open Portfolio Screen
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          "assets/images/${portfolio[index].image}.png",
                          fit: BoxFit.cover,
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.7),
                              ],
                            ),
                          ),
                        ),
                        if (index == 3)
                          Container(
                            color: Colors.black.withOpacity(0.5),
                            child: const Center(
                              child: Text(
                                "+12",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ServicesList extends StatelessWidget {
  final List<String> services;
  const _ServicesList(this.services);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: services.map((service) {
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: ColorResource.colorCards,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: ColorResource.colorPrimaryAccent.withOpacity(0.2),
            ),
          ),
          child: Text(
            service,
            style: const TextStyle(
              color: ColorResource.colorSoftText,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
    );
  }
}
