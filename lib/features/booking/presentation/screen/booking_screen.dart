import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:makeup_booking_app/core/utils/formatters.dart';
import 'package:makeup_booking_app/features/artist/domain/entity/artist.dart';
import 'package:makeup_booking_app/features/auth/presentation/provider/auth_provider.dart';
import 'package:makeup_booking_app/utils/app_text_styles.dart';
import 'package:makeup_booking_app/utils/color_resource.dart';

import '../../domain/booking.dart';
import '../../domain/booking_quote.dart';
import '../../domain/slot_math.dart';
import '../provider/booking_provider.dart';
import '../widgets/add_on_tile.dart';
import '../widgets/booking_summary.dart';

class BookingScreen extends ConsumerStatefulWidget {
  final Artist artist;

  const BookingScreen({super.key, required this.artist});

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  ArtistService? _service;
  final Map<String, int> _addOnQuantities = {};
  late ServiceMode _mode = widget.artist.serviceModes.first;
  final _addressController = TextEditingController();
  DateTime? _date;
  DateTime? _slot;
  bool _submitting = false;

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  bool get _needsAddress => _mode == ServiceMode.home;

  /// Null until a main service is chosen.
  BookingQuote? get _quote {
    final service = _service;
    if (service == null) return null;

    return BookingQuote(
      artist: widget.artist,
      mainService: service,
      mode: _mode,
      addOns: [
        for (final addOn in widget.artist.addOns)
          SelectedAddOn(addOn, _addOnQuantities[addOn.id] ?? 0),
      ],
    );
  }

  bool get _canSubmit =>
      _quote != null &&
      _slot != null &&
      (!_needsAddress || _addressController.text.trim().isNotEmpty) &&
      !_submitting;

  /// Any change to what is booked changes how long it takes, so a time chosen
  /// earlier may no longer fit: clear it and let the customer pick again.
  void _changeBooking(VoidCallback change) {
    setState(() {
      change();
      _slot = null;
    });
  }

  Future<void> _pickDate() async {
    final today = ref.read(clockProvider)();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? today,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
    );
    if (picked != null) {
      _changeBooking(
        () => _date = DateTime(picked.year, picked.month, picked.day),
      );
    }
  }

  Future<void> _submit() async {
    final quote = _quote;
    final userId = ref.read(currentUserIdProvider);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    if (quote == null || _slot == null) return;
    if (userId == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Please log in to book.')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await ref.read(bookingRepositoryProvider).createBooking(
            BookingRequest(
              userId: userId,
              quote: quote,
              address: _needsAddress ? _addressController.text.trim() : null,
              startAt: _slot!,
            ),
          );
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Request sent to ${widget.artist.name}. '
            "You'll be notified once it's confirmed.",
          ),
        ),
      );
      navigator.popUntil((route) => route.isFirst);
    } on SlotUnavailableException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
      if (mounted) {
        setState(() => _slot = null);
        ref.invalidate(bookedSlotsProvider);
      }
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text("Couldn't send your request. Please try again."),
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final artist = widget.artist;
    final quote = _quote;

    return Scaffold(
      appBar: AppBar(title: Text('Book ${artist.name}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _Label('Select service'),
          RadioGroup<ArtistService>(
            groupValue: _service,
            onChanged: (v) => _changeBooking(() => _service = v),
            child: Column(
              children: artist.mainServices
                  .map(
                    (s) => RadioListTile<ArtistService>(
                      value: s,
                      activeColor: ColorResource.colorRoseGoldCTA,
                      contentPadding: EdgeInsets.zero,
                      title: Text(s.name,
                          style: const TextStyle(
                              color: ColorResource.colorSoftText)),
                      subtitle: Text(
                        formatDuration(s.durationMinutes),
                        style: AppTextStyles.body.copyWith(fontSize: 12),
                      ),
                      secondary: Text(
                        formatRupees(s.price),
                        style: const TextStyle(
                          color: ColorResource.colorPrimaryAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          if (artist.addOns.isNotEmpty) ...[
            const SizedBox(height: 16),
            const _Label('Add extras'),
            for (final addOn in artist.addOns)
              AddOnTile(
                addOn: addOn,
                quantity: _addOnQuantities[addOn.id] ?? 0,
                onChanged: (qty) => _changeBooking(
                  () => _addOnQuantities[addOn.id] = qty,
                ),
              ),
          ],
          if (artist.serviceModes.length > 1) ...[
            const SizedBox(height: 16),
            const _Label('Where?'),
            Wrap(
              spacing: 10,
              children: artist.serviceModes
                  .map(
                    (m) => ChoiceChip(
                      label: Text(m.label),
                      selected: _mode == m,
                      onSelected: (_) => _changeBooking(() => _mode = m),
                    ),
                  )
                  .toList(),
            ),
          ],
          if (_needsAddress) ...[
            const SizedBox(height: 16),
            const _Label('Your address'),
            TextField(
              controller: _addressController,
              onChanged: (_) => setState(() {}),
              maxLines: 2,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Where should the artist come?',
              ),
            ),
          ],
          const SizedBox(height: 16),
          const _Label('Select date'),
          OutlinedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_today_outlined, size: 18),
            label: Text(_date == null ? 'Choose date' : formatDate(_date!)),
          ),
          if (_date != null && quote != null) ...[
            const SizedBox(height: 16),
            const _Label('Select time'),
            _SlotPicker(
              artist: artist,
              quote: quote,
              day: _date!,
              selected: _slot,
              onSelected: (s) => setState(() => _slot = s),
            ),
          ] else if (_date != null) ...[
            const SizedBox(height: 16),
            Text('Choose a service to see available times.',
                style: AppTextStyles.body),
          ],
          if (quote != null && _slot != null) ...[
            const SizedBox(height: 24),
            BookingSummary(quote: quote, start: _slot!),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: _canSubmit ? _submit : null,
            child: _submitting
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : const Text('Request Booking'),
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Times the chosen service fits into the artist's day: inside working hours,
/// not on a day off, and clear of every existing booking plus the buffer.
class _SlotPicker extends ConsumerWidget {
  final Artist artist;
  final BookingQuote quote;
  final DateTime day;
  final DateTime? selected;
  final ValueChanged<DateTime> onSelected;

  const _SlotPicker({
    required this.artist,
    required this.quote,
    required this.day,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final takenAsync =
        ref.watch(bookedSlotsProvider((artistId: artist.id, day: day)));

    return takenAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => TextButton(
        onPressed: () => ref.invalidate(bookedSlotsProvider),
        child: const Text("Couldn't load availability. Retry"),
      ),
      data: (taken) {
        final starts = SlotMath.openStarts(
          day: day,
          hours: artist.workingHours,
          weeklyOffDays: artist.weeklyOffDays,
          durationMinutes: quote.durationMinutes,
          bufferMinutes: quote.bufferMinutes,
          taken: taken,
          now: ref.read(clockProvider)(),
        );

        if (starts.isEmpty) {
          return Text(
            'No times left on this day for '
            '${formatDuration(quote.durationMinutes)}. Try another date.',
            style: AppTextStyles.body,
          );
        }

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final start in starts)
              ChoiceChip(
                label: Text(formatTime(start)),
                selected: selected == start,
                onSelected: (_) => onSelected(start),
              ),
          ],
        );
      },
    );
  }
}
