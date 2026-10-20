import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mrbob/core/models/geo_point.dart';
import 'package:mrbob/core/services/address_service.dart';
import 'package:mrbob/core/services/api_client.dart';
import 'package:mrbob/core/services/nearby_vendors_service.dart';
import 'package:mrbob/features/booking/presentation/widgets/vendors_nearby_card.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  NearbyVendorsService serviceWith(Map<String, dynamic> data) {
    return NearbyVendorsService(
      api: ApiClient(
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({'success': true, 'data': data}),
            200,
            headers: {'content-type': 'application/json'},
          ),
        ),
      ),
    );
  }

  testWidgets('shows the nearby count and the arrival estimate', (tester) async {
    await tester.pumpWidget(
      wrap(
        VendorsNearbyCard(
          categoryId: 'category-1',
          point: const GeoPoint(latitude: 19.0622, longitude: 72.8315),
          nearbyService: serviceWith({
            'vendorsNearby': 6,
            'nearestKm': 0.8,
            'etaMinutes': 12,
            'radiusKm': 5,
          }),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('6 vendors nearby'), findsOneWidget);
    expect(find.text('About 12 min · 800 m away'), findsOneWidget);
  });

  testWidgets('says the vendors are busy when nobody is around', (tester) async {
    await tester.pumpWidget(
      wrap(
        VendorsNearbyCard(
          point: const GeoPoint(latitude: 19.0622, longitude: 72.8315),
          nearbyService: serviceWith({'vendorsNearby': 0, 'radiusKm': 5}),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Vendors are busy right now'), findsOneWidget);
    expect(
      find.text("We'll find one for you — place the booking anyway."),
      findsOneWidget,
    );
  });

  testWidgets('hides itself when the position is unknown', (tester) async {
    await tester.pumpWidget(
      wrap(
        VendorsNearbyCard(
          nearbyService: serviceWith({'vendorsNearby': 0}),
          addressService: AddressService(
            api: ApiClient(
              client: MockClient(
                (_) async => http.Response(
                  jsonEncode({'success': true, 'data': <dynamic>[]}),
                  200,
                  headers: {'content-type': 'application/json'},
                ),
              ),
            ),
          ),
        ),
      ),
    );
    // The saved address has no position and the device has none in the
    // test environment, so the card collapses instead of guessing.
    await tester.pump(const Duration(seconds: 9));
    await tester.pump();
    expect(find.text('Vendors are busy right now'), findsNothing);
    expect(find.text('Checking professionals near you…'), findsNothing);
  });
}
