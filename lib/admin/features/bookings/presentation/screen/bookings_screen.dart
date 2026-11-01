import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:makeup_booking_app/core/widgets/async_states.dart';

import '../../../../core/widgets/page_header.dart';
import '../../domain/booking_filter.dart';
import '../provider/admin_booking_providers.dart';
import '../widgets/booking_card.dart';

class BookingsScreen extends ConsumerWidget {
  const BookingsScreen({super.key});

  static String _emptyMessage(BookingFilter filter, bool searching) {
    if (searching) return 'No bookings match your search.';
    return switch (filter) {
      BookingFilter.needsAction => 'No requests waiting for a decision.',
      BookingFilter.upcoming => 'No upcoming bookings.',
      BookingFilter.past => 'No past bookings yet.',
      BookingFilter.closed => 'No declined or cancelled bookings.',
      BookingFilter.all => 'No bookings yet.',
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(bookingFilterProvider);
    final counts = ref.watch(bookingCountsProvider);
    final bookingsAsync = ref.watch(visibleBookingsProvider);
    final searching = ref.watch(bookingSearchQueryProvider).trim().isNotEmpty;
    final waiting = counts[BookingFilter.needsAction] ?? 0;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'Bookings',
            subtitle: waiting == 0
                ? 'Nothing is waiting for a decision'
                : '$waiting waiting for a decision',
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in BookingFilter.values)
                ChoiceChip(
                  label: Text('${option.label} (${counts[option] ?? 0})'),
                  selected: option == filter,
                  onSelected: (_) =>
                      ref.read(bookingFilterProvider.notifier).select(option),
                ),
            ],
          ),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: TextField(
              onChanged: ref.read(bookingSearchQueryProvider.notifier).update,
              decoration: const InputDecoration(
                hintText: 'Search by artist or service',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: bookingsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => ErrorRetry(
                onRetry: () => ref.invalidate(adminBookingsProvider),
              ),
              data: (bookings) {
                if (bookings.isEmpty) {
                  return EmptyState(
                    message: _emptyMessage(filter, searching),
                    icon: Icons.event_available_outlined,
                  );
                }
                return ListView.separated(
                  itemCount: bookings.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) =>
                      BookingCard(booking: bookings[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
