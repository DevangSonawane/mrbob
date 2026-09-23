import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:postfix/features/home/presentation/pages/home_page.dart';
import 'package:postfix/main.dart';

void main() {
  testWidgets('PostFix opens onboarding, logs in, and reaches home', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const PostFixApp());

    expect(find.text('Expert fixes at your doorstep'), findsOneWidget);

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(find.text('Continue with E-mail'), findsOneWidget);

    await tester.tap(find.text('Continue with E-mail'));
    await tester.pumpAndSettle();

    expect(find.text('Continue with E-mail'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -260),
    );
    await tester.pump();

    await tester.tap(find.widgetWithText(FilledButton, 'Sign In'));
    await tester.pumpAndSettle();

    expect(find.byType(HomePage), findsOneWidget);
    expect(find.text('YOUR SOLUTION, ONE\nTAP AWAY!'), findsOneWidget);
    expect(find.text('Service Categories'), findsOneWidget);
    expect(find.text('Repairs'), findsOneWidget);
  });
}
