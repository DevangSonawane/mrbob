import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mrbob/core/services/api_client.dart';
import 'package:mrbob/core/services/api_config.dart';
import 'package:mrbob/core/services/booking_service.dart';
import 'package:mrbob/core/services/user_service.dart';

void main() {
  test('UserService fetches customer profile', () async {
    http.Request? captured;
    final service = UserService(
      api: ApiClient(
        client: MockClient((request) async {
          captured = request;
          return _jsonResponse({
            'success': true,
            'data': {
              'id': 'customer-1',
              'name': 'Aarav',
              'phone': '+919999999999',
            },
          });
        }),
      ),
    );

    final user = await service.getProfile();

    expect(captured?.method, 'GET');
    expect(
      captured?.url.toString(),
      '${ApiConfig.effectiveBaseUrl}/customer/profile',
    );
    expect(user.id, 'customer-1');
    expect(user.name, 'Aarav');
  });

  test('UserService patches customer profile', () async {
    http.Request? captured;
    String? body;
    final service = UserService(
      api: ApiClient(
        client: MockClient((request) async {
          captured = request;
          body = request.body;
          return _jsonResponse({
            'success': true,
            'data': {
              'id': 'customer-1',
              'name': 'Aarav Updated',
              'address': 'Andheri West',
            },
          });
        }),
      ),
    );

    final user = await service.updateMe(
      name: 'Aarav Updated',
      address: 'Andheri West',
    );

    expect(captured?.method, 'PATCH');
    expect(
      captured?.url.toString(),
      '${ApiConfig.effectiveBaseUrl}/customer/profile',
    );
    expect(jsonDecode(body!), {
      'name': 'Aarav Updated',
      'address': 'Andheri West',
    });
    expect(user.name, 'Aarav Updated');
  });

  test('UserService deletes customer profile', () async {
    http.Request? captured;
    final service = UserService(
      api: ApiClient(
        client: MockClient((request) async {
          captured = request;
          return _jsonResponse({'success': true, 'data': null});
        }),
      ),
    );

    await service.deleteAccount();

    expect(captured?.method, 'DELETE');
    expect(
      captured?.url.toString(),
      '${ApiConfig.effectiveBaseUrl}/customer/profile',
    );
  });

  test('BookingService lists customer bookings', () async {
    http.Request? captured;
    final service = BookingService(
      api: ApiClient(
        client: MockClient((request) async {
          captured = request;
          return _jsonResponse({
            'success': true,
            'data': {
              'items': [
                {'id': 'booking-1', 'status': 'PENDING'},
              ],
            },
          });
        }),
      ),
    );

    final bookings = await service.list();

    expect(captured?.method, 'GET');
    expect(
      captured?.url.toString(),
      '${ApiConfig.effectiveBaseUrl}/customer/bookings',
    );
    expect(bookings.single.id, 'booking-1');
  });

  test('BookingService fetches customer booking details', () async {
    http.Request? captured;
    final service = BookingService(
      api: ApiClient(
        client: MockClient((request) async {
          captured = request;
          return _jsonResponse({
            'success': true,
            'data': {'id': 'booking-1', 'status': 'COMPLETED'},
          });
        }),
      ),
    );

    final booking = await service.getById('booking-1');

    expect(captured?.method, 'GET');
    expect(
      captured?.url.toString(),
      '${ApiConfig.effectiveBaseUrl}/customer/bookings/booking-1',
    );
    expect(booking.id, 'booking-1');
  });
}

http.Response _jsonResponse(Map<String, dynamic> body, {int status = 200}) {
  return http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json'},
  );
}
