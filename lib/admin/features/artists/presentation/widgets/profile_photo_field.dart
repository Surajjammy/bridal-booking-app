import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:makeup_booking_app/core/widgets/app_network_image.dart';

import '../../../../core/domain/picked_image.dart';
import '../../../../core/theme/admin_colors.dart';
import '../provider/admin_artist_providers.dart';

/// Shows the current or newly picked profile photo and lets the admin
/// replace it.
class ProfilePhotoField extends ConsumerWidget {
  static const double _size = 160;

  final String existingUrl;
  final PickedImage? picked;
  final ValueChanged<PickedImage> onPicked;
  final String? errorText;

  const ProfilePhotoField({
    super.key,
    required this.existingUrl,
    required this.picked,
    required this.onPicked,
    this.errorText,
  });

  Future<void> _pick(WidgetRef ref) async {
    final image = await ref.read(imagePickerServiceProvider).pickOne();
    if (image != null) onPicked(image);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasPhoto = picked != null || existingUrl.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            width: _size,
            height: _size,
            child: picked != null
                ? Image.memory(picked!.bytes, fit: BoxFit.cover)
                : AppNetworkImage(url: existingUrl),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => _pick(ref),
          icon: const Icon(Icons.photo_camera_outlined, size: 18),
          label: Text(hasPhoto ? 'Replace photo' : 'Choose photo'),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              errorText!,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AdminColors.danger),
            ),
          ),
      ],
    );
  }
}
