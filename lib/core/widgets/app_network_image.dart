import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:makeup_booking_app/utils/color_resource.dart';

/// Network image with a neutral placeholder. Anything that is not an http(s)
/// URL (e.g. legacy asset names left in old Firestore documents) shows the
/// placeholder instead of crashing.
class AppNetworkImage extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;

  const AppNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    if (!url.startsWith('http')) return _placeholder();

    return CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: fit,
      placeholder: (_, __) => _placeholder(),
      errorWidget: (_, __, ___) => _placeholder(),
    );
  }

  Widget _placeholder() {
    return Container(
      width: width,
      height: height,
      color: ColorResource.colorCards,
      alignment: Alignment.center,
      child: Icon(
        Icons.person_outline,
        color: ColorResource.colorPrimaryAccent.withValues(alpha: 0.4),
        size: 32,
      ),
    );
  }
}
