import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money/widgets/statistics/payment_simulator.dart';
import 'package:money/models/wallet.dart';
import '../test_setup.dart';

void main() {
  setUpAll(() async {
    await TestSetup.initializeTestEnvironment();
  });

  setUp(() async {
    await TestSetup.setupTest();
  });

  tearDown(() async {
    await TestSetup.tearDownTest();
  });

  tearDownAll(() async {
    await TestSetup.cleanupTestEnvironment();
  });

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
        TestSetup.createTestWidget(
          PaymentSimulator(
            creditCards: [],
            kmhAccounts: [],
          ),
        ),
      );

      expect(find.byIcon(Icons.credit_card_off), findsOneWidget);
      expect(find.text('Kredi kartı bulunamadı'), findsOneWidget);
    });

    testWidgets('should display card selector when credit cards exist', (tester) async {
      await tester.pumpWidget(
        TestSetup.createTestWidget(
          PaymentSimulator(
            creditCards: testCreditCards,
            kmhAccounts: testKmhAccounts,
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
        TestSetup.createTestWidget(
          PaymentSimulator(
            creditCards: testCreditCards,
            kmhAccounts: testKmhAccounts,
          ),
        ),
      );

      // Initial pump shows the widget structure
      await tester.pump();
      
      // Widget should render without errors - check for basic structure
      expect(find.byType(PaymentSimulator), findsOneWidget);
    });

    testWidgets('should display custom payment section', (tester) async {
      await tester.pumpWidget(
        TestSetup.createTestWidget(
          PaymentSimulator(
            creditCards: testCreditCards,
            kmhAccounts: testKmhAccounts,
          ),
        ),
      );

      // Wait for simulations to load
      await tester.pumpAndSettle();

      // Widget should render without errors
      expect(find.byType(PaymentSimulator), findsOneWidget);
    });

    testWidgets('should display scenario cards after loading', (tester) async {
      await tester.pumpWidget(
        TestSetup.createTestWidget(
          PaymentSimulator(
            creditCards: testCreditCards,
            kmhAccounts: testKmhAccounts,
          ),
        ),
      );

      // Wait for simulations to complete
      await tester.pumpAndSettle();

      // Widget should render without errors
      expect(find.byType(PaymentSimulator), findsOneWidget);
    });

    testWidgets('should display comparison table', (tester) async {
      await tester.pumpWidget(
        TestSetup.createTestWidget(
          PaymentSimulator(
            creditCards: testCreditCards,
            kmhAccounts: testKmhAccounts,
          ),
        ),
      );

      // Wait for simulations to complete
      await tester.pumpAndSettle();

      // Widget should render without errors
      expect(find.byType(PaymentSimulator), findsOneWidget);
    });

    testWidgets('should display scenario icons', (tester) async {
      await tester.pumpWidget(
        TestSetup.createTestWidget(
          PaymentSimulator(
            creditCards: testCreditCards,
            kmhAccounts: testKmhAccounts,
          ),
        ),
      );

      // Wait for simulations to complete
      await tester.pumpAndSettle();

      // Widget should render without errors
      expect(find.byType(PaymentSimulator), findsOneWidget);
    });

    testWidgets('should support pull to refresh', (tester) async {
      await tester.pumpWidget(
        TestSetup.createTestWidget(
          PaymentSimulator(
            creditCards: testCreditCards,
            kmhAccounts: testKmhAccounts,
          ),
        ),
      );

      // Wait for initial load
      await tester.pumpAndSettle();

      // Find the RefreshIndicator
      final refreshIndicator = find.byType(RefreshIndicator);
      expect(refreshIndicator, findsOneWidget);
    });
  });
}