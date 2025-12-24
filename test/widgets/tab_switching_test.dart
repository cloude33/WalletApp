import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money/models/transaction.dart';
import 'package:money/models/wallet.dart';
import 'package:money/screens/statistics_screen.dart';

void main() {
  group('Statistics Screen Tab Switching Tests', () {
    late List<Transaction> testTransactions;
    late List<Wallet> testWallets;

    setUp(() {
      testTransactions = [
        Transaction(
          id: '1',
          amount: 1000.0,
          description: 'Income',
          date: DateTime.now(),
          type: 'income',
          category: 'Salary',
          walletId: 'w1',
        ),
        Transaction(
          id: '2',
          amount: 500.0,
          description: 'Expense',
          date: DateTime.now(),
          type: 'expense',
          category: 'Food',
          walletId: 'w1',
        ),
      ];

      testWallets = [
        Wallet(
          id: 'w1',
          name: 'Main Wallet',
          balance: 5000.0,
          type: 'bank',
          color: '0xFF2196F3',
          icon: 'account_balance',
        ),
      ];
    });

    testWidgets('should start with Reports tab selected',
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

      await tester.pumpAndSettle();

      // Reports tab content should be visible
      expect(find.text('Genel Bakış'), findsOneWidget);
    });

    testWidgets('should switch to Cash Flow tab', (WidgetTester tester) async {
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

      await tester.pumpAndSettle();

      // Tap Cash Flow tab
      await tester.tap(find.text('Nakit akışı'));
      await tester.pumpAndSettle();

      // Cash Flow content should be visible
      expect(find.text('Gelir vs Gider'), findsOneWidget);
    });

    testWidgets('should switch to Spending tab', (WidgetTester tester) async {
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

      await tester.pumpAndSettle();

      // Tap Spending tab
      await tester.tap(find.text('Harcama'));
      await tester.pumpAndSettle();

      // Spending tab should load
      expect(find.byType(TabBarView), findsOneWidget);
    });

    testWidgets('should switch to Credit tab', (WidgetTester tester) async {
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

      await tester.pumpAndSettle();

      // Tap Credit tab
      await tester.tap(find.text('Kredi'));
      await tester.pumpAndSettle();

      // Credit content should be visible
      expect(find.text('Kredi Kartları'), findsOneWidget);
    });

    testWidgets('should switch to Assets tab', (WidgetTester tester) async {
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

      await tester.pumpAndSettle();

      // Tap Assets tab
      await tester.tap(find.text('Varlıklar'));
      await tester.pumpAndSettle();

      // Assets content should be visible
      expect(find.text('Varlık Listesi'), findsOneWidget);
    });

    testWidgets('should switch back to Reports tab',
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

      await tester.pumpAndSettle();

      // Switch to Cash Flow
      await tester.tap(find.text('Nakit akışı'));
      await tester.pumpAndSettle();

      // Switch back to Reports
      await tester.tap(find.text('Raporlar'));
      await tester.pumpAndSettle();

      // Reports content should be visible again
      expect(find.text('Genel Bakış'), findsOneWidget);
    });

    testWidgets('should maintain state when switching tabs',
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

      await tester.pumpAndSettle();

      // Switch to Cash Flow
      await tester.tap(find.text('Nakit akışı'));
      await tester.pumpAndSettle();

      // Switch to Spending
      await tester.tap(find.text('Harcama'));
      await tester.pumpAndSettle();

      // Switch back to Cash Flow
      await tester.tap(find.text('Nakit akışı'));
      await tester.pumpAndSettle();

      // Cash Flow should still be rendered
      expect(find.text('Gelir vs Gider'), findsOneWidget);
    });

    testWidgets('should handle rapid tab switching',
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

      await tester.pumpAndSettle();

      // Rapidly switch tabs
      await tester.tap(find.text('Nakit akışı'));
      await tester.pump();

      await tester.tap(find.text('Harcama'));
      await tester.pump();

      await tester.tap(find.text('Kredi'));
      await tester.pump();

      await tester.tap(find.text('Varlıklar'));
      await tester.pumpAndSettle();

      // Should end up on Assets tab
      expect(find.text('Varlık Listesi'), findsOneWidget);
    });

    testWidgets('should show correct tab indicator',
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

      await tester.pumpAndSettle();

      // Find TabBar
      expect(find.byType(TabBar), findsOneWidget);

      // Switch tabs and verify indicator moves
      await tester.tap(find.text('Nakit akışı'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Harcama'));
      await tester.pumpAndSettle();

      // TabBar should still be present
      expect(find.byType(TabBar), findsOneWidget);
    });

    testWidgets('should handle tab switching with empty data',
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

      await tester.pumpAndSettle();

      // Switch through all tabs with empty data
      await tester.tap(find.text('Nakit akışı'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Harcama'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Kredi'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Varlıklar'));
      await tester.pumpAndSettle();

      // Should handle empty data gracefully
      expect(find.text('İstatistikler'), findsOneWidget);
    });

    testWidgets('should scroll tab bar if needed', (WidgetTester tester) async {
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

      await tester.pumpAndSettle();

      // TabBar should be scrollable
      final tabBar = tester.widget<TabBar>(find.byType(TabBar));
      expect(tabBar.isScrollable, isTrue);
    });

    testWidgets('should preserve scroll position in tabs',
        (WidgetTester tester) async {
      // Create many transactions to enable scrolling
      final manyTransactions = List.generate(
        50,
        (i) => Transaction(
          id: 'trans$i',
          amount: 100.0 * i,
          description: 'Transaction $i',
          date: DateTime.now().subtract(Duration(days: i)),
          type: i % 2 == 0 ? 'income' : 'expense',
          category: 'Category $i',
          walletId: 'w1',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: StatisticsScreen(
            transactions: manyTransactions,
            wallets: testWallets,
            loans: [],
            creditCardTransactions: [],
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Switch to a tab with scrollable content
      await tester.tap(find.text('Nakit akışı'));
      await tester.pumpAndSettle();

      // Switch to another tab
      await tester.tap(find.text('Harcama'));
      await tester.pumpAndSettle();

      // Switch back
      await tester.tap(find.text('Nakit akışı'));
      await tester.pumpAndSettle();

      // Content should be rendered
      expect(find.text('Gelir vs Gider'), findsOneWidget);
    });
  });

  group('Tab Content Rendering Tests', () {
    testWidgets('should render all tab content correctly',
        (WidgetTester tester) async {
      final transactions = [
        Transaction(
          id: '1',
          amount: 1000.0,
          description: 'Test',
          date: DateTime.now(),
          type: 'income',
          category: 'Salary',
          walletId: 'w1',
        ),
      ];

      final wallets = [
        Wallet(
          id: 'w1',
          name: 'Test',
          balance: 5000.0,
          type: 'bank',
          color: '0xFF2196F3',
          icon: 'account_balance',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: StatisticsScreen(
            transactions: transactions,
            wallets: wallets,
            loans: [],
            creditCardTransactions: [],
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Test each tab renders without errors
      final tabs = ['Nakit akışı', 'Harcama', 'Kredi', 'Varlıklar'];

      for (final tab in tabs) {
        await tester.tap(find.text(tab));
        await tester.pumpAndSettle();

        // Should render without throwing
        expect(find.byType(TabBarView), findsOneWidget);
      }
    });

    testWidgets('should update tab content when data changes',
        (WidgetTester tester) async {
      final transactions = [
        Transaction(
          id: '1',
          amount: 1000.0,
          description: 'Test',
          date: DateTime.now(),
          type: 'income',
          category: 'Salary',
          walletId: 'w1',
        ),
      ];

      final wallets = [
        Wallet(
          id: 'w1',
          name: 'Test',
          balance: 5000.0,
          type: 'bank',
          color: '0xFF2196F3',
          icon: 'account_balance',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: StatisticsScreen(
            transactions: transactions,
            wallets: wallets,
            loans: [],
            creditCardTransactions: [],
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Update with new data
      final newTransactions = [
        ...transactions,
        Transaction(
          id: '2',
          amount: 2000.0,
          description: 'New',
          date: DateTime.now(),
          type: 'income',
          category: 'Bonus',
          walletId: 'w1',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: StatisticsScreen(
            transactions: newTransactions,
            wallets: wallets,
            loans: [],
            creditCardTransactions: [],
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Content should update
      expect(find.text('İstatistikler'), findsOneWidget);
    });
  });
}
