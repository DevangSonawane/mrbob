import 'service_item.dart';

class Booking {
  const Booking({
    required this.service,
    required this.mode,
    required this.slot,
    required this.payment,
    required this.total,
  });

  final ServiceItem service;
  final String mode;
  final String slot;
  final String payment;
  final int total;
}
