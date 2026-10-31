import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:makeup_booking_app/core/providers/clock_provider.dart';
import 'package:makeup_booking_app/core/utils/formatters.dart';
import 'package:makeup_booking_app/features/artist/domain/entity/artist.dart';
import 'package:makeup_booking_app/features/booking/domain/booking.dart';
import 'package:makeup_booking_app/features/booking/domain/booking_transitions.dart';

import '../../../../core/theme/admin_colors.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/status_pill.dart';
import '../provider/admin_booking_providers.dart';

/// One booking: the facts an admin needs to decide, and the actions that are
/// valid right now.
class BookingCard extends ConsumerWidget {
  static const double _wideBreakpoint = 760;

  final Booking booking;

  const BookingCard({super.key, required this.booking});

  Future<void> _change(
    BuildContext context,
    WidgetRef ref,
    BookingStatus to,
  ) async {
    final messenger = ScaffoldMessenger.of(context);

    if (BookingTransitions.freesCalendar(to)) {
      final confirmed = await showConfirmDialog(
        context,
        title: to == BookingStatus.declined
            ? 'Decline this request?'
            : 'Cancel this booking?',
        message: "This frees ${booking.artistName}'s time on "
            '${formatDate(booking.startAt)}, ${formatTime(booking.startAt)} – '
            '${formatTime(booking.blockedUntil)}, so someone else can book it. '
            'The customer will see it as ${to.name} in their bookings.',
        confirmLabel: to == BookingStatus.declined ? 'Decline' : 'Cancel booking',
        destructive: true,
      );
      if (!confirmed || !context.mounted) return;
    }

    final ok = await ref
        .read(bookingAdminControllerProvider.notifier)
        .changeStatus(booking, to);

    final error = ref.read(bookingAdminControllerProvider).error;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Booking ${_pastTense(to)}'
              : error is Exception
                  ? error.toString()
                  : "Couldn't update the booking. Please try again.",
        ),
      ),
    );
  }

  static String _pastTense(BookingStatus status) => switch (status) {
        BookingStatus.confirmed => 'confirmed',
        BookingStatus.declined => 'declined',
        BookingStatus.cancelled => 'cancelled',
        BookingStatus.completed => 'marked as completed',
        BookingStatus.requested => 'updated',
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider)();
    final busy = ref.watch(bookingAdminControllerProvider).isLoading;
    final actions = BookingTransitions.adminActions(booking, now);

    final details = _Details(booking: booking);
    final buttons = _Actions(
      actions: actions,
      busy: busy,
      onPressed: (to) => _change(context, ref, to),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= _wideBreakpoint) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: details),
                  if (actions.isNotEmpty) ...[
                    const SizedBox(width: 24),
                    SizedBox(width: 170, child: buttons),
                  ],
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                details,
                if (actions.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  buttons,
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Details extends ConsumerWidget {
  final Booking booking;

  const _Details({required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final phone = ref.watch(customerPhoneProvider(booking.userId));
    final isHome = booking.mode == ServiceMode.home;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                booking.artistName,
                overflow: TextOverflow.ellipsis,
                style: text.titleMedium,
              ),
            ),
            const SizedBox(width: 10),
            StatusPill.booking(booking.status),
          ],
        ),
        const SizedBox(height: 2),
        Text(booking.serviceName, style: text.bodyMedium),
        const SizedBox(height: 12),
        _Line(
          icon: Icons.schedule,
          text: '${formatDate(booking.startAt)} · '
              '${formatTime(booking.startAt)} – ${formatTime(booking.endAt)}',
        ),
        _Line(
          icon: isHome ? Icons.home_outlined : Icons.storefront_outlined,
          text: isHome && (booking.address ?? '').isNotEmpty
              ? '${booking.mode.label} · ${booking.address}'
              : booking.mode.label,
        ),
        _Line(
          icon: Icons.person_outline,
          text: phone.when(
            data: (value) => value ?? 'Customer phone not available',
            loading: () => 'Loading customer…',
            error: (_, __) => 'Customer phone not available',
          ),
        ),
        _Line(
          icon: Icons.payments_outlined,
          text: '${formatRupees(booking.amount)} · platform '
              '${formatRupees(booking.commission)} '
              '(${formatPercent(booking.commissionRate)})',
        ),
        if (booking.createdAt != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'Requested ${formatDateTime(booking.createdAt!)}',
              style: text.bodySmall,
            ),
          ),
      ],
    );
  }
}

class _Line extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Line({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AdminColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  final List<BookingStatus> actions;
  final bool busy;
  final ValueChanged<BookingStatus> onPressed;

  const _Actions({
    required this.actions,
    required this.busy,
    required this.onPressed,
  });

  String _label(BookingStatus status) => switch (status) {
        BookingStatus.confirmed => 'Confirm',
        BookingStatus.declined => 'Decline',
        BookingStatus.cancelled => 'Cancel booking',
        BookingStatus.completed => 'Mark completed',
        BookingStatus.requested => '',
      };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final action in actions)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: action == BookingStatus.confirmed
                ? FilledButton(
                    onPressed: busy ? null : () => onPressed(action),
                    child: Text(_label(action)),
                  )
                : OutlinedButton(
                    style: BookingTransitions.freesCalendar(action)
                        ? OutlinedButton.styleFrom(
                            foregroundColor: AdminColors.danger,
                          )
                        : null,
                    onPressed: busy ? null : () => onPressed(action),
                    child: Text(_label(action)),
                  ),
          ),
      ],
    );
  }
}
