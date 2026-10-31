import 'package:flutter/material.dart';
import 'package:makeup_booking_app/features/booking/domain/booking.dart';

import '../theme/admin_colors.dart';

/// Small coloured label for a status. Always carries text, so meaning never
/// depends on colour alone.
class StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const StatusPill({super.key, required this.label, required this.color});

  factory StatusPill.active(bool isActive) => StatusPill(
        label: isActive ? 'Active' : 'Inactive',
        color: isActive ? AdminColors.success : AdminColors.neutral,
      );

  factory StatusPill.booking(BookingStatus status) => switch (status) {
        BookingStatus.requested =>
          const StatusPill(label: 'Requested', color: AdminColors.warning),
        BookingStatus.confirmed =>
          const StatusPill(label: 'Confirmed', color: AdminColors.success),
        BookingStatus.declined =>
          const StatusPill(label: 'Declined', color: AdminColors.danger),
        BookingStatus.cancelled =>
          const StatusPill(label: 'Cancelled', color: AdminColors.danger),
        BookingStatus.completed =>
          const StatusPill(label: 'Completed', color: AdminColors.neutral),
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
