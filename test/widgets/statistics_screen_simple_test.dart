import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money/models/transaction.dart';
import 'package:money/models/wallet.dart';
import 'package:money/models/loan.dart';
import 'package:money/models/credit_card_transaction.dart';
import 'package:money/screens/statistics_screen.dart';

/// Simplified widget tests for StatisticsScreen that focus on core rendering
/// and avoid async timeout issues
void main() {
  group('StatisticsScreen Simple Widget Tests', () {
    late List<Transaction> testTransactions;
    late List<Wallet> testWallets;

    setUp(() {
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
      ];
    });

    testWidgets('should render statistics screen', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: StatisticsScreen(
            transactions: testTransactions,
            wallets: testWallets,
            loans: [],
            creditCardTransactions: [],
          ),
        ),
      );

      // Verify screen title
      expect(find.text('İstatistikler'), findsOneWidget);
    });

    testWidgets('should display all tab labels', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: StatisticsScreen(
            transactions: testTransactions,
            wallets: testWallets,
            loans: [],
            creditCardTransactions: [],
          ),
        ),
      );

      // Verify all tabs are present
      expect(find.text('Nakit akışı'), findsOneWidget);
      expect(find.text('Harcama'), findsOneWidget);
      expect(find.text('Kredi'), findsOneWidget);
      expect(find.text('Raporlar'), findsOneWidget);
      expect(find.text('Varlıklar'), findsOneWidget);
    });

    testWidgets('should have TabBar widget', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: StatisticsScreen(
            transactions: testTransactions,
            wallets: testWallets,
            loans: [],
            creditCardTransactions: [],
          ),
        ),
      );

      expect(find.byType(TabBar), findsOneWidget);
      expect(find.byType(TabBarView), findsOneWidget);
    });

    testWidgets('should render with empty data', (WidgetTester tester) async {
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

      // Should still render without errors
      expect(find.text('İstatistikler'), findsOneWidget);
      expect(find.byType(TabBar), findsOneWidget);
    });

    testWidgets('should render in dark mode', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: StatisticsScreen(
            transactions: testTransactions,
            wallets: testWallets,
            loans: [],
            creditCardTransactions: [],
          ),
        ),
      );

      expect(find.text('İstatistikler'), findsOneWidget);
    });

    testWidgets('should render in light mode', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: StatisticsScreen(
            transactions: testTransactions,
            wallets: testWallets,
            loans: [],
            creditCardTransactions: [],
          ),
        ),
      );

      expect(find.text('İstatistikler'), findsOneWidget);
    });

    testWidgets('should have 5 tabs', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: StatisticsScreen(
            transactions: testTransactions,
            wallets: testWallets,
            loans: [],
            creditCardTransactions: [],
          ),
        ),
      );

      final tabBar = tester.widget<TabBar>(find.byType(TabBar));
      expect(tabBar.tabs.length, 5);
    });

    testWidgets('should have scrollable tab bar', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: StatisticsScreen(
            transactions: testTransactions,
            wallets: testWallets,
            loans: [],
            creditCardTransactions: [],
          ),
        ),
      );

      final tabBar = tester.widget<TabBar>(find.byType(TabBar));
      expect(tabBar.isScrollable, isTrue);
    });

    testWidgets('should render with credit card transactions',
        (WidgetTester tester) async {
      final creditCardTransactions = <CreditCardTransaction>[
        CreditCardTransaction(
          id: 'cc1',
          cardId: 'card1',
          amount: 500.0,
          description: 'Test CC Transaction',
          transactionDate: DateTime.now(),
          category: 'Shopping',
          installmentCount: 1,
          createdAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: StatisticsScreen(
            transactions: testTransactions,
            wallets: testWallets,
            loans: [],
            creditCardTransactions: creditCardTransactions,
          ),
        ),
      );

      expect(find.text('İstatistikler'), findsOneWidget);
    });

    testWidgets('should render with loans', (WidgetTester tester) async {
      final loans = [
        Loan(
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
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: StatisticsScreen(
            transactions: testTransactions,
            wallets: testWallets,
            loans: loans,
            creditCardTransactions: [],
          ),
        ),
      );

      expect(find.text('İstatistikler'), findsOneWidget);
    });

    testWidgets('should render with KMH wallets', (WidgetTester tester) async {
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
            loans: [],
            creditCardTransactions: [],
          ),
        ),
      );

      expect(find.text('İstatistikler'), findsOneWidget);
    });

    testWidgets('should render with credit card wallets',
        (WidgetTester tester) async {
      final creditCardWallet = Wallet(
        id: 'cc1',
        name: 'Test Credit Card',
        balance: -2000.0,
        type: 'credit_card',
        color: '0xFFF44336',
        icon: 'credit_card',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: StatisticsScreen(
            transactions: testTransactions,
            wallets: [creditCardWallet],
            loans: [],
            creditCardTransactions: [],
          ),
        ),
      );

      expect(find.text('İstatistikler'), findsOneWidget);
    });

    testWidgets('should have positioned filter widget',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: StatisticsScreen(
            transactions: testTransactions,
            wallets: testWallets,
            loans: [],
            creditCardTransactions: [],
          ),
        ),
      );

      // Filter should be in a Positioned widget
      expect(find.byType(Positioned), findsWidgets);
    });

    testWidgets('should render SafeArea', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: StatisticsScreen(
            transactions: testTransactions,
            wallets: testWallets,
            loans: [],
            creditCardTransactions: [],
          ),
        ),
      );

      expect(find.byType(SafeArea), findsOneWidget);
    });

    testWidgets('should render Scaffold', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: StatisticsScreen(
            transactions: testTransactions,
            wallets: testWallets,
            loans: [],
            creditCardTransactions: [],
          ),
        ),
      );

      expect(find.byType(Scaffold), findsOneWidget);
    });
  });
}
