import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mrbob/core/models/api/nearby_vendors.dart';
import 'package:mrbob/core/services/api_client.dart';
import 'package:mrbob/core/services/api_config.dart';
import 'package:mrbob/core/services/nearby_vendors_service.dart';

void main() {
  test('nearby vendors queries the customer endpoint with the position', () async {
    http.Request? captured;
    final service = NearbyVendorsService(
      api: ApiClient(
        client: MockClient((request) async {
          captured = request;
          return _jsonResponse({
            'success': true,
            'data': {
              'vendorsNearby': 6,
              'nearestKm': 0.8,
              'etaMinutes': 12,
              'radiusKm': 5,
              'areas': [
                {
                  'cell': '87608b0b1ffffff',
                  'center': [19.061, 72.832],
                  'boundary': [
                    [19.07, 72.82],
                    [19.05, 72.84],
                  ],
                  'vendors': 4,
                },
              ],
            },
          });
        }),
      ),
    );

    final nearby = await service.nearby(
      latitude: 19.0622,
      longitude: 72.8315,
      categoryId: 'category-1',
    );

    expect(captured?.method, 'GET');
    final url = captured!.url;
    expect(
      '${url.origin}${url.path}',
      '${ApiConfig.effectiveBaseUrl}/customer/nearby-vendors',
    );
    expect(url.queryParameters['latitude'], '19.0622');
    expect(url.queryParameters['longitude'], '72.8315');
    expect(url.queryParameters['categoryId'], 'category-1');

    expect(nearby.vendorsNearby, 6);
    expect(nearby.nearestKm, 0.8);
    expect(nearby.etaMinutes, 12);
    expect(nearby.radiusKm, 5);
    expect(nearby.hasVendors, isTrue);
    expect(nearby.etaLabel, '12 min');
    expect(nearby.distanceLabel, '800 m away');
    expect(nearby.areas, hasLength(1));
    expect(nearby.areas.first.cell, '87608b0b1ffffff');
    expect(nearby.areas.first.vendors, 4);
    expect(nearby.areas.first.center?.latitude, 19.061);
    expect(nearby.areas.first.center?.longitude, 72.832);
    expect(nearby.areas.first.boundary, hasLength(2));
  });

  test('nearby vendors omits the position when there is none', () async {
    http.Request? captured;
    final service = NearbyVendorsService(
      api: ApiClient(
        client: MockClient((request) async {
          captured = request;
          return _jsonResponse({
            'success': true,
            'data': {'vendorsNearby': 0, 'radiusKm': 5},
          });
        }),
      ),
    );

    final nearby = await service.nearby();

    expect(captured?.url.queryParameters.containsKey('latitude'), isFalse);
    expect(captured?.url.queryParameters.containsKey('categoryId'), isFalse);
    expect(nearby.vendorsNearby, 0);
    expect(nearby.hasVendors, isFalse);
    expect(nearby.etaLabel, isNull);
    expect(nearby.distanceLabel, isNull);
  });

  test('nearby vendors survives a response without the data envelope', () async {
    final service = NearbyVendorsService(
      api: ApiClient(client: MockClient((_) async => _jsonResponse({}))),
    );

    final nearby = await service.nearby(latitude: 19.0, longitude: 72.8);

    expect(nearby.vendorsNearby, 0);
    expect(nearby.areas, isEmpty);
  });

  test('nearby vendors labels long arrival times in hours', () {
    const nearby = NearbyVendors(
      vendorsNearby: 3,
      etaMinutes: 95,
      nearestKm: 0.25,
    );

    expect(nearby.etaLabel, '1 hr 35 min');
    expect(nearby.distanceLabel, '250 m away');
  });
}

http.Response _jsonResponse(Map<String, dynamic> body, {int status = 200}) {
  return http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json'},
  );
}
