import '../models/api/api_booking.dart';
import '../models/booking.dart';
import 'services_data.dart';

/// Maps a backend booking (`GET /bookings`) onto the local
/// display model the existing UI renders.
///
/// The backend category name is matched against the local
/// service catalog (exact, then fuzzy) so icons, prices and
/// durations keep rendering; unmatched bookings fall back to
/// the first catalog entry.
Booking mapApiBooking(ApiBooking api) {
  final categoryName = api.category?.name ?? '';
  final normalized = categoryName.toLowerCase();
  final service = services.firstWhere(
    (s) => s.title.toLowerCase() == normalized,
    orElse: () {
      if (normalized.isEmpty) return services.first;
      final fuzzy = services.where(
        (s) =>
            s.title.toLowerCase().contains(normalized) ||
            normalized.contains(s.title.toLowerCase()),
      );
      return fuzzy.isNotEmpty ? fuzzy.first : services.first;
    },
  );

  final scheduledAt = api.scheduledAt;
  final isInstant = scheduledAt == null;

  return Booking(
    id: api.id,
    service: service,
    mode: isInstant ? 'Instant' : 'Scheduled',
    slot: isInstant ? 'ASAP, 20 min' : _formatSlot(scheduledAt),
    payment: api.paymentStatus != null ? 'Pay now' : 'Pay on delivery',
    total: api.totalAmount?.toInt() ?? service.price,
    status: _mapStatus(api.status),
  );
}

BookingStatus _mapStatus(ApiBookingStatus status) {
  return switch (status) {
    ApiBookingStatus.completed => BookingStatus.completed,
    ApiBookingStatus.cancelled => BookingStatus.cancelled,
    ApiBookingStatus.pending ||
    ApiBookingStatus.matching ||
    ApiBookingStatus.assigned ||
    ApiBookingStatus.inProgress =>
      BookingStatus.inService,
  };
}

/// 'Today, 4:30 PM' style label from a scheduled date-time.
String _formatSlot(DateTime dt) {
  final now = DateTime.now();
  final isToday =
      dt.year == now.year && dt.month == now.month && dt.day == now.day;
  final isTomorrow =
      dt.year == now.year &&
      dt.month == now.month &&
      dt.day == now.day + 1;
  final dayLabel =
      isToday ? 'Today' : isTomorrow ? 'Tomorrow' : '${dt.day}/${dt.month}';
  final hour = dt.hour;
  final period = hour >= 12 ? 'PM' : 'AM';
  final h12 = hour % 12 == 0 ? 12 : hour % 12;
  return '$dayLabel, $h12:${dt.minute.toString().padLeft(2, '0')} $period';
}
