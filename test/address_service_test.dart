import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mrbob/core/models/api/customer_address.dart';
import 'package:mrbob/core/services/address_service.dart';
import 'package:mrbob/core/services/api_client.dart';
import 'package:mrbob/core/services/api_config.dart';

void main() {
  test('address list is parsed with the pinned position', () async {
    http.Request? captured;
    final service = AddressService(
      api: ApiClient(
        client: MockClient((request) async {
          captured = request;
          return _jsonResponse({
            'success': true,
            'data': [
              {
                'id': 'address-1',
                'label': 'HOME',
                'line1': 'A-1204, 4th Cross',
                'line2': 'Andheri West',
                'city': {'id': 'city-1', 'name': 'Mumbai'},
                'zone': {'id': 'zone-1', 'name': 'Bandra West'},
                'state': 'Maharashtra',
                'pincode': '400053',
                'latitude': 19.0636,
                'longitude': 72.83,
                'isDefault': true,
              },
            ],
          });
        }),
      ),
    );

    final addresses = await service.list();

    expect(captured?.method, 'GET');
    expect(
      captured?.url.toString(),
      '${ApiConfig.effectiveBaseUrl}/users/me/addresses',
    );
    expect(addresses, hasLength(1));
    final address = addresses.first;
    expect(address.id, 'address-1');
    expect(address.hasLocation, isTrue);
    expect(address.latitude, 19.0636);
    expect(address.longitude, 72.83);
    expect(address.isDefault, isTrue);
    expect(address.city?.name, 'Mumbai');
    expect(address.zone?.name, 'Bandra West');
    expect(address.shortLabel, 'A-1204, 4th Cross, Andheri West, Mumbai');
  });

  test('creating an address sends the map pin with it', () async {
    http.Request? captured;
    String? body;
    final service = AddressService(
      api: ApiClient(
        client: MockClient((request) async {
          captured = request;
          body = request.body;
          return _jsonResponse({
            'success': true,
            'data': {
              'id': 'address-2',
              'line1': 'A-1204, 4th Cross',
              'latitude': 19.0636,
              'longitude': 72.83,
            },
          });
        }),
      ),
    );

    final created = await service.create(
      line1: 'A-1204, 4th Cross',
      line2: 'Andheri West',
      cityId: 'city-1',
      state: 'Maharashtra',
      pincode: '400053',
      latitude: 19.0636,
      longitude: 72.83,
    );

    expect(captured?.method, 'POST');
    expect(
      captured?.url.toString(),
      '${ApiConfig.effectiveBaseUrl}/users/me/addresses',
    );
    final sent = jsonDecode(body!) as Map<String, dynamic>;
    expect(sent['cityId'], 'city-1');
    expect(sent['pincode'], '400053');
    expect(sent['latitude'], 19.0636);
    expect(sent['longitude'], 72.83);
    expect(created.id, 'address-2');
  });

  test('updating an address sends the map pin with it', () async {
    http.Request? captured;
    String? body;
    final service = AddressService(
      api: ApiClient(
        client: MockClient((request) async {
          captured = request;
          body = request.body;
          return _jsonResponse({
            'success': true,
            'data': {'id': 'address-1', 'latitude': 19.07, 'longitude': 72.84},
          });
        }),
      ),
    );

    await service.update(
      'address-1',
      line1: 'B-22, Hill Road',
      latitude: 19.07,
      longitude: 72.84,
    );

    expect(captured?.method, 'PATCH');
    expect(
      captured?.url.toString(),
      '${ApiConfig.effectiveBaseUrl}/users/me/addresses/address-1',
    );
    final sent = jsonDecode(body!) as Map<String, dynamic>;
    expect(sent['line1'], 'B-22, Hill Road');
    expect(sent['latitude'], 19.07);
    expect(sent['longitude'], 72.84);
  });

  test('an address without a position never sends a half pin', () async {
    String? body;
    final service = AddressService(
      api: ApiClient(
        client: MockClient((request) async {
          body = request.body;
          return _jsonResponse({
            'success': true,
            'data': {'id': 'address-1'},
          });
        }),
      ),
    );

    await service.update('address-1', line1: 'B-22, Hill Road');

    final sent = jsonDecode(body!) as Map<String, dynamic>;
    expect(sent.containsKey('latitude'), isFalse);
    expect(sent.containsKey('longitude'), isFalse);
  });

  test('the default address is the one marked as default', () async {
    final service = AddressService(
      api: ApiClient(
        client: MockClient(
          (_) async => _jsonResponse({
            'success': true,
            'data': [
              {'id': 'address-1', 'line1': 'First'},
              {'id': 'address-2', 'line1': 'Second', 'isDefault': true},
            ],
          }),
        ),
      ),
    );

    final address = await service.defaultAddress();

    expect(address?.id, 'address-2');
  });

  test('setting and deleting an address hit the documented routes', () async {
    final requests = <http.Request>[];
    final service = AddressService(
      api: ApiClient(
        client: MockClient((request) async {
          requests.add(request);
          return _jsonResponse({
            'success': true,
            'data': {'id': 'address-1'},
          });
        }),
      ),
    );

    await service.setDefault('address-1');
    await service.delete('address-1');

    expect(requests[0].method, 'POST');
    expect(
      requests[0].url.toString(),
      '${ApiConfig.effectiveBaseUrl}/users/me/addresses/address-1/default',
    );
    expect(requests[1].method, 'DELETE');
    expect(
      requests[1].url.toString(),
      '${ApiConfig.effectiveBaseUrl}/users/me/addresses/address-1',
    );
  });

  test('an address model keeps the position out of the body when unset', () {
    const address = CustomerAddress(
      id: 'address-1',
      line1: 'A-1204, 4th Cross',
      state: 'Maharashtra',
      pincode: '400053',
    );

    expect(address.hasLocation, isFalse);
    final body = address.toRequestBody();
    expect(body.containsKey('latitude'), isFalse);
    expect(body.containsKey('longitude'), isFalse);
  });
}

http.Response _jsonResponse(Map<String, dynamic> body, {int status = 200}) {
  return http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json'},
  );
}
