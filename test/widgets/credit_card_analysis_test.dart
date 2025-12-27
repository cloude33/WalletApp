import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:money/widgets/statistics/credit_card_analysis.dart';
import 'package:money/models/credit_card.dart';
import 'package:money/models/credit_card_statement.dart';
import 'package:money/models/credit_card_transaction.dart';
import 'package:money/services/credit_card_box_service.dart';
import 'package:money/services/data_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

void main() {
  late String testPath;

  setUp(() async {
    // Create a unique test directory for each test
    testPath =
        'test_hive_credit_card_analysis_${DateTime.now().millisecondsSinceEpoch}';
    await Directory(testPath).create(recursive: true);

    // Initialize Hive with test path
    Hive.init(testPath);

    // Register adapters
    if (!Hive.isAdapterRegistered(10)) {
      Hive.registerAdapter(CreditCardAdapter());
    }
    if (!Hive.isAdapterRegistered(11)) {
      Hive.registerAdapter(CreditCardTransactionAdapter());
    }
    if (!Hive.isAdapterRegistered(12)) {
      Hive.registerAdapter(CreditCardStatementAdapter());
    }

    // Initialize SharedPreferences with empty data for each test
    SharedPreferences.setMockInitialValues({});

    // Initialize boxes
    await CreditCardBoxService.init();
    await DataService().init();
  });

  tearDown(() async {
    // Close all boxes
    await Hive.close();

    // Clean up test directory
    try {
      await Directory(testPath).delete(recursive: true);
    } catch (e) {
      // Ignore errors during cleanup
    }
  });

  // Helper function to create test credit card
  CreditCard createTestCard({
    required String id,
    required String bankName,
    required String cardName,
    required double creditLimit,
  }) {
    return CreditCard(
      id: id,
      bankName: bankName,
      cardName: cardName,
      last4Digits: '1234',
      creditLimit: creditLimit,
      statementDay: 15,
      dueDateOffset: 10,
      monthlyInterestRate: 3.5,
      lateInterestRate: 4.5,
      cardColor: Colors.blue.toARGB32(),
      createdAt: DateTime.now(),
      isActive: true,
    );
  }

  // Helper function to create test transaction
  CreditCardTransaction createTestTransaction({
    required String id,
    required String cardId,
    required double amount,
    required String description,
    required String category,
  }) {
    return CreditCardTransaction(
      id: id,
      cardId: cardId,
      amount: amount,
      description: description,
      transactionDate: DateTime.now(),
      category: category,
      installmentCount: 1,
      createdAt: DateTime.now(),
    );
  }

  // Helper function to create test statement
  CreditCardStatement createTestStatement({
    required String id,
    required String cardId,
    required double totalDebt,
    required double minimumPayment,
    DateTime? dueDate,
  }) {
    final now = DateTime.now();
    return CreditCardStatement(
      id: id,
      cardId: cardId,
      periodStart: now.subtract(const Duration(days: 30)),
      periodEnd: now,
      dueDate: dueDate ?? now.add(const Duration(days: 15)),
      totalDebt: totalDebt,
      minimumPayment: minimumPayment,
      remainingDebt: totalDebt,
      createdAt: now,
    );
  }

  group('CreditCardAnalysis Widget Tests', () {
    testWidgets('shows loading indicator initially', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: CreditCardAnalysis())),
      );

      // Should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows empty state when no credit cards exist', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: CreditCardAnalysis())),
      );

      // Wait for data to load
      await tester.pumpAndSettle();

      // Should show empty state
      expect(find.text('Kredi Kartı Bulunamadı'), findsOneWidget);
      expect(
        find.text('Henüz kredi kartınız bulunmamaktadır.'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.credit_card_outlined), findsOneWidget);
    });

    testWidgets('displays credit card list with debt information', (
      WidgetTester tester,
    ) async {
      // Create test credit cards
      final card1 = createTestCard(
        id: 'card1',
        bankName: 'Test Bank',
        cardName: 'Gold Card',
        creditLimit: 10000.0,
      );

      final card2 = createTestCard(
        id: 'card2',
        bankName: 'Another Bank',
        cardName: 'Platinum Card',
        creditLimit: 20000.0,
      );

      // Save cards
      await CreditCardBoxService.creditCardsBox.put(card1.id, card1);
      await CreditCardBoxService.creditCardsBox.put(card2.id, card2);

      // Create transactions for card1
      final transaction1 = createTestTransaction(
        id: 'trans1',
        cardId: 'card1',
        amount: 1500.0,
        description: 'Test Purchase',
        category: 'Shopping',
      );

      await CreditCardBoxService.transactionsBox.put(
        transaction1.id,
        transaction1,
      );

      // Create statement for card1
      final statement1 = createTestStatement(
        id: 'stmt1',
        cardId: 'card1',
        totalDebt: 1500.0,
        minimumPayment: 150.0,
      );

      await CreditCardBoxService.statementsBox.put(statement1.id, statement1);

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: CreditCardAnalysis())),
      );

      // Wait for data to load
      await tester.pumpAndSettle();

      // Should show total summary card
      expect(find.text('Toplam Kredi Kartı Borcu'), findsOneWidget);
      expect(find.text('2 Kart'), findsOneWidget);

      // Should show individual credit cards
      expect(find.text('Test Bank Gold Card'), findsOneWidget);
      expect(find.text('Another Bank Platinum Card'), findsOneWidget);
    });

    testWidgets('displays card-based debt correctly', (
      WidgetTester tester,
    ) async {
      // Create test credit card with debt
      final card = createTestCard(
        id: 'card1',
        bankName: 'Test Bank',
        cardName: 'Gold Card',
        creditLimit: 10000.0,
      );

      await CreditCardBoxService.creditCardsBox.put(card.id, card);

      // Create transactions
      final transaction1 = createTestTransaction(
        id: 'trans1',
        cardId: 'card1',
        amount: 3000.0,
        description: 'Purchase 1',
        category: 'Shopping',
      );

      final transaction2 = createTestTransaction(
        id: 'trans2',
        cardId: 'card1',
        amount: 2000.0,
        description: 'Purchase 2',
        category: 'Food',
      );

      await CreditCardBoxService.transactionsBox.put(
        transaction1.id,
        transaction1,
      );
      await CreditCardBoxService.transactionsBox.put(
        transaction2.id,
        transaction2,
      );

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: CreditCardAnalysis())),
      );

      // Wait for data to load
      await tester.pumpAndSettle();

      // Should show debt amount (5000 TL)
      expect(find.textContaining('5.000'), findsAtLeastNWidgets(1));

      // Should show "Borç" label
      expect(find.text('Borç'), findsOneWidget);
    });

    testWidgets('displays total limit and usage', (WidgetTester tester) async {
      // Create test credit cards
      final card1 = createTestCard(
        id: 'card1',
        bankName: 'Bank 1',
        cardName: 'Card 1',
        creditLimit: 10000.0,
      );

      final card2 = createTestCard(
        id: 'card2',
        bankName: 'Bank 2',
        cardName: 'Card 2',
        creditLimit: 15000.0,
      );

      await CreditCardBoxService.creditCardsBox.put(card1.id, card1);
      await CreditCardBoxService.creditCardsBox.put(card2.id, card2);

      // Create transactions for card1 (3000 TL debt)
      final transaction1 = createTestTransaction(
        id: 'trans1',
        cardId: 'card1',
        amount: 3000.0,
        description: 'Purchase',
        category: 'Shopping',
      );

      await CreditCardBoxService.transactionsBox.put(
        transaction1.id,
        transaction1,
      );

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: CreditCardAnalysis())),
      );

      // Wait for data to load
      await tester.pumpAndSettle();

      // Should show total limit (25000 TL)
      expect(find.text('Toplam Limit'), findsOneWidget);
      expect(find.textContaining('25.000'), findsAtLeastNWidgets(1));

      // Should show utilization rate (3000/25000 = 12%)
      expect(find.text('Kullanım Oranı'), findsOneWidget);
      expect(find.textContaining('%12'), findsAtLeastNWidgets(1));
    });

    testWidgets(
      'displays installment status with minimum payment and due date',
      (WidgetTester tester) async {
        // Create test credit card
        final card = createTestCard(
          id: 'card1',
          bankName: 'Test Bank',
          cardName: 'Gold Card',
          creditLimit: 10000.0,
        );

        await CreditCardBoxService.creditCardsBox.put(card.id, card);

        // Create transaction
        final transaction = createTestTransaction(
          id: 'trans1',
          cardId: 'card1',
          amount: 5000.0,
          description: 'Purchase',
          category: 'Shopping',
        );

        await CreditCardBoxService.transactionsBox.put(
          transaction.id,
          transaction,
        );

        // Create statement with minimum payment and due date
        final dueDate = DateTime.now().add(const Duration(days: 15));
        final statement = createTestStatement(
          id: 'stmt1',
          cardId: 'card1',
          totalDebt: 5000.0,
          minimumPayment: 500.0,
          dueDate: dueDate,
        );

        await CreditCardBoxService.statementsBox.put(statement.id, statement);

        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: CreditCardAnalysis())),
        );

        // Wait for data to load
        await tester.pumpAndSettle();

        // Should show minimum payment
        expect(find.text('Minimum Ödeme'), findsOneWidget);
        expect(find.textContaining('500'), findsAtLeastNWidgets(1));

        // Should show due date
        expect(find.text('Son Ödeme Tarihi'), findsOneWidget);
      },
    );

    testWidgets('shows utilization progress bar with correct color', (
      WidgetTester tester,
    ) async {
      // Create test credit card with high utilization
      final card = createTestCard(
        id: 'card1',
        bankName: 'Test Bank',
        cardName: 'Gold Card',
        creditLimit: 10000.0,
      );

      await CreditCardBoxService.creditCardsBox.put(card.id, card);

      // Create transaction with 85% utilization
      final transaction = createTestTransaction(
        id: 'trans1',
        cardId: 'card1',
        amount: 8500.0,
        description: 'Purchase',
        category: 'Shopping',
      );

      await CreditCardBoxService.transactionsBox.put(
        transaction.id,
        transaction,
      );

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: CreditCardAnalysis())),
      );

      // Wait for data to load
      await tester.pumpAndSettle();

      // Should show utilization rate
      expect(find.text('Kullanım Oranı'), findsAtLeastNWidgets(1));
      expect(find.textContaining('%85'), findsAtLeastNWidgets(1));

      // Should show progress bar
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('shows positive message when card has no debt', (
      WidgetTester tester,
    ) async {
      // Create test credit card with no transactions
      final card = createTestCard(
        id: 'card1',
        bankName: 'Test Bank',
        cardName: 'Gold Card',
        creditLimit: 10000.0,
      );

      await CreditCardBoxService.creditCardsBox.put(card.id, card);

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: CreditCardAnalysis())),
      );

      // Wait for data to load
      await tester.pumpAndSettle();

      // Should show positive message
      expect(find.text('Bu kartta borç bulunmamaktadır'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('displays available credit correctly', (
      WidgetTester tester,
    ) async {
      // Create test credit card
      final card = createTestCard(
        id: 'card1',
        bankName: 'Test Bank',
        cardName: 'Gold Card',
        creditLimit: 10000.0,
      );

      await CreditCardBoxService.creditCardsBox.put(card.id, card);

      // Create transaction (3000 TL debt)
      final transaction = createTestTransaction(
        id: 'trans1',
        cardId: 'card1',
        amount: 3000.0,
        description: 'Purchase',
        category: 'Shopping',
      );

      await CreditCardBoxService.transactionsBox.put(
        transaction.id,
        transaction,
      );

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: CreditCardAnalysis())),
      );

      // Wait for data to load
      await tester.pumpAndSettle();

      // Should show available credit (10000 - 3000 = 7000)
      expect(find.text('Kullanılabilir Kredi'), findsOneWidget);
      expect(find.textContaining('7.000'), findsAtLeastNWidgets(1));
    });

    testWidgets('supports pull-to-refresh', (WidgetTester tester) async {
      // Create test credit card
      final card = createTestCard(
        id: 'card1',
        bankName: 'Test Bank',
        cardName: 'Gold Card',
        creditLimit: 10000.0,
      );

      await CreditCardBoxService.creditCardsBox.put(card.id, card);

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: CreditCardAnalysis())),
      );

      // Wait for initial load
      await tester.pumpAndSettle();

      // Find the RefreshIndicator
      expect(find.byType(RefreshIndicator), findsOneWidget);

      // Perform pull-to-refresh gesture
      await tester.drag(find.byType(RefreshIndicator), const Offset(0, 300));
      await tester.pumpAndSettle();

      // Widget should still be displayed
      expect(find.text('Test Bank Gold Card'), findsOneWidget);
    });
  });
}
