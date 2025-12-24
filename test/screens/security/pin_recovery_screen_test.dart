import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money/screens/security/pin_recovery_screen.dart';

void main() {
  group('PIN Recovery Screen Tests', () {
    testWidgets('should display PIN recovery screen title', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const PINRecoveryScreen(),
        ),
      );

      // Check if the app bar title is displayed
      expect(find.text('PIN Kurtarma'), findsOneWidget);
    });

    testWidgets('should have proper navigation buttons', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const PINRecoveryScreen(),
        ),
      );

      // Should have close button initially
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('should show loading initially', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const PINRecoveryScreen(),
        ),
      );

      // Wait for first frame
      await tester.pump();
      
      // Should show loading initially
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should not crash during initialization', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const PINRecoveryScreen(),
        ),
      );

      // Should not crash and should show scaffold
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });
}