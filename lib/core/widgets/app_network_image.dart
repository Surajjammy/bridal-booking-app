import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

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
    if (!url.startsWith('http')) return _Placeholder(width, height);

    return CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: fit,
      placeholder: (_, __) => _Placeholder(width, height),
      errorWidget: (_, __, ___) => _Placeholder(width, height),
    );
  }
}

class _Placeholder extends StatelessWidget {
  final double? width;
  final double? height;

  const _Placeholder(this.width, this.height);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: width,
      height: height,
      color: scheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(
        Icons.person_outline,
        color: scheme.onSurface.withValues(alpha: 0.35),
        size: 32,
      ),
    );
  }
}
