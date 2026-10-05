import 'package:flutter_test/flutter_test.dart';

import 'package:mrbob/main.dart';

void main() {
  testWidgets('MrBob opens login before phone login', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MrBobApp());

    expect(find.text('Every care,'), findsNothing);
    expect(find.text('handled.'), findsNothing);
    expect(find.text('Skip'), findsNothing);
    expect(find.text('Log in or sign up'), findsOneWidget);
    expect(find.text('Enter Mobile Number'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Verify your phone number'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
  });
}
