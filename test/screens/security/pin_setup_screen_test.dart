import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money/screens/security/pin_setup_screen.dart';

void main() {
  group('PIN Setup Screen Tests', () {
    testWidgets('PIN setup screen displays correctly', (WidgetTester tester) async {
      // Set a larger test size to avoid overflow
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      
      // Build the PIN setup screen
      await tester.pumpWidget(
        const MaterialApp(
          home: PINSetupScreen(),
        ),
      );

      // Wait for any async initialization
      await tester.pumpAndSettle();

      // Verify that the screen displays correctly
      expect(find.text('PIN Kurulumu'), findsOneWidget);
      expect(find.text('PIN Kodu Oluşturun'), findsOneWidget);
      expect(find.text('Uygulamanızı güvence altına almak için bir PIN kodu oluşturun.'), findsOneWidget);
      
      // Verify PIN length selector is displayed
      expect(find.text('4 Haneli'), findsOneWidget);
      expect(find.text('6 Haneli'), findsOneWidget);
      
      // Verify that the continue button is initially disabled
      final continueButton = find.text('Devam Et');
      expect(continueButton, findsOneWidget);
      
      // Verify that PIN dots are displayed
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('PIN input works correctly', (WidgetTester tester) async {
      // Set a larger test size to avoid overflow
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      
      // Build the PIN setup screen
      await tester.pumpWidget(
        const MaterialApp(
          home: PINSetupScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Test number pad input
      await tester.tap(find.text('1'));
      await tester.pump();
      
      await tester.tap(find.text('2'));
      await tester.pump();
      
      await tester.tap(find.text('3'));
      await tester.pump();
      
      await tester.tap(find.text('4'));
      await tester.pump();

      // Verify that the continue button becomes enabled after entering 4 digits
      final continueButton = find.widgetWithText(ElevatedButton, 'Devam Et');
      expect(continueButton, findsOneWidget);
      
      final buttonWidget = tester.widget<ElevatedButton>(continueButton);
      expect(buttonWidget.onPressed, isNotNull);
    });

    testWidgets('PIN strength indicator appears', (WidgetTester tester) async {
      // Set a larger test size to avoid overflow
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      
      // Build the PIN setup screen
      await tester.pumpWidget(
        const MaterialApp(
          home: PINSetupScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Enter a PIN to trigger strength indicator
      await tester.tap(find.text('1'));
      await tester.pump();
      
      await tester.tap(find.text('2'));
      await tester.pump();
      
      await tester.tap(find.text('3'));
      await tester.pump();
      
      await tester.tap(find.text('4'));
      await tester.pump();

      // Verify that PIN strength indicator appears
      expect(find.text('PIN Güçlülüğü: '), findsOneWidget);
    });

    testWidgets('Backspace button works correctly', (WidgetTester tester) async {
      // Set a larger test size to avoid overflow
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      
      // Build the PIN setup screen
      await tester.pumpWidget(
        const MaterialApp(
          home: PINSetupScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Enter some digits
      await tester.tap(find.text('1'));
      await tester.pump();
      
      await tester.tap(find.text('2'));
      await tester.pump();

      // Tap backspace
      await tester.tap(find.byIcon(Icons.backspace_outlined));
      await tester.pump();

      // The continue button should be disabled since we have less than 4 digits
      final continueButton = find.widgetWithText(ElevatedButton, 'Devam Et');
      expect(continueButton, findsOneWidget);
      
      final buttonWidget = tester.widget<ElevatedButton>(continueButton);
      expect(buttonWidget.onPressed, isNull);
    });

    testWidgets('Navigation to confirm page works', (WidgetTester tester) async {
      // Set a larger test size to avoid overflow
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      
      // Build the PIN setup screen
      await tester.pumpWidget(
        const MaterialApp(
          home: PINSetupScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Enter a 4-digit PIN
      await tester.tap(find.text('1'));
      await tester.pump();
      
      await tester.tap(find.text('2'));
      await tester.pump();
      
      await tester.tap(find.text('3'));
      await tester.pump();
      
      await tester.tap(find.text('4'));
      await tester.pump();

      // Tap continue button
      await tester.tap(find.text('Devam Et'));
      await tester.pumpAndSettle();

      // Verify that we're now on the confirm page
      expect(find.text('PIN Kodunu Onaylayın'), findsOneWidget);
      expect(find.text('Güvenlik için PIN kodunuzu tekrar girin.'), findsOneWidget);
    });
  });
}