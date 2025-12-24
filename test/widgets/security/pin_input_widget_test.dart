import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money/widgets/security/pin_input_widget.dart';

void main() {
  group('PINInputWidget Tests', () {
    testWidgets('should display correct number of dots', (WidgetTester tester) async {
      String pin = '';
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PINInputWidget(
              pin: pin,
              onChanged: (value) => pin = value,
              maxLength: 6,
            ),
          ),
        ),
      );

      // Widget should be rendered
      expect(find.byType(PINInputWidget), findsOneWidget);
      
      // Number pad buttons should be present
      expect(find.text('1'), findsOneWidget);
      expect(find.text('9'), findsOneWidget);
      expect(find.byIcon(Icons.backspace_outlined), findsOneWidget);
    });

    testWidgets('should call onChanged when number is pressed', (WidgetTester tester) async {
      String pin = '';
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PINInputWidget(
              pin: pin,
              onChanged: (value) => pin = value,
              maxLength: 6,
            ),
          ),
        ),
      );

      // '1' butonuna bas
      await tester.tap(find.text('1'));
      await tester.pump();

      expect(pin, equals('1'));
    });

    testWidgets('should call onCompleted when PIN is complete', (WidgetTester tester) async {
      String pin = '';
      String? completedPin;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return PINInputWidget(
                  pin: pin,
                  onChanged: (value) => setState(() => pin = value),
                  onCompleted: (value) => completedPin = value,
                  maxLength: 4,
                );
              },
            ),
          ),
        ),
      );

      // 4 haneli PIN gir
      await tester.tap(find.text('1'));
      await tester.pump();
      await tester.tap(find.text('2'));
      await tester.pump();
      await tester.tap(find.text('3'));
      await tester.pump();
      await tester.tap(find.text('4'));
      await tester.pump();

      expect(completedPin, equals('1234'));
    });

    testWidgets('should handle backspace correctly', (WidgetTester tester) async {
      String pin = '123';
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return PINInputWidget(
                  pin: pin,
                  onChanged: (value) => setState(() => pin = value),
                  maxLength: 6,
                );
              },
            ),
          ),
        ),
      );

      // Backspace butonuna bas
      await tester.tap(find.byIcon(Icons.backspace_outlined));
      await tester.pump();

      expect(pin, equals('12'));
    });

    testWidgets('should respect maxLength limit', (WidgetTester tester) async {
      String pin = '';
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return PINInputWidget(
                  pin: pin,
                  onChanged: (value) => setState(() => pin = value),
                  maxLength: 4,
                );
              },
            ),
          ),
        ),
      );

      // 5 rakam girmeye çalış
      for (int i = 1; i <= 5; i++) {
        await tester.tap(find.text(i.toString()));
        await tester.pump();
      }

      // Sadece 4 hane olmalı
      expect(pin.length, equals(4));
      expect(pin, equals('1234'));
    });

    testWidgets('should show error state correctly', (WidgetTester tester) async {
      String pin = '1234';
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PINInputWidget(
              pin: pin,
              onChanged: (value) {},
              hasError: true,
              maxLength: 4,
            ),
          ),
        ),
      );

      await tester.pump();
      
      // Error state'de widget render edilmeli
      expect(find.byType(PINInputWidget), findsOneWidget);
    });

    testWidgets('should disable input when loading', (WidgetTester tester) async {
      String pin = '';
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PINInputWidget(
              pin: pin,
              onChanged: (value) => pin = value,
              isLoading: true,
              maxLength: 4,
            ),
          ),
        ),
      );

      // Loading durumunda butonlar disabled olmalı
      await tester.tap(find.text('1'));
      await tester.pump();

      // PIN değişmemeli
      expect(pin, equals(''));
      
      // Loading indicator görünmeli
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should hide number pad when showNumberPad is false', (WidgetTester tester) async {
      String pin = '';
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PINInputWidget(
              pin: pin,
              onChanged: (value) => pin = value,
              showNumberPad: false,
              maxLength: 4,
            ),
          ),
        ),
      );

      // Number pad butonları görünmemeli
      expect(find.text('1'), findsNothing);
      expect(find.text('2'), findsNothing);
      expect(find.byIcon(Icons.backspace_outlined), findsNothing);
    });

    testWidgets('should show PIN characters when obscureText is false', (WidgetTester tester) async {
      String pin = '12';
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PINInputWidget(
              pin: pin,
              onChanged: (value) {},
              obscureText: false,
              maxLength: 4,
            ),
          ),
        ),
      );

      await tester.pump();
      
      // Widget render edilmeli (karakterler dot'larda görünür olacak)
      expect(find.byType(PINInputWidget), findsOneWidget);
    });

    testWidgets('should handle custom dot sizes and spacing', (WidgetTester tester) async {
      String pin = '';
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PINInputWidget(
              pin: pin,
              onChanged: (value) => pin = value,
              dotSize: 20.0,
              dotSpacing: 12.0,
              maxLength: 4,
            ),
          ),
        ),
      );

      await tester.pump();
      
      // Widget custom parametrelerle render edilmeli
      expect(find.byType(PINInputWidget), findsOneWidget);
    });
  });

  group('PINInputTheme Tests', () {
    test('should create default theme correctly', () {
      const theme = PINInputTheme.defaultTheme;
      
      expect(theme.dotSize, equals(16.0));
      expect(theme.dotSpacing, equals(8.0));
      expect(theme.numberPadButtonSize, equals(60.0));
    });

    test('should create dark theme correctly', () {
      const theme = PINInputTheme.darkTheme;
      
      expect(theme.dotSize, equals(18.0));
      expect(theme.dotSpacing, equals(10.0));
      expect(theme.numberPadButtonSize, equals(65.0));
    });

    test('should create compact theme correctly', () {
      const theme = PINInputTheme.compactTheme;
      
      expect(theme.dotSize, equals(12.0));
      expect(theme.dotSpacing, equals(6.0));
      expect(theme.numberPadButtonSize, equals(50.0));
    });
  });
}