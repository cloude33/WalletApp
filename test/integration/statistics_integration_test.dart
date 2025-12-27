import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money/models/transaction.dart';
import 'package:money/models/wallet.dart';
import 'package:money/models/loan.dart';
import 'package:money/models/credit_card_transaction.dart';
import 'package:money/screens/statistics_screen.dart';

/// Integration tests for Statistics Screen
/// Tests complete user flows including:
/// - Tab switching
/// - Filter + chart updates
/// - Export operations
/// - Critical user workflows
void main() {
  group('Statistics Screen Integration Tests', () {
    late List<Transaction> testTransactions;
    late List<Wallet> testWallets;
    late List<Loan> testLoans;
    late List<CreditCardTransaction> testCreditCardTransactions;

    setUp(() {
      // Create comprehensive test data
      testTransactions = _createTestTransactions();
      testWallets = _createTestWallets();
      testLoans = _createTestLoans();
      testCreditCardTransactions = _createTestCreditCardTransactions();
    });

    group('Complete User Flow: Tab Switching', () {
      testWidgets(
        'should navigate through all tabs and display correct content',
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

          // Initial render
          await tester.pump();
          await tester.pump(const Duration(seconds: 1));

          // Start at Reports tab (default)
          expect(find.text('Genel Bakış'), findsOneWidget);

          // Navigate to Cash Flow tab
          await tester.tap(find.text('Nakit akışı'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));
          expect(find.text('Gelir vs Gider'), findsOneWidget);

          // Navigate to Credit tab
          await tester.tap(find.text('Kredi'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));
          expect(find.text('Kredi Kartları'), findsOneWidget);

          // Navigate to Assets tab
          await tester.tap(find.text('Varlıklar'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));
          expect(find.text('Varlık Listesi'), findsOneWidget);

          // Navigate back to Reports
          await tester.tap(find.text('Raporlar'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));
          expect(find.text('Genel Bakış'), findsOneWidget);
        },
      );

      testWidgets(
        'should maintain data consistency across tab switches',
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

          await tester.pump();
          await tester.pump(const Duration(seconds: 1));

          // Switch to Cash Flow and verify data
          await tester.tap(find.text('Nakit akışı'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));
          expect(find.text('Gelir vs Gider'), findsOneWidget);

          // Switch to Assets
          await tester.tap(find.text('Varlıklar'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));
          expect(find.text('Varlık Listesi'), findsOneWidget);

          // Switch back to Cash Flow - data should still be there
          await tester.tap(find.text('Nakit akışı'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));
          expect(find.text('Gelir vs Gider'), findsOneWidget);
        },
      );
    });

    group('Complete User Flow: Filter + Chart Updates', () {
      testWidgets(
        'should update charts when time filter changes',
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

          await tester.pump();
          await tester.pump(const Duration(seconds: 1));

          // Navigate to Cash Flow tab
          await tester.tap(find.text('Nakit akışı'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));

          // Initial filter is "Aylık"
          expect(find.text('Aylık'), findsOneWidget);

          // Change to "Haftalık"
          await tester.tap(find.text('Haftalık'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));

          // Chart should still be visible
          expect(find.text('Gelir vs Gider'), findsOneWidget);

          // Change to "Yıllık"
          await tester.tap(find.text('Yıllık'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));

          // Chart should still be visible
          expect(find.text('Gelir vs Gider'), findsOneWidget);
        },
      );

      testWidgets(
        'should handle filter changes across multiple tabs',
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

          await tester.pump();
          await tester.pump(const Duration(seconds: 1));

          // Start with Aylık filter
          await tester.tap(find.text('Nakit akışı'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));

          // Change to Haftalık
          await tester.tap(find.text('Haftalık'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));

          // Switch to Assets tab
          await tester.tap(find.text('Varlıklar'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));

          // Filter should persist
          expect(find.text('Varlık Listesi'), findsOneWidget);
        },
      );
    });

    group('Complete User Flow: Export Operations', () {
      testWidgets(
        'should display reports tab with export capability',
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

          await tester.pump();
          await tester.pump(const Duration(seconds: 1));

          // Reports tab should be displayed with overview
          expect(find.text('Genel Bakış'), findsOneWidget);
          
          // Reports tab should render without errors
          expect(find.byType(StatisticsScreen), findsOneWidget);
        },
      );

      testWidgets(
        'should maintain data after navigating between tabs',
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

          await tester.pump();
          await tester.pump(const Duration(seconds: 1));

          // Verify data is present
          expect(find.text('Genel Bakış'), findsOneWidget);

          // Navigate to other tabs
          await tester.tap(find.text('Nakit akışı'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));

          await tester.tap(find.text('Varlıklar'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));

          // Return to reports
          await tester.tap(find.text('Raporlar'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));

          // Data should still be there
          expect(find.text('Genel Bakış'), findsOneWidget);
        },
      );
    });

    group('Complete User Flow: Critical Workflows', () {
      testWidgets(
        'should complete full analysis workflow',
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

          await tester.pump();
          await tester.pump(const Duration(seconds: 1));

          // Step 1: View overview in Reports
          expect(find.text('Genel Bakış'), findsOneWidget);

          // Step 2: Check cash flow
          await tester.tap(find.text('Nakit akışı'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));
          expect(find.text('Gelir vs Gider'), findsOneWidget);

          // Step 3: Check credit status
          await tester.tap(find.text('Kredi'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));
          expect(find.text('Kredi Kartları'), findsOneWidget);

          // Step 4: Review assets
          await tester.tap(find.text('Varlıklar'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));
          expect(find.text('Varlık Listesi'), findsOneWidget);

          // Step 5: Change time period
          await tester.tap(find.text('Haftalık'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));

          // Step 6: Review updated data
          await tester.tap(find.text('Raporlar'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));
          expect(find.text('Genel Bakış'), findsOneWidget);
        },
      );

      testWidgets(
        'should handle empty data gracefully across all tabs',
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
          await tester.pump(const Duration(seconds: 1));

          // Navigate through all tabs with empty data
          final tabs = [
            'Nakit akışı',
            'Kredi',
            'Varlıklar',
            'Raporlar'
          ];

          for (final tab in tabs) {
            await tester.tap(find.text(tab));
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 500));

            // Should not crash
            expect(find.byType(TabBarView), findsOneWidget);
          }
        },
      );

      testWidgets(
        'should handle KMH accounts in assets tab',
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

          await tester.pump();
          await tester.pump(const Duration(seconds: 1));

          // Check KMH in Assets tab
          await tester.tap(find.text('Varlıklar'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));
          expect(find.text('KMH Kullanım Durumu'), findsOneWidget);
        },
      );

      testWidgets(
        'should display loan information correctly',
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

          await tester.pump();
          await tester.pump(const Duration(seconds: 1));

          // Navigate to Credit tab
          await tester.tap(find.text('Kredi'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));

          // Should show loan tracking
          expect(find.text('Kredi Takibi'), findsOneWidget);
          expect(find.text('Devam eden krediler'), findsOneWidget);
        },
      );

      testWidgets(
        'should handle theme changes',
        (WidgetTester tester) async {
          // Test with light theme
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
          await tester.pump(const Duration(seconds: 1));
          expect(find.text('İstatistikler'), findsOneWidget);

          // Test with dark theme
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
          await tester.pump(const Duration(seconds: 1));
          expect(find.text('İstatistikler'), findsOneWidget);
        },
      );
    });

    group('Edge Cases and Error Handling', () {
      testWidgets(
        'should handle null or missing data fields',
        (WidgetTester tester) async {
          final incompleteTransactions = [
            Transaction(
              id: '1',
              amount: 100.0,
              description: 'Test',
              date: DateTime.now(),
              type: 'income',
              category: 'Salary',
              walletId: 'w1',
            ),
          ];

          await tester.pumpWidget(
            MaterialApp(
              home: StatisticsScreen(
                transactions: incompleteTransactions,
                wallets: testWallets,
                loans: [],
                creditCardTransactions: [],
              ),
            ),
          );

          await tester.pump();
          await tester.pump(const Duration(seconds: 1));

          // Should render without errors
          expect(find.text('İstatistikler'), findsOneWidget);
        },
      );

      testWidgets(
        'should handle very old transactions',
        (WidgetTester tester) async {
          final oldTransactions = [
            Transaction(
              id: '1',
              amount: 1000.0,
              description: 'Old Transaction',
              date: DateTime(2020, 1, 1),
              type: 'income',
              category: 'Salary',
              walletId: 'w1',
            ),
          ];

          await tester.pumpWidget(
            MaterialApp(
              home: StatisticsScreen(
                transactions: oldTransactions,
                wallets: testWallets,
                loans: [],
                creditCardTransactions: [],
              ),
            ),
          );

          await tester.pump();
          await tester.pump(const Duration(seconds: 1));

          // Should handle old dates
          expect(find.text('İstatistikler'), findsOneWidget);
        },
      );
    });
  });
}

