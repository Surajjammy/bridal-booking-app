import 'package:flutter/material.dart';
import 'package:makeup_booking_app/core/utils/formatters.dart';
import 'package:makeup_booking_app/features/artist/domain/entity/artist.dart';
import 'package:makeup_booking_app/utils/app_text_styles.dart';
import 'package:makeup_booking_app/utils/color_resource.dart';

import '../../domain/booking_quote.dart';
import '../../domain/cancellation_policy.dart';

/// What the customer is about to book: each item, the time it takes, the
/// total, and the cancellation rule, all before they commit.
class BookingSummary extends StatelessWidget {
  final BookingQuote quote;
  final DateTime start;

  const BookingSummary({super.key, required this.quote, required this.start});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorResource.colorCards,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final item in quote.items) _ItemRow(item: item),
          const Divider(height: 24),
          _InfoRow(
            icon: Icons.schedule,
            text: '${formatDate(start)}, ${formatTime(start)} – '
                '${formatTime(quote.endAt(start))} '
                '(${formatDuration(quote.durationMinutes)})',
          ),
          const SizedBox(height: 6),
          _InfoRow(
            icon: quote.mode == ServiceMode.home
                ? Icons.home_outlined
                : Icons.storefront_outlined,
            text: quote.mode.label,
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total',
                  style: TextStyle(color: ColorResource.colorSoftText)),
              Text(
                formatRupees(quote.totalPrice),
                style: const TextStyle(
                  color: ColorResource.colorPrimaryAccent,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'The artist confirms your request. ${CancellationPolicy.summary}',
            style: AppTextStyles.body.copyWith(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  final BookingItem item;

  const _ItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final label = item.quantity > 1 ? '${item.name} × ${item.quantity}' : item.name;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: item.isAddOn
                  ? AppTextStyles.body
                  : AppTextStyles.artistName.copyWith(fontSize: 15),
            ),
          ),
          Text(
            formatRupees(item.totalPrice),
            style: const TextStyle(color: ColorResource.colorSoftText),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: ColorResource.colorPrimaryAccent),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: AppTextStyles.body)),
      ],
    );
  }
}
