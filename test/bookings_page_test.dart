import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mrbob/core/data/services_data.dart';
import 'package:mrbob/core/models/booking.dart';
import 'package:mrbob/features/bookings/presentation/pages/bookings_page.dart';

void main() {
  final bookings = [
    Booking(
      service: services.first,
      mode: 'Scheduled',
      slot: 'Today, 4:30 PM',
      payment: 'Pay on delivery',
      total: 648,
      status: BookingStatus.confirmed,
    ),
    Booking(
      service: services[1],
      mode: 'Instant',
      slot: 'ASAP, 20 min',
      payment: 'Pay now',
      total: 498,
      status: BookingStatus.inService,
    ),
    Booking(
      service: services[3],
      mode: 'Scheduled',
      slot: 'Yesterday, 2:00 PM',
      payment: 'Pay on delivery',
      total: 748,
      status: BookingStatus.completed,
    ),
  ];

  Widget wrap(Widget child) {
    return MaterialApp(home: child);
  }

  testWidgets('renders header, stats and booking cards', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(wrap(BookingsPage(bookings: bookings)));
    await tester.pumpAndSettle();

    expect(find.text('My bookings'), findsOneWidget);
    expect(find.text('Civil touch-ups'), findsOneWidget);
    expect(find.text('Plumbing fixes'), findsOneWidget);
    expect(find.text('Painting repairs'), findsOneWidget);
    expect(find.text('Confirmed'), findsOneWidget);
    expect(find.text('In service'), findsOneWidget);
    expect(find.text('Completed'), findsWidgets);
  });

  // Filter pills are keyed: card status labels reuse the same words.
  Finder segment(String label) => find.byKey(ValueKey('filter-$label'));

  testWidgets('filters bookings by segment', (tester) async {
    await tester.pumpWidget(wrap(BookingsPage(bookings: bookings)));
    await tester.pumpAndSettle();

    await tester.tap(segment('Completed'));
    await tester.pumpAndSettle();

    expect(find.text('Civil touch-ups'), findsNothing);
    expect(find.text('Plumbing fixes'), findsNothing);
    expect(find.text('Painting repairs'), findsOneWidget);

    await tester.tap(segment('Instant'));
    await tester.pumpAndSettle();

    expect(find.text('Plumbing fixes'), findsOneWidget);
    expect(find.text('Painting repairs'), findsNothing);
  });

  testWidgets('shows empty state when there are no bookings', (tester) async {
    await tester.pumpWidget(wrap(BookingsPage(bookings: const [])));
    await tester.pumpAndSettle();

    expect(find.text('No bookings here'), findsOneWidget);
    expect(
      find.textContaining('Services you book will appear here.'),
      findsOneWidget,
    );
  });

  testWidgets('no overflow across common phone widths', (tester) async {
    for (final size in const [
      Size(320, 640),
      Size(360, 780),
      Size(390, 844),
      Size(430, 932),
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          home: BookingsPage(bookings: bookings),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(size: size),
            child: child!,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    }
  });
}
