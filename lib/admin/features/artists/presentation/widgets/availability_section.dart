import 'package:flutter/material.dart';
import 'package:makeup_booking_app/core/utils/formatters.dart';
import 'package:makeup_booking_app/features/artist/domain/entity/artist.dart';

import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/section_card.dart';

/// Working hours, days off and buffers for one artist. The form creates it,
/// reads the values on save, and disposes it.
class AvailabilityController extends ChangeNotifier {
  /// Opening and closing times are chosen in half-hour steps, matching the
  /// customer calendar.
  static const int stepMinutes = 30;
  static const int _midnight = 24 * 60;

  late int startMinute;
  late int endMinute;
  final Set<int> offDays;
  final TextEditingController buffer;
  final TextEditingController travelBuffer;

  /// Pass null for a new artist to start from the defaults.
  AvailabilityController([Artist? artist])
      : offDays = {...?artist?.weeklyOffDays},
        buffer = TextEditingController(
          text: '${artist?.bufferMinutes ?? Artist.defaultBufferMinutes}',
        ),
        travelBuffer = TextEditingController(
          text: '${artist?.travelBufferMinutes ?? Artist.defaultTravelBufferMinutes}',
        ) {
    final hours = artist?.workingHours ?? WorkingHours.standard;
    startMinute = _snap(hours.startMinute);
    endMinute = _snap(hours.endMinute);
  }

  static int _snap(int minute) => (minute ~/ stepMinutes) * stepMinutes;

  WorkingHours get workingHours =>
      WorkingHours(startMinute: startMinute, endMinute: endMinute);

  int get bufferMinutes => int.parse(buffer.text.trim());
  int get travelBufferMinutes => int.parse(travelBuffer.text.trim());

  void setStart(int minute) {
    startMinute = minute;
    notifyListeners();
  }

  void setEnd(int minute) {
    endMinute = minute;
    notifyListeners();
  }

  void toggleOffDay(int weekday, {required bool off}) {
    off ? offDays.add(weekday) : offDays.remove(weekday);
    notifyListeners();
  }

  /// Every half hour from midnight, for the opening-time dropdown.
  static List<int> get startOptions =>
      [for (var m = 0; m < _midnight; m += stepMinutes) m];

  /// Every half hour after midnight, up to and including the next midnight.
  static List<int> get endOptions =>
      [for (var m = stepMinutes; m <= _midnight; m += stepMinutes) m];

  static String label(int minute) =>
      minute == _midnight ? 'Midnight' : formatMinuteOfDay(minute);

  @override
  void dispose() {
    buffer.dispose();
    travelBuffer.dispose();
    super.dispose();
  }
}

class AvailabilitySection extends StatelessWidget {
  static const _weekdays = {
    DateTime.monday: 'Mon',
    DateTime.tuesday: 'Tue',
    DateTime.wednesday: 'Wed',
    DateTime.thursday: 'Thu',
    DateTime.friday: 'Fri',
    DateTime.saturday: 'Sat',
    DateTime.sunday: 'Sun',
  };

  final AvailabilityController controller;

  /// Lays two fields side by side on wide screens and stacks them on narrow
  /// ones. Supplied by the form so every section wraps the same way.
  final Widget Function(Widget left, Widget right) twoColumns;

  const AvailabilitySection({
    super.key,
    required this.controller,
    required this.twoColumns,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Availability',
      description: 'When customers can book this artist. Add-ons and long '
          'services are fitted into these hours automatically.',
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              twoColumns(
                DropdownButtonFormField<int>(
                  initialValue: controller.startMinute,
                  decoration: const InputDecoration(labelText: 'Opens'),
                  items: _timeItems(AvailabilityController.startOptions),
                  onChanged: (v) => controller.setStart(v!),
                ),
                DropdownButtonFormField<int>(
                  initialValue: controller.endMinute,
                  decoration: const InputDecoration(labelText: 'Closes'),
                  items: _timeItems(AvailabilityController.endOptions),
                  onChanged: (v) => controller.setEnd(v!),
                  validator: (v) => v! <= controller.startMinute
                      ? 'Must be after opening time'
                      : null,
                ),
              ),
              const SizedBox(height: 20),
              Text('Days off', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final entry in _weekdays.entries)
                    FilterChip(
                      label: Text(entry.value),
                      selected: controller.offDays.contains(entry.key),
                      onSelected: (off) =>
                          controller.toggleOffDay(entry.key, off: off),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              twoColumns(
                TextFormField(
                  controller: controller.buffer,
                  validator: _validateBuffer,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Gap after a studio booking',
                    suffixText: 'min',
                    helperText: 'Absorbs small overruns',
                  ),
                ),
                TextFormField(
                  controller: controller.travelBuffer,
                  validator: _validateBuffer,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Gap after a home visit',
                    suffixText: 'min',
                    helperText: 'Includes travel',
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<DropdownMenuItem<int>> _timeItems(List<int> minutes) => [
        for (final m in minutes)
          DropdownMenuItem(value: m, child: Text(AvailabilityController.label(m))),
      ];

  static String? _validateBuffer(String? value) =>
      Validators.number(value, min: 0, max: 240) ??
      (int.tryParse(value!.trim()) == null ? 'Whole minutes only' : null);
}
