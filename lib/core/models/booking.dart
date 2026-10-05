import 'service_item.dart';

enum BookingStatus {
  confirmed('Confirmed'),
  inService('In service'),
  completed('Completed'),
  cancelled('Cancelled');

  const BookingStatus(this.label);

  final String label;

  bool get isActive =>
      this == BookingStatus.confirmed || this == BookingStatus.inService;
}

/// How the customer wants the service fulfilled.
///
/// Used as the home-page view filter (null = show everything) and intended
/// for the booking flow: [instant] means "now" (no day/time picker),
/// [scheduled] goes through the normal slot picker.
enum BookingMode {
  instant('Instant'),
  scheduled('Scheduled');

  const BookingMode(this.label);

  final String label;
}

class Booking {
  const Booking({
    this.id = '',
    required this.service,
    required this.mode,
    required this.slot,
    required this.payment,
    required this.total,
    this.status = BookingStatus.confirmed,
  });

  /// Backend booking id (`POST /bookings` response). Empty for
  /// locally-created demo bookings.
  final String id;
  final ServiceItem service;
  final String mode;
  final String slot;
  final String payment;
  final int total;
  final BookingStatus status;

  bool get paysOnDelivery => payment == 'Pay on delivery';
}
