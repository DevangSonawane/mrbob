import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mrbob/core/models/geo_point.dart';
import 'package:mrbob/shared/widgets/osm_map_picker.dart';

void main() {
  testWidgets('dragging the map moves the pin to a new position', (
    tester,
  ) async {
    GeoPoint? changed;
    const start = GeoPoint(latitude: 19.0636, longitude: 72.83);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OsmMapPicker(
            point: start,
            onChanged: (point) => changed = point,
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.drag(find.byType(OsmMapPicker), const Offset(0, 120));
    await tester.pumpAndSettle();

    expect(changed, isNotNull);
    // Dragging the map down moves the view north, so the latitude grows.
    expect(changed!.latitude, greaterThan(start.latitude));
    expect(changed!.longitude, closeTo(start.longitude, 0.001));
  });

  testWidgets('a tap without a drag keeps the position', (tester) async {
    GeoPoint? changed;
    const start = GeoPoint(latitude: 19.0636, longitude: 72.83);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OsmMapPicker(
            point: start,
            onChanged: (point) => changed = point,
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byType(OsmMapPicker));
    await tester.pumpAndSettle();

    expect(changed, isNull);
  });
}
