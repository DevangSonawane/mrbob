import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mrbob/features/home/presentation/pages/home_page.dart';

void main() {
  Future<void> pumpHome(WidgetTester tester, {bool reduceMotion = false}) {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    return tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(
          size: const Size(390, 844),
          disableAnimations: reduceMotion,
        ),
        child: MaterialApp(home: HomePage(onBooked: (_) {})),
      ),
    );
  }

  Future<void> teardown(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 10));
  }

  testWidgets('hero carousel rotates categories, hint and pages', (
    tester,
  ) async {
    await pumpHome(tester);
    await tester.pump(const Duration(milliseconds: 1000));
    expect(find.text('PLUMBING'), findsOneWidget);
    expect(find.text('"plumber"'), findsOneWidget);
    final title = tester.getTopLeft(find.text('experts').last);

    // Category tag flips; the title does not move.
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('ELECTRICAL'), findsOneWidget);
    expect(tester.getTopLeft(find.text('experts').last), title);

    // Search hint rolls to the next term.
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('"electrician"'), findsOneWidget);

    // Auto-advance to the inspection banner.
    await tester.pump(const Duration(milliseconds: 3000));
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pump(const Duration(milliseconds: 900));
    expect(find.text('NEW HOME?'), findsOneWidget);

    // Collapse the header; must not overflow.
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
    await teardown(tester);
  });

  testWidgets('reduced motion holds the first banner', (tester) async {
    await pumpHome(tester, reduceMotion: true);
    await tester.pump(const Duration(seconds: 8));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('experts'), findsWidgets);
    expect(find.text('NEW HOME?'), findsNothing);
    await teardown(tester);
  });
}
