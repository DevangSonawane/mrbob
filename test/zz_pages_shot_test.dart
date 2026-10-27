import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mrbob/core/data/services_data.dart';
import 'package:mrbob/core/models/booking.dart';
import 'package:mrbob/features/bookings/presentation/pages/bookings_page.dart';
import 'package:mrbob/features/bookings/presentation/pages/booking_detail_page.dart';
import 'package:mrbob/features/home/presentation/pages/all_services_page.dart';

Future<void> load(String family, List<String> files) async {
  final l = FontLoader(family);
  for (final f in files) {
    l.addFont(Future.value(ByteData.sublistView(File(f).readAsBytesSync())));
  }
  await l.load();
}

final bookings = [
  Booking(
    id: 'a1b2c3d4e5',
    service: services[1],
    mode: 'Instant',
    slot: 'Today, 4:30 PM',
    payment: 'Pay now',
    total: 498,
    status: BookingStatus.inService,
  ),
  Booking(
    service: services[2],
    mode: 'Scheduled',
    slot: 'Tomorrow, 11:00 AM',
    payment: 'Pay on delivery',
    total: 648,
    status: BookingStatus.confirmed,
  ),
  Booking(
    id: 'x',
    service: services[3],
    mode: 'Scheduled',
    slot: '12 Oct, 2:00 PM',
    payment: 'Pay now',
    total: 748,
    status: BookingStatus.completed,
  ),
  Booking(
    id: 'y',
    service: services[4],
    mode: 'Scheduled',
    slot: '2 Oct, 5:00 PM',
    payment: 'Pay now',
    total: 599,
    status: BookingStatus.completed,
    customerRating: 4,
  ),
  Booking(
    service: services[6],
    mode: 'Scheduled',
    slot: '28 Sep, 10:00 AM',
    payment: 'Pay now',
    total: 829,
    status: BookingStatus.cancelled,
  ),
];

Future<void> shot(
  WidgetTester tester,
  Widget page,
  String name, {
  double h = 844,
}) async {
  tester.view.physicalSize = Size(1170, h * 3);
  tester.view.devicePixelRatio = 3;
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Roboto'),
      home: page,
    ),
  );
  await tester.pump();
  debugPrint('SHOT $name built');
  for (var i = 0; i < 4; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 250)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump(const Duration(seconds: 2));
  debugPrint('SHOT $name golden');
  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile(
      '/private/tmp/claude-501/-Users-devangsonawane-ZingIT/f0910cb6-37b7-4610-95dc-f88c02938db9/scratchpad/p_$name.png',
    ),
  );
  debugPrint('SHOT $name done');
  expect(tester.takeException(), isNull);
}

