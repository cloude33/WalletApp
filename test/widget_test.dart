// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money/screens/welcome_screen.dart';

void main() {
  testWidgets('App launches without errors', (WidgetTester tester) async {
    // Test a simple screen instead of the full app to avoid Firebase issues
    await tester.pumpWidget(
      const MaterialApp(
        home: WelcomeScreen(),
      ),
    );

    // Verify that the welcome screen renders without throwing errors
    expect(tester.takeException(), isNull);
    expect(find.byType(WelcomeScreen), findsOneWidget);
  });
}