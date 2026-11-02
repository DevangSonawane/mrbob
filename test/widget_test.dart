import 'package:flutter_test/flutter_test.dart';

import 'package:mrbob/main.dart';

void main() {
  testWidgets('Zingit opens login before phone login', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ZingitApp(hasSession: false));

    expect(find.text('Log in or sign up'), findsOneWidget);
    expect(find.text('Enter Mobile Number'), findsOneWidget);
  });
}
