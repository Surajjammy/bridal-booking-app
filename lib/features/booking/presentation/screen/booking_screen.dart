import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:makeup_booking_app/core/config/app_config.dart';
import 'package:makeup_booking_app/core/utils/formatters.dart';
import 'package:makeup_booking_app/features/artist/domain/entity/artist.dart';
import 'package:makeup_booking_app/utils/app_text_styles.dart';
import 'package:makeup_booking_app/utils/color_resource.dart';

import '../../domain/booking.dart';
import '../provider/booking_provider.dart';

class BookingScreen extends ConsumerStatefulWidget {
  final Artist artist;

  const BookingScreen({super.key, required this.artist});

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  ArtistService? _service;
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

  bool get _canSubmit =>
      _service != null &&
      _slot != null &&
      (!_needsAddress || _addressController.text.trim().isNotEmpty) &&
      !_submitting;

  Future<void> _pickDate() async {
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? today,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _date = DateTime(picked.year, picked.month, picked.day);
        _slot = null;
      });
    }
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      await ref.read(bookingRepositoryProvider).createBooking(
            BookingRequest(
              userId: ref.read(currentUserIdProvider),
              artist: widget.artist,
              service: _service!,
              mode: _mode,
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

    return Scaffold(
      appBar: AppBar(title: Text('Book ${artist.name}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _Label('Select service'),
          RadioGroup<ArtistService>(
            groupValue: _service,
            onChanged: (v) => setState(() => _service = v),
            child: Column(
              children: artist.services
                  .map(
                    (s) => RadioListTile<ArtistService>(
                      value: s,
                      activeColor: ColorResource.colorRoseGoldCTA,
                      contentPadding: EdgeInsets.zero,
                      title: Text(s.name,
                          style: const TextStyle(
                              color: ColorResource.colorSoftText)),
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
                      onSelected: (_) => setState(() => _mode = m),
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
          if (_date != null) ...[
            const SizedBox(height: 16),
            const _Label('Select time'),
            _SlotPicker(
              artistId: artist.id,
              day: _date!,
              selected: _slot,
              onSelected: (s) => setState(() => _slot = s),
            ),
          ],
          if (_service != null && _slot != null) ...[
            const SizedBox(height: 24),
            _Summary(
              service: _service!,
              slot: _slot!,
              mode: _mode,
            ),
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

class _SlotPicker extends ConsumerWidget {
  final String artistId;
  final DateTime day;
  final DateTime? selected;
  final ValueChanged<DateTime> onSelected;

  const _SlotPicker({
    required this.artistId,
    required this.day,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookedAsync =
        ref.watch(bookedSlotsProvider((artistId: artistId, day: day)));

    return bookedAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => TextButton(
        onPressed: () => ref.invalidate(bookedSlotsProvider),
        child: const Text("Couldn't load availability. Retry"),
      ),
      data: (booked) {
        final now = DateTime.now();
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: AppConfig.defaultSlotHours.map((hour) {
            final start = DateTime(day.year, day.month, day.day, hour);
            final unavailable = booked.contains(start) || start.isBefore(now);
            return ChoiceChip(
              label: Text(formatTime(start)),
              selected: selected == start,
              onSelected: unavailable ? null : (_) => onSelected(start),
            );
          }).toList(),
        );
      },
    );
  }
}

class _Summary extends StatelessWidget {
  final ArtistService service;
  final DateTime slot;
  final ServiceMode mode;

  const _Summary({
    required this.service,
    required this.slot,
    required this.mode,
  });

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
          Text(service.name, style: AppTextStyles.artistName),
          const SizedBox(height: 4),
          Text(
            '${formatDate(slot)} · ${formatTime(slot)} · ${mode.label}',
            style: AppTextStyles.body,
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total',
                  style: TextStyle(color: ColorResource.colorSoftText)),
              Text(
                formatRupees(service.price),
                style: const TextStyle(
                  color: ColorResource.colorPrimaryAccent,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'The artist confirms your request. Payment will be added soon.',
            style: AppTextStyles.body.copyWith(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
