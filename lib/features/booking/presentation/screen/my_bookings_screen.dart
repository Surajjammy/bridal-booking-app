import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:makeup_booking_app/core/utils/formatters.dart';
import 'package:makeup_booking_app/core/widgets/async_states.dart';
import 'package:makeup_booking_app/utils/app_text_styles.dart';
import 'package:makeup_booking_app/utils/color_resource.dart';

import '../../domain/booking.dart';
import '../provider/booking_provider.dart';

class MyBookingsScreen extends ConsumerWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(userBookingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My bookings')),
      body: bookingsAsync.when(
        data: (bookings) {
          if (bookings.isEmpty) {
            return const EmptyState(
              message: "You haven't booked anyone yet.",
              icon: Icons.event_note_outlined,
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: bookings.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) => _BookingCard(booking: bookings[i]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => ErrorRetry(
          onRetry: () => ref.invalidate(userBookingsProvider),
        ),
      ),
    );
  }
}

class _BookingCard extends ConsumerWidget {
  final Booking booking;
  const _BookingCard({required this.booking});

  Color get _statusColor => switch (booking.status) {
        BookingStatus.confirmed || BookingStatus.completed => Colors.green,
        BookingStatus.requested => ColorResource.colorPrimaryAccent,
        BookingStatus.declined || BookingStatus.cancelled => Colors.redAccent,
      };

  String get _statusLabel => switch (booking.status) {
        BookingStatus.requested => 'Awaiting confirmation',
        BookingStatus.confirmed => 'Confirmed',
        BookingStatus.declined => 'Declined',
        BookingStatus.cancelled => 'Cancelled',
        BookingStatus.completed => 'Completed',
      };

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel this booking?'),
        content: Text(
          '${booking.serviceName} with ${booking.artistName} on '
          '${formatDate(booking.startAt)}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel booking'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(bookingRepositoryProvider).cancelBooking(booking);
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text("Couldn't cancel. Please try again.")),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorResource.colorCards,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(booking.artistName, style: AppTextStyles.artistName),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _statusLabel,
                  style: TextStyle(color: _statusColor, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(booking.serviceName, style: AppTextStyles.body),
          const SizedBox(height: 4),
          Text(
            '${formatDate(booking.startAt)} · ${formatTime(booking.startAt)} · '
            '${booking.mode.label}',
            style: AppTextStyles.body,
          ),
          if (booking.address != null && booking.address!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(booking.address!, style: AppTextStyles.body),
            ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formatRupees(booking.amount),
                style: const TextStyle(
                  color: ColorResource.colorPrimaryAccent,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (booking.canCancel)
                TextButton(
                  onPressed: () => _cancel(context, ref),
                  child: const Text('Cancel'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
