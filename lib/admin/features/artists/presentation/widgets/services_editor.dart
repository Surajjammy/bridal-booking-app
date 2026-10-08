import 'package:flutter/material.dart';
import 'package:makeup_booking_app/features/artist/domain/entity/artist.dart';

import '../../../../core/theme/admin_colors.dart';
import '../../../../core/utils/validators.dart';

/// Text controllers for one editable service row.
class ServiceRowControllers {
  /// Kept stable across edits: bookings refer to a service by this id.
  final String id;
  final TextEditingController name;
  final TextEditingController price;
  final TextEditingController duration;

  ServiceRowControllers._(this.id, String name, String price, String duration)
      : name = TextEditingController(text: name),
        price = TextEditingController(text: price),
        duration = TextEditingController(text: duration);

  // Disambiguates rows created within the same clock tick.
  static int _sequence = 0;

  factory ServiceRowControllers.empty() => ServiceRowControllers._(
        '${DateTime.now().microsecondsSinceEpoch}_${_sequence++}',
        '',
        '',
        '120',
      );

  factory ServiceRowControllers.fromService(ArtistService service) =>
      ServiceRowControllers._(
        service.id,
        service.name,
        service.price == service.price.roundToDouble()
            ? service.price.toInt().toString()
            : service.price.toString(),
        service.durationMinutes.toString(),
      );

  ArtistService toService() => ArtistService(
        id: id,
        name: name.text.trim(),
        price: double.parse(price.text.trim()),
        durationMinutes: int.parse(duration.text.trim()),
      );

  void dispose() {
    name.dispose();
    price.dispose();
    duration.dispose();
  }
}

/// Owns the list of service rows. The form creates it, reads
/// [toServices] on save, and disposes it.
class ServicesEditorController extends ChangeNotifier {
  final List<ServiceRowControllers> _rows;

  ServicesEditorController(List<ArtistService> initial)
      : _rows = initial.map(ServiceRowControllers.fromService).toList();

  List<ServiceRowControllers> get rows => List.unmodifiable(_rows);

  bool get isEmpty => _rows.isEmpty;

  void add() {
    _rows.add(ServiceRowControllers.empty());
    notifyListeners();
  }

  void remove(ServiceRowControllers row) {
    if (_rows.remove(row)) {
      row.dispose();
      notifyListeners();
    }
  }

  /// Call only after the form validated every row.
  List<ArtistService> toServices() => _rows.map((r) => r.toService()).toList();

  @override
  void dispose() {
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }
}

class ServicesEditor extends StatelessWidget {
  final ServicesEditorController controller;
  final String? errorText;

  const ServicesEditor({
    super.key,
    required this.controller,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final row in controller.rows)
              Padding(
                key: ValueKey(row.id),
                padding: const EdgeInsets.only(bottom: 12),
                child: _ServiceRow(
                  row: row,
                  onRemove: () => controller.remove(row),
                ),
              ),
            if (errorText != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  errorText!,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AdminColors.danger),
                ),
              ),
            OutlinedButton.icon(
              onPressed: controller.add,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add service'),
            ),
          ],
        );
      },
    );
  }
}

class _ServiceRow extends StatelessWidget {
  static const double _wideBreakpoint = 640;

  final ServiceRowControllers row;
  final VoidCallback onRemove;

  const _ServiceRow({required this.row, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final nameField = TextFormField(
      controller: row.name,
      validator: (v) =>
          Validators.required(v, 'Service name') ?? Validators.maxLength(v, 80),
      decoration: const InputDecoration(
        labelText: 'Service',
        hintText: 'e.g. Bridal makeup',
      ),
    );
    final priceField = TextFormField(
      controller: row.price,
      validator: (v) => Validators.number(v, min: 1, max: 1000000),
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(labelText: 'Price', prefixText: '₹ '),
    );
    final durationField = TextFormField(
      controller: row.duration,
      validator: (v) =>
          Validators.number(v, min: 15, max: 720) ??
          (int.tryParse(v!.trim()) == null ? 'Whole minutes only' : null),
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: 'Duration',
        suffixText: 'min',
      ),
    );
    final removeButton = IconButton(
      tooltip: 'Remove service',
      onPressed: onRemove,
      icon: const Icon(Icons.delete_outline, color: AdminColors.danger),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= _wideBreakpoint) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 4, child: nameField),
              const SizedBox(width: 12),
              Expanded(flex: 2, child: priceField),
              const SizedBox(width: 12),
              Expanded(flex: 2, child: durationField),
              const SizedBox(width: 4),
              removeButton,
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            nameField,
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: priceField),
                const SizedBox(width: 12),
                Expanded(child: durationField),
                removeButton,
              ],
            ),
          ],
        );
      },
    );
  }
}
