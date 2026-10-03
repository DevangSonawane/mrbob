import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mrbob/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:mrbob/main.dart';

void main() {
  testWidgets('MrBob opens onboarding slides before email login', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MrBobApp());

    expect(find.byType(OnboardingPage), findsOneWidget);
    expect(find.text('Every home fix, one app.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('onboarding-next-button')));
    await tester.pumpAndSettle();

    expect(find.text('Know the moment they arrive.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('onboarding-next-button')));
    await tester.pumpAndSettle();

    expect(find.text('Continue with E-mail'), findsOneWidget);

    await tester.tap(find.text('Continue with E-mail'));
    await tester.pumpAndSettle();

    expect(find.text('Enter your phone number'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
  });
}
