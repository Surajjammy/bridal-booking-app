import 'package:flutter/material.dart';
import 'package:makeup_booking_app/core/utils/formatters.dart';
import 'package:makeup_booking_app/features/artist/domain/entity/artist.dart';
import 'package:makeup_booking_app/utils/color_resource.dart';

/// One add-on the customer can include. A single-use add-on is a checkbox; one
/// that can be repeated (extra family members) gets a quantity stepper.
class AddOnTile extends StatelessWidget {
  final ArtistService addOn;
  final int quantity;
  final ValueChanged<int> onChanged;

  const AddOnTile({
    super.key,
    required this.addOn,
    required this.quantity,
    required this.onChanged,
  });

  bool get _repeatable => addOn.maxQuantity > 1;

  @override
  Widget build(BuildContext context) {
    final selected = quantity > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: ColorResource.colorCards,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected
              ? ColorResource.colorRoseGoldCTA
              : ColorResource.colorPrimaryAccent.withValues(alpha: 0.2),
        ),
      ),
      // The whole row toggles a single-use add-on, not just the small
      // checkbox. A repeatable one is changed with its stepper instead.
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: _repeatable ? null : () => onChanged(selected ? 0 : 1),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: _content(selected),
        ),
      ),
    );
  }

  Widget _content(bool selected) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                addOn.name,
                style: const TextStyle(
                  color: ColorResource.colorSoftText,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '+${formatDuration(addOn.durationMinutes)} · '
                '+${formatRupees(addOn.price)}'
                '${_repeatable ? ' each' : ''}',
                style: TextStyle(
                  color: ColorResource.colorSoftText.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        if (_repeatable)
          _Stepper(
            quantity: quantity,
            max: addOn.maxQuantity,
            onChanged: onChanged,
          )
        else
          Checkbox(
            value: selected,
            activeColor: ColorResource.colorRoseGoldCTA,
            onChanged: (value) => onChanged(value == true ? 1 : 0),
          ),
      ],
    );
  }
}

class _Stepper extends StatelessWidget {
  final int quantity;
  final int max;
  final ValueChanged<int> onChanged;

  const _Stepper({
    required this.quantity,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Remove one',
          onPressed: quantity > 0 ? () => onChanged(quantity - 1) : null,
          icon: const Icon(Icons.remove_circle_outline),
          color: ColorResource.colorPrimaryAccent,
        ),
        SizedBox(
          width: 22,
          child: Text(
            '$quantity',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white),
          ),
        ),
        IconButton(
          tooltip: 'Add one',
          onPressed: quantity < max ? () => onChanged(quantity + 1) : null,
          icon: const Icon(Icons.add_circle_outline),
          color: ColorResource.colorPrimaryAccent,
        ),
      ],
    );
  }
}
