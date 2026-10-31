import 'package:makeup_booking_app/features/artist/domain/entity/artist.dart';

import 'slot_math.dart';

/// An add-on the customer chose, with how many.
class SelectedAddOn {
  final ArtistService service;
  final int quantity;

  const SelectedAddOn(this.service, this.quantity);
}

/// One line of a booking: the main service or an add-on.
class BookingItem {
  final String serviceId;
  final String name;
  final double price;
  final int durationMinutes;
  final int quantity;
  final bool isAddOn;

  const BookingItem({
    required this.serviceId,
    required this.name,
    required this.price,
    required this.durationMinutes,
    required this.quantity,
    required this.isAddOn,
  });

  double get totalPrice => price * quantity;
  int get totalMinutes => durationMinutes * quantity;
}

/// What a customer is about to book: how long it takes, what it costs, and
/// how much of the artist's day it blocks. Pure, so the booking screen, the
/// repository and the tests all agree on the numbers.
class BookingQuote {
  final Artist artist;
  final ArtistService mainService;
  final List<SelectedAddOn> addOns;
  final ServiceMode mode;

  const BookingQuote({
    required this.artist,
    required this.mainService,
    required this.mode,
    this.addOns = const [],
  });

  List<BookingItem> get items => [
        BookingItem(
          serviceId: mainService.id,
          name: mainService.name,
          price: mainService.price,
          durationMinutes: mainService.durationMinutes,
          quantity: 1,
          isAddOn: false,
        ),
        for (final addOn in addOns.where((a) => a.quantity > 0))
          BookingItem(
            serviceId: addOn.service.id,
            name: addOn.service.name,
            price: addOn.service.price,
            durationMinutes: addOn.service.durationMinutes,
            quantity: addOn.quantity,
            isAddOn: true,
          ),
      ];

  /// How long the customer is in the chair.
  int get durationMinutes => items.fold(0, (sum, i) => sum + i.totalMinutes);

  double get totalPrice => items.fold(0.0, (sum, i) => sum + i.totalPrice);

  /// Time the artist keeps free afterwards (travel for a home visit).
  int get bufferMinutes => artist.bufferFor(mode);

  int get blockedMinutes => durationMinutes + bufferMinutes;

  DateTime endAt(DateTime start) =>
      start.add(Duration(minutes: durationMinutes));

  DateTime blockedUntil(DateTime start) =>
      SlotMath.blockedUntil(start, blockedMinutes);

  /// Short label for lists: "Bridal makeup + 2 add-ons".
  String get summary {
    final count = items.where((i) => i.isAddOn).length;
    if (count == 0) return mainService.name;
    return '${mainService.name} + $count add-on${count == 1 ? '' : 's'}';
  }
}
