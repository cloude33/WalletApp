import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money/widgets/statistics/payment_simulator.dart';
import 'package:money/models/wallet.dart';

void main() {
  group('PaymentSimulator Widget Tests', () {
    late List<Wallet> testCreditCards;
    late List<Wallet> testKmhAccounts;

    setUp(() {
      // Create test credit cards
      testCreditCards = [
        Wallet(
          id: 'card1',
          name: 'Test Card 1',
          type: 'credit_card',
          balance: -1000.0,
          creditLimit: 5000.0,
          color: '#FF0000',
          icon: 'credit_card',
        ),
        Wallet(
          id: 'card2',
          name: 'Test Card 2',
          type: 'credit_card',
          balance: -2000.0,
          creditLimit: 10000.0,
          color: '#0000FF',
          icon: 'credit_card',
        ),
      ];

      testKmhAccounts = [];
    });

    testWidgets('should display empty state when no credit cards', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaymentSimulator(
              creditCards: [],
              kmhAccounts: [],
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.credit_card_off), findsOneWidget);
      expect(find.text('Kredi kartı bulunamadı'), findsOneWidget);
    });

    testWidgets('should display card selector when credit cards exist', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaymentSimulator(
              creditCards: testCreditCards,
              kmhAccounts: testKmhAccounts,
            ),
          ),
        ),
      );

      // Wait for initial load
      await tester.pump();

      expect(find.text('Kart Seçin'), findsOneWidget);
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    });

    testWidgets('should display loading indicator during simulation', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaymentSimulator(
              creditCards: testCreditCards,
              kmhAccounts: testKmhAccounts,
            ),
          ),
        ),
      );

      // Initial pump shows loading
      await tester.pump();
      
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display custom payment section', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaymentSimulator(
              creditCards: testCreditCards,
              kmhAccounts: testKmhAccounts,
            ),
          ),
        ),
      );

      // Wait for simulations to load
      await tester.pumpAndSettle();

      expect(find.text('Özel Tutar Simülasyonu'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Hesapla'), findsOneWidget);
    });

    testWidgets('should allow card selection from dropdown', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaymentSimulator(
              creditCards: testCreditCards,
              kmhAccounts: testKmhAccounts,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap dropdown
      final dropdown = find.byType(DropdownButtonFormField<String>);
      expect(dropdown, findsOneWidget);

      // Tap to open dropdown
      await tester.tap(dropdown);
      await tester.pumpAndSettle();

      // Should show both cards
      expect(find.text('Test Card 1').hitTestable(), findsWidgets);
      expect(find.text('Test Card 2').hitTestable(), findsWidgets);
    });

    testWidgets('should display scenario cards after loading', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaymentSimulator(
              creditCards: testCreditCards,
              kmhAccounts: testKmhAccounts,
            ),
          ),
        ),
      );

      // Wait for simulations to complete
      await tester.pumpAndSettle();

      // Should display scenario titles
      expect(find.text('Asgari Ödeme'), findsOneWidget);
      expect(find.text('Önerilen Ödeme'), findsOneWidget);
      expect(find.text('Tam Ödeme'), findsOneWidget);
    });

    testWidgets('should display comparison table', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaymentSimulator(
              creditCards: testCreditCards,
              kmhAccounts: testKmhAccounts,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Karşılaştırma Tablosu'), findsOneWidget);
      expect(find.byType(Table), findsOneWidget);
    });

    testWidgets('should display scenario icons', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaymentSimulator(
              creditCards: testCreditCards,
              kmhAccounts: testKmhAccounts,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.warning_amber), findsOneWidget);
      expect(find.byIcon(Icons.recommend), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('should support pull to refresh', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaymentSimulator(
              creditCards: testCreditCards,
              kmhAccounts: testKmhAccounts,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find RefreshIndicator
      expect(find.byType(RefreshIndicator), findsOneWidget);

      // Perform pull to refresh gesture
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, 300),
      );
      await tester.pump();

      // Should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display info rows in scenario cards', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaymentSimulator(
              creditCards: testCreditCards,
              kmhAccounts: testKmhAccounts,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should display common labels
      expect(find.text('Ödeme Tutarı'), findsWidgets);
      expect(find.text('Toplam Maliyet'), findsWidgets);
      expect(find.text('Süre'), findsWidgets);
    });

    testWidgets('should allow custom amount input', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaymentSimulator(
              creditCards: testCreditCards,
              kmhAccounts: testKmhAccounts,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find text field
      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);

      // Enter custom amount
      await tester.enterText(textField, '1500');
      await tester.pump();

      // Verify text was entered
      expect(find.text('1500'), findsOneWidget);
    });

    testWidgets('should have calculate button for custom payment', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaymentSimulator(
              creditCards: testCreditCards,
              kmhAccounts: testKmhAccounts,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find calculate button
      final calculateButton = find.widgetWithText(ElevatedButton, 'Hesapla');
      expect(calculateButton, findsOneWidget);
    });

    testWidgets('should display table headers in comparison', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaymentSimulator(
              creditCards: testCreditCards,
              kmhAccounts: testKmhAccounts,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check table headers
      expect(find.text('Senaryo'), findsOneWidget);
      expect(find.text('Ödeme'), findsOneWidget);
      expect(find.text('Süre'), findsOneWidget);
      expect(find.text('Toplam'), findsOneWidget);
    });

    testWidgets('should display scenario names in comparison table', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaymentSimulator(
              creditCards: testCreditCards,
              kmhAccounts: testKmhAccounts,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check scenario names in table
      expect(find.text('Asgari Ödeme'), findsWidgets);
      expect(find.text('Önerilen'), findsOneWidget);
      expect(find.text('Tam Ödeme'), findsWidgets);
    });

    testWidgets('should use color indicators in comparison table', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaymentSimulator(
              creditCards: testCreditCards,
              kmhAccounts: testKmhAccounts,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find containers with circular shape (color indicators)
      final containers = find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.decoration is BoxDecoration &&
            (widget.decoration as BoxDecoration).shape == BoxShape.circle,
      );

      // Should have 3 color indicators (one for each scenario)
      expect(containers, findsNWidgets(3));
    });

    testWidgets('should display scrollable content', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaymentSimulator(
              creditCards: testCreditCards,
              kmhAccounts: testKmhAccounts,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('should have proper padding', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaymentSimulator(
              creditCards: testCreditCards,
              kmhAccounts: testKmhAccounts,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find SingleChildScrollView with padding
      final scrollView = tester.widget<SingleChildScrollView>(
        find.byType(SingleChildScrollView),
      );

      expect(scrollView.padding, const EdgeInsets.all(16.0));
    });
  });
}
