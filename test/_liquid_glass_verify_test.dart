import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:mrbob/features/shell/presentation/pages/main_shell.dart';

void main() {
  testWidgets('nav taps switch tab and search field accepts input', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: MainShell()));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Service Categories'), findsOneWidget);

    // Tabs are icon-only (labels removed); scope icon taps to the bar and
    // use the unselected (outlined) variant visible before each tap.
    Finder barIcon(IconData icon) => find.descendant(
      of: find.byType(GlassTabBar),
      matching: find.byIcon(icon),
    );

    await tester.tap(barIcon(Icons.receipt_long_outlined));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('My bookings'), findsOneWidget);

    await tester.tap(barIcon(Icons.home_outlined));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Service Categories'), findsOneWidget);

    // GlassSearchBar renders a CupertinoTextField internally
    // (GlassTextField.search), not a Material TextField.
    final searchField = find.byType(CupertinoTextField);
    expect(searchField, findsOneWidget);
    await tester.tap(searchField);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.enterText(searchField, 'Plumbing');
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.widgetWithText(CupertinoTextField, 'Plumbing'), findsOneWidget);
  });
}