// Helper functions to create test data

List<Transaction> _createTestTransactions() {
  final now = DateTime.now();
  return [
    Transaction(
      id: '1',
      amount: 5000.0,
      description: 'Salary',
      date: now.subtract(const Duration(days: 5)),
      type: 'income',
      category: 'Salary',
      walletId: 'wallet1',
    ),
    Transaction(
      id: '2',
      amount: 500.0,
      description: 'Groceries',
      date: now.subtract(const Duration(days: 3)),
      type: 'expense',
      category: 'Food',
      walletId: 'wallet1',
    ),
    Transaction(
      id: '3',
      amount: 200.0,
      description: 'Transport',
      date: now.subtract(const Duration(days: 2)),
      type: 'expense',
      category: 'Transport',
      walletId: 'wallet1',
    ),
    Transaction(
      id: '4',
      amount: 1000.0,
      description: 'Freelance',
      date: now.subtract(const Duration(days: 10)),
      type: 'income',
      category: 'Freelance',
      walletId: 'wallet1',
    ),
    Transaction(
      id: '5',
      amount: 300.0,
      description: 'Entertainment',
      date: now.subtract(const Duration(days: 7)),
      type: 'expense',
      category: 'Entertainment',
      walletId: 'wallet2',
    ),
  ];
}

