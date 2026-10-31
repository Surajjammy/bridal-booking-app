import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:makeup_booking_app/features/booking/presentation/screen/my_bookings_screen.dart';
import 'package:makeup_booking_app/utils/app_text_styles.dart';
import 'package:makeup_booking_app/utils/color_resource.dart';

import '../provider/auth_provider.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phone = ref.watch(authStateProvider).value?.phoneNumber ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('My account')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ColorResource.colorCards,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.phone_iphone,
                    color: ColorResource.colorPrimaryAccent),
                const SizedBox(width: 12),
                Text(phone, style: AppTextStyles.artistName),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            tileColor: ColorResource.colorCards,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            leading: const Icon(Icons.event_note_outlined,
                color: ColorResource.colorPrimaryAccent),
            title: const Text('My bookings',
                style: TextStyle(color: ColorResource.colorSoftText)),
            trailing: const Icon(Icons.chevron_right,
                color: ColorResource.colorSoftText),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyBookingsScreen()),
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            tileColor: ColorResource.colorCards,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('Log out',
                style: TextStyle(color: ColorResource.colorSoftText)),
            onTap: () async {
              final navigator = Navigator.of(context);
              await ref.read(authRepositoryProvider).signOut();
              navigator.pop();
            },
          ),
        ],
      ),
    );
  }
}
