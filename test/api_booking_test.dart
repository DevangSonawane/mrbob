import 'package:flutter_test/flutter_test.dart';
import 'package:mrbob/core/models/api/api_booking.dart';

void main() {
  test('parseBookingList reads paginated bookings envelope', () {
    final bookings = parseBookingList({
      'success': true,
      'items': [
        {
          'id': 'booking-1',
          'status': 'PENDING',
          'service': {
            'id': 'category-1',
            'name': 'Electrician',
            'tier': 'REPAIR',
          },
          'scheduledAt': '2026-10-12T10:00:00.000Z',
          'price': 299,
          'address': {'line': 'Andheri West, Mumbai'},
          'payment': {'mode': 'PAY_AFTER_SERVICE', 'status': 'UNPAID'},
        },
      ],
      'meta': {'page': 1, 'limit': 20, 'total': 1, 'totalPages': 1},
    });

    expect(bookings, hasLength(1));
    expect(bookings.first.id, 'booking-1');
    expect(bookings.first.categoryId, 'category-1');
    expect(bookings.first.category?.name, 'Electrician');
    expect(bookings.first.totalAmount, 299);
    expect(bookings.first.address, 'Andheri West, Mumbai');
    expect(bookings.first.paymentStatus, 'UNPAID');
  });
}