void main() {
  testWidgets('list', (tester) async {
    await tester.runAsync(() async {
      await load('Roboto', [
        '/Users/devangsonawane/tools/flutter/bin/cache/artifacts/material_fonts/Roboto-Regular.ttf',
        '/Users/devangsonawane/tools/flutter/bin/cache/artifacts/material_fonts/Roboto-Medium.ttf',
        '/Users/devangsonawane/tools/flutter/bin/cache/artifacts/material_fonts/Roboto-Bold.ttf',
        '/Users/devangsonawane/tools/flutter/bin/cache/artifacts/material_fonts/Roboto-Black.ttf',
      ]);
      await load('packages/lucide_icons_flutter/Lucide', [
        '/Users/devangsonawane/.pub-cache/hosted/pub.dev/lucide_icons_flutter-3.1.20/assets/lucide.ttf',
      ]);
      await load('MaterialIcons', [
        '/Users/devangsonawane/tools/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
      ]);
    });
    addTearDown(tester.view.reset);
    await shot(tester, BookingsPage(bookings: bookings), 'list', h: 1300);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
  testWidgets('loading', (tester) async {
    await tester.runAsync(() async {
      await load('Roboto', [
        '/Users/devangsonawane/tools/flutter/bin/cache/artifacts/material_fonts/Roboto-Regular.ttf',
        '/Users/devangsonawane/tools/flutter/bin/cache/artifacts/material_fonts/Roboto-Medium.ttf',
        '/Users/devangsonawane/tools/flutter/bin/cache/artifacts/material_fonts/Roboto-Bold.ttf',
        '/Users/devangsonawane/tools/flutter/bin/cache/artifacts/material_fonts/Roboto-Black.ttf',
      ]);
      await load('packages/lucide_icons_flutter/Lucide', [
        '/Users/devangsonawane/.pub-cache/hosted/pub.dev/lucide_icons_flutter-3.1.20/assets/lucide.ttf',
      ]);
      await load('MaterialIcons', [
        '/Users/devangsonawane/tools/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
      ]);
    });
    addTearDown(tester.view.reset);
    await shot(
      tester,
      BookingsPage(bookings: bookings, isLoading: true),
      'loading',
    );
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
  testWidgets('detail_live', (tester) async {
    await tester.runAsync(() async {
      await load('Roboto', [
        '/Users/devangsonawane/tools/flutter/bin/cache/artifacts/material_fonts/Roboto-Regular.ttf',
        '/Users/devangsonawane/tools/flutter/bin/cache/artifacts/material_fonts/Roboto-Medium.ttf',
        '/Users/devangsonawane/tools/flutter/bin/cache/artifacts/material_fonts/Roboto-Bold.ttf',
        '/Users/devangsonawane/tools/flutter/bin/cache/artifacts/material_fonts/Roboto-Black.ttf',
      ]);
      await load('packages/lucide_icons_flutter/Lucide', [
        '/Users/devangsonawane/.pub-cache/hosted/pub.dev/lucide_icons_flutter-3.1.20/assets/lucide.ttf',
      ]);
      await load('MaterialIcons', [
        '/Users/devangsonawane/tools/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
      ]);
    });
    addTearDown(tester.view.reset);
    await shot(
      tester,
      BookingDetailPage(booking: bookings[0]),
      'detail_live',
      h: 1150,
    );
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
  testWidgets('detail_done', (tester) async {
    await tester.runAsync(() async {
      await load('Roboto', [
        '/Users/devangsonawane/tools/flutter/bin/cache/artifacts/material_fonts/Roboto-Regular.ttf',
        '/Users/devangsonawane/tools/flutter/bin/cache/artifacts/material_fonts/Roboto-Medium.ttf',
        '/Users/devangsonawane/tools/flutter/bin/cache/artifacts/material_fonts/Roboto-Bold.ttf',
        '/Users/devangsonawane/tools/flutter/bin/cache/artifacts/material_fonts/Roboto-Black.ttf',
      ]);
      await load('packages/lucide_icons_flutter/Lucide', [
        '/Users/devangsonawane/.pub-cache/hosted/pub.dev/lucide_icons_flutter-3.1.20/assets/lucide.ttf',
      ]);
      await load('MaterialIcons', [
        '/Users/devangsonawane/tools/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
      ]);
    });
    addTearDown(tester.view.reset);
    await shot(
      tester,
      BookingDetailPage(booking: bookings[2]),
      'detail_done',
      h: 1150,
    );
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
  testWidgets('detail_cancel', (tester) async {
    await tester.runAsync(() async {
      await load('Roboto', [
        '/Users/devangsonawane/tools/flutter/bin/cache/artifacts/material_fonts/Roboto-Regular.ttf',
        '/Users/devangsonawane/tools/flutter/bin/cache/artifacts/material_fonts/Roboto-Medium.ttf',
        '/Users/devangsonawane/tools/flutter/bin/cache/artifacts/material_fonts/Roboto-Bold.ttf',
        '/Users/devangsonawane/tools/flutter/bin/cache/artifacts/material_fonts/Roboto-Black.ttf',
      ]);
      await load('packages/lucide_icons_flutter/Lucide', [
        '/Users/devangsonawane/.pub-cache/hosted/pub.dev/lucide_icons_flutter-3.1.20/assets/lucide.ttf',
      ]);
      await load('MaterialIcons', [
        '/Users/devangsonawane/tools/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
      ]);
    });
    addTearDown(tester.view.reset);
    await shot(
      tester,
      BookingDetailPage(booking: bookings[4]),
      'detail_cancel',
    );
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
  testWidgets('all', (tester) async {
    await tester.runAsync(() async {
      await load('Roboto', [
        '/Users/devangsonawane/tools/flutter/bin/cache/artifacts/material_fonts/Roboto-Regular.ttf',
        '/Users/devangsonawane/tools/flutter/bin/cache/artifacts/material_fonts/Roboto-Medium.ttf',
        '/Users/devangsonawane/tools/flutter/bin/cache/artifacts/material_fonts/Roboto-Bold.ttf',
        '/Users/devangsonawane/tools/flutter/bin/cache/artifacts/material_fonts/Roboto-Black.ttf',
      ]);
      await load('packages/lucide_icons_flutter/Lucide', [
        '/Users/devangsonawane/.pub-cache/hosted/pub.dev/lucide_icons_flutter-3.1.20/assets/lucide.ttf',
      ]);
      await load('MaterialIcons', [
        '/Users/devangsonawane/tools/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
      ]);
    });
    addTearDown(tester.view.reset);
    await shot(
      tester,
      AllServicesPage(services: services, onServiceSelected: (_, _) async {}),
      'all',
      h: 1300,
    );
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
  testWidgets('all_320', (tester) async {
    await tester.runAsync(() async {
      await load('Roboto', [
        '/Users/devangsonawane/tools/flutter/bin/cache/artifacts/material_fonts/Roboto-Regular.ttf',
        '/Users/devangsonawane/tools/flutter/bin/cache/artifacts/material_fonts/Roboto-Medium.ttf',
        '/Users/devangsonawane/tools/flutter/bin/cache/artifacts/material_fonts/Roboto-Bold.ttf',
        '/Users/devangsonawane/tools/flutter/bin/cache/artifacts/material_fonts/Roboto-Black.ttf',
      ]);
      await load('packages/lucide_icons_flutter/Lucide', [
        '/Users/devangsonawane/.pub-cache/hosted/pub.dev/lucide_icons_flutter-3.1.20/assets/lucide.ttf',
      ]);
      await load('MaterialIcons', [
        '/Users/devangsonawane/tools/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
      ]);
    });
    addTearDown(tester.view.reset);
    await shot(
      tester,
      AllServicesPage(services: services, onServiceSelected: (_, _) async {}),
      'all_320',
    );
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
