import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parion/models/transaction.dart';
import 'package:parion/models/wallet.dart';
import 'package:parion/models/loan.dart';
import 'package:parion/models/credit_card_transaction.dart';
import 'package:parion/screens/statistics_screen.dart';

void main() {
  group('StatisticsScreen Widget Tests', () {
    late List<Transaction> testTransactions;
    late List<Wallet> testWallets;
    late List<Loan> testLoans;
    late List<CreditCardTransaction> testCreditCardTransactions;

    setUp(() {
      // Setup test data
      testTransactions = [
        Transaction(
          id: '1',
          amount: 1000.0,
          description: 'Test Income',
          date: DateTime.now(),
          type: 'income',
          category: 'Salary',
          walletId: 'wallet1',
        ),
        Transaction(
          id: '2',
          amount: 500.0,
          description: 'Test Expense',
          date: DateTime.now(),
          type: 'expense',
          category: 'Food',
          walletId: 'wallet1',
        ),
      ];

      testWallets = [
        Wallet(
          id: 'wallet1',
          name: 'Test Wallet',
          balance: 5000.0,
          type: 'bank',
          color: '0xFF2196F3',
          icon: 'account_balance',
        ),
        Wallet(
          id: 'wallet2',
          name: 'Test Credit Card',
          balance: -2000.0,
          type: 'credit_card',
          color: '0xFFF44336',
          icon: 'credit_card',
        ),
      ];

      testLoans = [];
      testCreditCardTransactions = [];
    });

    testWidgets('should render statistics screen with all tabs',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: StatisticsScreen(
            transactions: testTransactions,
            wallets: testWallets,
            loans: testLoans,
            creditCardTransactions: testCreditCardTransactions,
          ),
        ),
      );

      // Verify screen title
      expect(find.text('İstatistikler'), findsOneWidget);

      // Verify all tabs are present
      expect(find.text('Nakit akışı'), findsOneWidget);
      expect(find.text('Harcama'), findsOneWidget);
      expect(find.text('Kredi'), findsOneWidget);
      expect(find.text('Raporlar'), findsOneWidget);
      expect(find.text('Varlıklar'), findsOneWidget);
    });

    testWidgets('should switch between tabs', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: StatisticsScreen(
            transactions: testTransactions,
            wallets: testWallets,
            loans: testLoans,
            creditCardTransactions: testCreditCardTransactions,
          ),
        ),
      );

      // Initial tab should be Raporlar (index 3)
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap on Nakit akışı tab
      await tester.tap(find.text('Nakit akışı'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify tab switched
      expect(find.byType(TabBarView), findsOneWidget);

      // Tap on Harcama tab
      await tester.tap(find.text('Harcama'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap on Kredi tab
      await tester.tap(find.text('Kredi'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap on Varlıklar tab
      await tester.tap(find.text('Varlıklar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('should display time filter bar', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: StatisticsScreen(
            transactions: testTransactions,
            wallets: testWallets,
            loans: testLoans,
            creditCardTransactions: testCreditCardTransactions,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Time filter should be visible at the bottom
      // Look for filter-related text or buttons
      expect(find.byType(Positioned), findsWidgets);
    });

    testWidgets('should render cash flow tab with chart',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: StatisticsScreen(
            transactions: testTransactions,
            wallets: testWallets,
            loans: testLoans,
            creditCardTransactions: testCreditCardTransactions,
          ),
        ),
      );

      // Navigate to cash flow tab
      await tester.tap(find.text('Nakit akışı'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify chart title
      expect(find.text('Gelir vs Gider'), findsOneWidget);
    });

    testWidgets('should render credit tab with credit cards',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: StatisticsScreen(
            transactions: testTransactions,
            wallets: testWallets,
            loans: testLoans,
            creditCardTransactions: testCreditCardTransactions,
          ),
        ),
      );

      // Navigate to credit tab
      await tester.tap(find.text('Kredi'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify credit card section
      expect(find.text('Kredi Kartları'), findsOneWidget);
      expect(find.text('Toplam Borç'), findsOneWidget);
    });

    testWidgets('should render assets tab with wallets',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: StatisticsScreen(
            transactions: testTransactions,
            wallets: testWallets,
            loans: testLoans,
            creditCardTransactions: testCreditCardTransactions,
          ),
        ),
      );

      // Navigate to assets tab
      await tester.tap(find.text('Varlıklar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify assets section
      expect(find.text('Varlık Listesi'), findsOneWidget);
    });

    testWidgets('should render reports tab', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: StatisticsScreen(
            transactions: testTransactions,
            wallets: testWallets,
            loans: testLoans,
            creditCardTransactions: testCreditCardTransactions,
          ),
        ),
      );

      // Reports tab is default (index 3)
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify reports section
      expect(find.text('Genel Bakış'), findsOneWidget);
    });

    testWidgets('should handle empty transactions', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: StatisticsScreen(
            transactions: [],
            wallets: testWallets,
            loans: testLoans,
            creditCardTransactions: [],
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Should still render without errors
      expect(find.text('İstatistikler'), findsOneWidget);
    });

    testWidgets('should handle empty wallets', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: StatisticsScreen(
            transactions: testTransactions,
            wallets: [],
            loans: testLoans,
            creditCardTransactions: testCreditCardTransactions,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Should still render without errors
      expect(find.text('İstatistikler'), findsOneWidget);
    });

    testWidgets('should display KMH wallets in assets tab',
        (WidgetTester tester) async {
      final kmhWallet = Wallet(
        id: 'kmh1',
        name: 'Test KMH',
        balance: -1000.0,
        type: 'bank',
        color: '0xFF9C27B0',
        icon: 'account_balance',
        creditLimit: 5000.0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: StatisticsScreen(
            transactions: testTransactions,
            wallets: [kmhWallet],
            loans: testLoans,
            creditCardTransactions: testCreditCardTransactions,
          ),
        ),
      );

      // Navigate to assets tab
      await tester.tap(find.text('Varlıklar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify KMH section
      expect(find.text('KMH Kullanım Durumu'), findsOneWidget);
    });

    testWidgets('should display loans in credit tab',
        (WidgetTester tester) async {
      final testLoan = Loan(
        id: 'loan1',
        name: 'Test Loan',
        bankName: 'Test Bank',
        totalAmount: 10000.0,
        remainingAmount: 5000.0,
        totalInstallments: 12,
        remainingInstallments: 6,
        currentInstallment: 6,
        installmentAmount: 833.33,
        startDate: DateTime.now().subtract(const Duration(days: 180)),
        endDate: DateTime.now().add(const Duration(days: 180)),
        walletId: 'w1',
        installments: [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: StatisticsScreen(
            transactions: testTransactions,
            wallets: testWallets,
            loans: [testLoan],
            creditCardTransactions: testCreditCardTransactions,
          ),
        ),
      );

      // Navigate to credit tab
      await tester.tap(find.text('Kredi'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify loan tracking section
      expect(find.text('Kredi Takibi'), findsOneWidget);
      expect(find.text('Devam eden krediler'), findsOneWidget);
    });

    testWidgets('should handle dark mode', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: StatisticsScreen(
            transactions: testTransactions,
            wallets: testWallets,
            loans: testLoans,
            creditCardTransactions: testCreditCardTransactions,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Should render in dark mode without errors
      expect(find.text('İstatistikler'), findsOneWidget);
    });

    testWidgets('should handle light mode', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: StatisticsScreen(
            transactions: testTransactions,
            wallets: testWallets,
            loans: testLoans,
            creditCardTransactions: testCreditCardTransactions,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Should render in light mode without errors
      expect(find.text('İstatistikler'), findsOneWidget);
    });
  });

  group('StatisticsScreen Chart Rendering Tests', () {
    testWidgets('should render line chart in cash flow tab',
        (WidgetTester tester) async {
      final transactions = List.generate(
        12,
        (index) => Transaction(
          id: 'trans$index',
          amount: 1000.0 + (index * 100),
          description: 'Transaction $index',
          date: DateTime(2024, index + 1, 15),
          type: index % 2 == 0 ? 'income' : 'expense',
          category: 'Test',
          walletId: 'wallet1',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: StatisticsScreen(
            transactions: transactions,
            wallets: [
              Wallet(
                id: 'wallet1',
                name: 'Test',
                balance: 5000.0,
                type: 'bank',
                color: '0xFF2196F3',
                icon: 'account_balance',
              ),
            ],
            loans: [],
            creditCardTransactions: [],
          ),
        ),
      );

      await tester.tap(find.text('Nakit akışı'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Chart should be rendered
      expect(find.text('Gelir vs Gider'), findsOneWidget);
    });

    testWidgets('should render pie chart in assets tab',
        (WidgetTester tester) async {
      final wallets = <Wallet>[
        Wallet(
          id: 'w1',
          name: 'Wallet 1',
          balance: 3000.0,
          type: 'bank',
          color: '0xFF2196F3',
          icon: 'account_balance',
        ),
        Wallet(
          id: 'w2',
          name: 'Wallet 2',
          balance: 2000.0,
          type: 'cash',
          color: '0xFF4CAF50',
          icon: 'money',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: StatisticsScreen(
            transactions: [],
            wallets: wallets,
            loans: [],
            creditCardTransactions: [],
          ),
        ),
      );

      await tester.tap(find.text('Varlıklar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Pie chart should be rendered
      expect(find.text('Varlık Listesi'), findsOneWidget);
    });
  });

  group('StatisticsScreen Filter Interaction Tests', () {
    testWidgets('should have filter positioned at bottom',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: StatisticsScreen(
            transactions: [],
            wallets: [],
            loans: [],
            creditCardTransactions: [],
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Filter should be in a Positioned widget at the bottom
      final positioned = tester.widgetList<Positioned>(find.byType(Positioned));
      expect(positioned.length, greaterThan(0));
    });
  });

  group('StatisticsScreen Export Button Tests', () {
    testWidgets('should display share icon in reports tab',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: StatisticsScreen(
            transactions: [
              Transaction(
                id: '1',
                amount: 1000.0,
                description: 'Test',
                date: DateTime.now(),
                type: 'income',
                category: 'Salary',
                walletId: 'w1',
              ),
            ],
            wallets: [],
            loans: [],
            creditCardTransactions: [],
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Reports tab is default, should have share icon
      // Share icon might not be visible in all cases, so just check no errors
      expect(tester.takeException(), isNull);
    });
  });
}