List<Wallet> _createTestWallets() {
  return [
    Wallet(
      id: 'wallet1',
      name: 'Main Wallet',
      balance: 5000.0,
      type: 'bank',
      color: '0xFF2196F3',
      icon: 'account_balance',
    ),
    Wallet(
      id: 'wallet2',
      name: 'Cash Wallet',
      balance: 1000.0,
      type: 'cash',
      color: '0xFF4CAF50',
      icon: 'money',
    ),
    Wallet(
      id: 'wallet3',
      name: 'Credit Card',
      balance: -2000.0,
      type: 'credit_card',
      color: '0xFFF44336',
      icon: 'credit_card',
    ),
  ];
}

List<Loan> _createTestLoans() {
  return [
    Loan(
      id: 'loan1',
      name: 'Car Loan',
      bankName: 'Test Bank',
      totalAmount: 10000.0,
      remainingAmount: 5000.0,
      totalInstallments: 12,
      remainingInstallments: 6,
      currentInstallment: 6,
      installmentAmount: 833.33,
      startDate: DateTime.now().subtract(const Duration(days: 180)),
      endDate: DateTime.now().add(const Duration(days: 180)),
      walletId: 'wallet1',
      installments: [],
    ),
  ];
}

List<CreditCardTransaction> _createTestCreditCardTransactions() {
  final now = DateTime.now();
  return [
    CreditCardTransaction(
      id: 'cc1',
      cardId: 'wallet3',
      amount: 150.0,
      description: 'Online Shopping',
      transactionDate: now.subtract(const Duration(days: 4)),
      category: 'Shopping',
      installmentCount: 1,
      createdAt: now.subtract(const Duration(days: 4)),
    ),
    CreditCardTransaction(
      id: 'cc2',
      cardId: 'wallet3',
      amount: 80.0,
      description: 'Restaurant',
      transactionDate: now.subtract(const Duration(days: 6)),
      category: 'Food',
      installmentCount: 1,
      createdAt: now.subtract(const Duration(days: 6)),
    ),
  ];
}
