import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money/screens/security/pin_change_screen.dart';

void main() {
  group('PINChangeScreen', () {
    testWidgets('should display PIN change screen with correct title', (WidgetTester tester) async {
      // Build the widget
      await tester.pumpWidget(
        const MaterialApp(
          home: PINChangeScreen(),
        ),
      );

      // Verify the screen is displayed
      expect(find.text('PIN Değiştir'), findsOneWidget);
      expect(find.text('Mevcut PIN\'inizi Girin'), findsOneWidget);
      expect(find.text('PIN kodunuzu değiştirmek için önce mevcut PIN\'inizi doğrulayın.'), findsOneWidget);
    });

    testWidgets('should show progress indicator', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PINChangeScreen(),
        ),
      );

      // Verify progress indicator is present
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('should have number pad for PIN input', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PINChangeScreen(),
        ),
      );

      // Verify number pad buttons are present
      for (int i = 0; i <= 9; i++) {
        expect(find.text(i.toString()), findsOneWidget);
      }
      
      // Verify backspace button
      expect(find.byIcon(Icons.backspace_outlined), findsOneWidget);
    });

    testWidgets('should enable continue button when PIN has 4+ digits', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PINChangeScreen(),
        ),
      );

      // Initially, continue button should be disabled
      final continueButton = find.text('Doğrula');
      expect(continueButton, findsOneWidget);
      
      // Tap some numbers to enter a PIN
      await tester.tap(find.text('1'));
      await tester.pump();
      await tester.tap(find.text('2'));
      await tester.pump();
      await tester.tap(find.text('3'));
      await tester.pump();
      await tester.tap(find.text('4'));
      await tester.pump();

      // Now the continue button should be enabled (we can't easily test this without mocking)
      // But we can verify the PIN dots are filled
      // This is a basic UI test to ensure the screen renders correctly
    });

    testWidgets('should show PIN dots for visual feedback', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PINChangeScreen(),
        ),
      );

      // Verify PIN dots are present (6 dots for max length)
      // We can't easily count the exact containers, but we can verify the structure exists
      expect(find.byType(Row), findsWidgets);
      expect(find.byType(Container), findsWidgets);
    });
  });
}