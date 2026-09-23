import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mrbob/features/home/presentation/pages/home_page.dart';
import 'package:mrbob/main.dart';

void main() {
  testWidgets('MrBob opens onboarding, logs in, and reaches home', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MrBobApp());

    expect(find.text('Expert fixes at your doorstep'), findsOneWidget);

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(find.text('Continue with E-mail'), findsOneWidget);

    await tester.tap(find.text('Continue with E-mail'));
    await tester.pumpAndSettle();

    expect(find.text('Sign In'), findsNWidgets(2));

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -260),
    );
    await tester.pump();

    await tester.tap(find.text('Sign In').last);
    await tester.pumpAndSettle();

    expect(find.byType(HomePage), findsOneWidget);
    expect(find.text('YOUR SOLUTION,\nONE TAP AWAY!'), findsOneWidget);
    expect(find.text('Service Categories'), findsOneWidget);
    expect(find.text('Repairs'), findsOneWidget);
  });
}
