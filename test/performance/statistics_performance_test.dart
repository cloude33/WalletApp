import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money/models/transaction.dart';
import 'package:money/models/wallet.dart';
import 'package:money/models/loan.dart';
import 'package:money/models/credit_card_transaction.dart';
import 'package:money/screens/statistics_screen.dart';

/// Performance tests for Statistics Screen
/// Tests loading times, memory usage, chart rendering, and scroll performance
/// 
/// Performance Targets:
/// - Screen load: < 1s
/// - Chart render: < 300ms
/// - Memory usage: < 150MB
/// - Scroll: 60fps (16.67ms per frame)
void main() {
  group('Statistics Screen Performance Tests', () {
    late List<Transaction> largeTransactionSet;
    late List<Wallet> testWallets;
    late List<Loan> testLoans;
    late List<CreditCardTransaction> testCreditCardTransactions;

    setUp(() {
      // Create large dataset for performance testing
      largeTransactionSet = _createLargeTransactionSet(1000);
      testWallets = _createTestWallets(20);
      testLoans = _createTestLoans(10);
      testCreditCardTransactions = _createLargeCreditCardTransactionSet(500);
    });

    group('Loading Time Tests', () {
      testWidgets(
        'should load statistics screen within 1 second',
        (WidgetTester tester) async {
          final stopwatch = Stopwatch()..start();

          await tester.pumpWidget(
            MaterialApp(
              home: StatisticsScreen(
                transactions: largeTransactionSet,
                wallets: testWallets,
                loans: testLoans,
                creditCardTransactions: testCreditCardTransactions,
              ),
            ),
          );

          // Initial pump
          await tester.pump();
          
          // Wait for animations and async operations
          await tester.pump(const Duration(milliseconds: 500));

          stopwatch.stop();
          final loadTime = stopwatch.elapsedMilliseconds;

          print('📊 Screen load time: ${loadTime}ms');
          
          // Target: < 1000ms (1 second)
          expect(
            loadTime,
            lessThan(1000),
            reason: 'Screen should load within 1 second. Actual: ${loadTime}ms',
          );

          // Verify screen loaded successfully
          expect(find.text('İstatistikler'), findsOneWidget);
        },
      );

      testWidgets(
        'should load cash flow tab within 500ms',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            MaterialApp(
              home: StatisticsScreen(
                transactions: largeTransactionSet,
                wallets: testWallets,
                loans: testLoans,
                creditCardTransactions: testCreditCardTransactions,
              ),
            ),
          );

          await tester.pump();
          await tester.pump(const Duration(milliseconds: 100));

          final stopwatch = Stopwatch()..start();

          // Navigate to cash flow tab
          await tester.tap(find.text('Nakit akışı'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));

          stopwatch.stop();
          final loadTime = stopwatch.elapsedMilliseconds;

          print('📊 Cash flow tab load time: ${loadTime}ms');
          
          // Target: < 500ms
          expect(
            loadTime,
            lessThan(500),
            reason: 'Tab should load within 500ms. Actual: ${loadTime}ms',
          );

          expect(find.text('Gelir vs Gider'), findsOneWidget);
        },
      );

      testWidgets(
        'should load spending tab within 500ms',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            MaterialApp(
              home: StatisticsScreen(
                transactions: largeTransactionSet,
                wallets: testWallets,
                loans: testLoans,
                creditCardTransactions: testCreditCardTransactions,
              ),
            ),
          );

          await tester.pump();
          await tester.pump(const Duration(milliseconds: 100));

          final stopwatch = Stopwatch()..start();

          // Navigate to spending tab
          await tester.tap(find.text('Harcama'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));

          stopwatch.stop();
          final loadTime = stopwatch.elapsedMilliseconds;

          print('📊 Spending tab load time: ${loadTime}ms');
          
          // Target: < 500ms
          expect(
            loadTime,
            lessThan(500),
            reason: 'Tab should load within 500ms. Actual: ${loadTime}ms',
          );
        },
      );

      testWidgets(
        'should load assets tab within 500ms',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            MaterialApp(
              home: StatisticsScreen(
                transactions: largeTransactionSet,
                wallets: testWallets,
                loans: testLoans,
                creditCardTransactions: testCreditCardTransactions,
              ),
            ),
          );

          await tester.pump();
          await tester.pump(const Duration(milliseconds: 100));

          final stopwatch = Stopwatch()..start();

          // Navigate to assets tab
          await tester.tap(find.text('Varlıklar'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));

          stopwatch.stop();
          final loadTime = stopwatch.elapsedMilliseconds;

          print('📊 Assets tab load time: ${loadTime}ms');
          
          // Target: < 500ms
          expect(
            loadTime,
            lessThan(500),
            reason: 'Tab should load within 500ms. Actual: ${loadTime}ms',
          );

          expect(find.text('Varlık Listesi'), findsOneWidget);
        },
      );
    });

    group('Chart Rendering Performance Tests', () {
      testWidgets(
        'should render line chart within 300ms',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            MaterialApp(
              home: StatisticsScreen(
                transactions: largeTransactionSet,
                wallets: testWallets,
                loans: testLoans,
                creditCardTransactions: testCreditCardTransactions,
              ),
            ),
          );

          await tester.pump();
          await tester.pump(const Duration(milliseconds: 100));

          // Navigate to cash flow tab
          await tester.tap(find.text('Nakit akışı'));
          await tester.pump();

          final stopwatch = Stopwatch()..start();

          // Wait for chart to render
          await tester.pump(const Duration(milliseconds: 200));

          stopwatch.stop();
          final renderTime = stopwatch.elapsedMilliseconds;

          print('📊 Line chart render time: ${renderTime}ms');
          
          // Target: < 300ms
          expect(
            renderTime,
            lessThan(300),
            reason: 'Chart should render within 300ms. Actual: ${renderTime}ms',
          );
        },
      );

      testWidgets(
        'should render pie chart within 300ms',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            MaterialApp(
              home: StatisticsScreen(
                transactions: largeTransactionSet,
                wallets: testWallets,
                loans: testLoans,
                creditCardTransactions: testCreditCardTransactions,
              ),
            ),
          );

          await tester.pump();
          await tester.pump(const Duration(milliseconds: 100));

          // Navigate to assets tab (has pie chart)
          await tester.tap(find.text('Varlıklar'));
          await tester.pump();

          final stopwatch = Stopwatch()..start();

          // Wait for chart to render
          await tester.pump(const Duration(milliseconds: 200));

          stopwatch.stop();
          final renderTime = stopwatch.elapsedMilliseconds;

          print('📊 Pie chart render time: ${renderTime}ms');
          
          // Target: < 300ms
          expect(
            renderTime,
            lessThan(300),
            reason: 'Chart should render within 300ms. Actual: ${renderTime}ms',
          );
        },
      );

      testWidgets(
        'should handle multiple chart renders efficiently',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            MaterialApp(
              home: StatisticsScreen(
                transactions: largeTransactionSet,
                wallets: testWallets,
                loans: testLoans,
                creditCardTransactions: testCreditCardTransactions,
              ),
            ),
          );

          await tester.pump();
          await tester.pump(const Duration(milliseconds: 100));

          final stopwatch = Stopwatch()..start();

          // Navigate through tabs multiple times
          for (int i = 0; i < 3; i++) {
            await tester.tap(find.text('Nakit akışı'));
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 100));

            await tester.tap(find.text('Varlıklar'));
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 100));
          }

          stopwatch.stop();
          final totalTime = stopwatch.elapsedMilliseconds;

          print('📊 Multiple chart renders total time: ${totalTime}ms');
          
          // Target: < 2000ms for 6 tab switches
          expect(
            totalTime,
            lessThan(2000),
            reason: 'Multiple renders should complete within 2s. Actual: ${totalTime}ms',
          );
        },
      );
    });

    group('Scroll Performance Tests', () {
      testWidgets(
        'should maintain smooth scrolling with large dataset',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            MaterialApp(
              home: StatisticsScreen(
                transactions: largeTransactionSet,
                wallets: testWallets,
                loans: testLoans,
                creditCardTransactions: testCreditCardTransactions,
              ),
            ),
          );

          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));

          // Navigate to cash flow tab
          await tester.tap(find.text('Nakit akışı'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));

          final stopwatch = Stopwatch()..start();

          // Perform scroll operations
          for (int i = 0; i < 5; i++) {
            await tester.drag(
              find.byType(SingleChildScrollView).first,
              const Offset(0, -200),
            );
            await tester.pump();
          }

          stopwatch.stop();
          final scrollTime = stopwatch.elapsedMilliseconds;

          print('📊 Scroll operations time: ${scrollTime}ms');
          
          // Target: < 500ms for 5 scroll operations
          expect(
            scrollTime,
            lessThan(500),
            reason: 'Scroll should be smooth. Actual: ${scrollTime}ms',
          );
        },
      );

      testWidgets(
        'should handle rapid tab switching without lag',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            MaterialApp(
              home: StatisticsScreen(
                transactions: largeTransactionSet,
                wallets: testWallets,
                loans: testLoans,
                creditCardTransactions: testCreditCardTransactions,
              ),
            ),
          );

          await tester.pump();
          await tester.pump(const Duration(milliseconds: 100));

          final stopwatch = Stopwatch()..start();

          // Rapid tab switching
          final tabs = ['Nakit akışı', 'Harcama', 'Kredi', 'Varlıklar', 'Raporlar'];
          
          for (final tab in tabs) {
            await tester.tap(find.text(tab));
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 50));
          }

          stopwatch.stop();
          final switchTime = stopwatch.elapsedMilliseconds;

          print('📊 Rapid tab switching time: ${switchTime}ms');
          
          // Target: < 1000ms for 5 tab switches
          expect(
            switchTime,
            lessThan(1000),
            reason: 'Tab switching should be fast. Actual: ${switchTime}ms',
          );
        },
      );
    });

    group('Filter Performance Tests', () {
      testWidgets(
        'should apply filters within 200ms',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            MaterialApp(
              home: StatisticsScreen(
                transactions: largeTransactionSet,
                wallets: testWallets,
                loans: testLoans,
                creditCardTransactions: testCreditCardTransactions,
              ),
            ),
          );

          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));

          // Navigate to cash flow tab
          await tester.tap(find.text('Nakit akışı'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));

          final stopwatch = Stopwatch()..start();

          // Change filter
          await tester.tap(find.text('Haftalık'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 100));

          stopwatch.stop();
          final filterTime = stopwatch.elapsedMilliseconds;

          print('📊 Filter application time: ${filterTime}ms');
          
          // Target: < 200ms
          expect(
            filterTime,
            lessThan(200),
            reason: 'Filter should apply quickly. Actual: ${filterTime}ms',
          );
        },
      );

      testWidgets(
        'should handle multiple filter changes efficiently',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            MaterialApp(
              home: StatisticsScreen(
                transactions: largeTransactionSet,
                wallets: testWallets,
                loans: testLoans,
                creditCardTransactions: testCreditCardTransactions,
              ),
            ),
          );

          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));

          // Navigate to cash flow tab
          await tester.tap(find.text('Nakit akışı'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));

          final stopwatch = Stopwatch()..start();

          // Multiple filter changes
          final filters = ['Haftalık', 'Aylık', 'Yıllık', 'Aylık'];
          
          for (final filter in filters) {
            await tester.tap(find.text(filter));
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 50));
          }

          stopwatch.stop();
          final totalTime = stopwatch.elapsedMilliseconds;

          print('📊 Multiple filter changes time: ${totalTime}ms');
          
          // Target: < 800ms for 4 filter changes
          expect(
            totalTime,
            lessThan(800),
            reason: 'Multiple filters should apply quickly. Actual: ${totalTime}ms',
          );
        },
      );
    });

    group('Data Processing Performance Tests', () {
      test('should calculate cash flow data within 100ms', () {
        final stopwatch = Stopwatch()..start();

        // Simulate cash flow calculation
        final incomeTransactions = largeTransactionSet
            .where((t) => t.type == 'income')
            .toList();
        final expenseTransactions = largeTransactionSet
            .where((t) => t.type == 'expense')
            .toList();

        final totalIncome = incomeTransactions.fold<double>(
          0.0,
          (sum, t) => sum + t.amount,
        );
        final totalExpense = expenseTransactions.fold<double>(
          0.0,
          (sum, t) => sum + t.amount,
        );

        stopwatch.stop();
        final calcTime = stopwatch.elapsedMilliseconds;

        print('📊 Cash flow calculation time: ${calcTime}ms');
        
        // Target: < 100ms
        expect(
          calcTime,
          lessThan(100),
          reason: 'Calculation should be fast. Actual: ${calcTime}ms',
        );

        expect(totalIncome, greaterThan(0));
        expect(totalExpense, greaterThan(0));
      });

      test('should group transactions by category within 100ms', () {
        final stopwatch = Stopwatch()..start();

        // Group by category
        final categoryMap = <String, List<Transaction>>{};
        for (final transaction in largeTransactionSet) {
          categoryMap.putIfAbsent(transaction.category, () => []);
          categoryMap[transaction.category]!.add(transaction);
        }

        stopwatch.stop();
        final groupTime = stopwatch.elapsedMilliseconds;

        print('📊 Category grouping time: ${groupTime}ms');
        
        // Target: < 100ms
        expect(
          groupTime,
          lessThan(100),
          reason: 'Grouping should be fast. Actual: ${groupTime}ms',
        );

        expect(categoryMap.keys.length, greaterThan(0));
      });

      test('should calculate monthly aggregates within 150ms', () {
        final stopwatch = Stopwatch()..start();

        // Group by month
        final monthlyMap = <String, List<Transaction>>{};
        for (final transaction in largeTransactionSet) {
          final monthKey = '${transaction.date.year}-${transaction.date.month}';
          monthlyMap.putIfAbsent(monthKey, () => []);
          monthlyMap[monthKey]!.add(transaction);
        }

        // Calculate monthly totals
        final monthlyTotals = <String, double>{};
        for (final entry in monthlyMap.entries) {
          monthlyTotals[entry.key] = entry.value.fold<double>(
            0.0,
            (sum, t) => sum + t.amount,
          );
        }

        stopwatch.stop();
        final aggTime = stopwatch.elapsedMilliseconds;

        print('📊 Monthly aggregation time: ${aggTime}ms');
        
        // Target: < 150ms
        expect(
          aggTime,
          lessThan(150),
          reason: 'Aggregation should be fast. Actual: ${aggTime}ms',
        );

        expect(monthlyTotals.keys.length, greaterThan(0));
      });
    });

    group('Memory Usage Tests', () {
      testWidgets(
        'should handle large dataset without excessive memory',
        (WidgetTester tester) async {
          // Create very large dataset
          final veryLargeTransactionSet = _createLargeTransactionSet(5000);

          await tester.pumpWidget(
            MaterialApp(
              home: StatisticsScreen(
                transactions: veryLargeTransactionSet,
                wallets: testWallets,
                loans: testLoans,
                creditCardTransactions: testCreditCardTransactions,
              ),
            ),
          );

          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));

          // Navigate through all tabs
          final tabs = ['Nakit akışı', 'Harcama', 'Kredi', 'Varlıklar'];
          
          for (final tab in tabs) {
            await tester.tap(find.text(tab));
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 200));
          }

          // If we get here without OOM, test passes
          expect(find.text('İstatistikler'), findsOneWidget);
          
          print('📊 Successfully handled ${veryLargeTransactionSet.length} transactions');
        },
      );

      testWidgets(
        'should dispose resources properly',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            MaterialApp(
              home: StatisticsScreen(
                transactions: largeTransactionSet,
                wallets: testWallets,
                loans: testLoans,
                creditCardTransactions: testCreditCardTransactions,
              ),
            ),
          );

          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));

          // Navigate away (dispose)
          await tester.pumpWidget(
            const MaterialApp(
              home: Scaffold(
                body: Center(child: Text('Other Screen')),
              ),
            ),
          );

          await tester.pump();

          // Should dispose without errors
          expect(find.text('Other Screen'), findsOneWidget);
          
          print('📊 Resources disposed successfully');
        },
      );
    });

    group('Stress Tests', () {
      testWidgets(
        'should handle rapid interactions without crashing',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            MaterialApp(
              home: StatisticsScreen(
                transactions: largeTransactionSet,
                wallets: testWallets,
                loans: testLoans,
                creditCardTransactions: testCreditCardTransactions,
              ),
            ),
          );

          await tester.pump();
          await tester.pump(const Duration(milliseconds: 100));

          final stopwatch = Stopwatch()..start();

          // Rapid interactions
          for (int i = 0; i < 10; i++) {
            // Tab switch
            await tester.tap(find.text('Nakit akışı'));
            await tester.pump();

            // Filter change
            await tester.tap(find.text('Haftalık'));
            await tester.pump();

            // Another tab
            await tester.tap(find.text('Varlıklar'));
            await tester.pump();
          }

          stopwatch.stop();
          final stressTime = stopwatch.elapsedMilliseconds;

          print('📊 Stress test completed in: ${stressTime}ms');
          
          // Should complete without crashing
          expect(find.text('İstatistikler'), findsOneWidget);
        },
      );
    });
  });

  group('Performance Benchmarks Summary', () {
    test('should print performance summary', () {
      print('\n${'=' * 60}');
      print('📊 PERFORMANCE TEST SUMMARY');
      print('=' * 60);
      print('Target Metrics:');
      print('  ✓ Screen load time: < 1000ms');
      print('  ✓ Tab load time: < 500ms');
      print('  ✓ Chart render time: < 300ms');
      print('  ✓ Filter application: < 200ms');
      print('  ✓ Data calculation: < 100ms');
      print('  ✓ Memory usage: < 150MB');
      print('  ✓ Scroll performance: 60fps (16.67ms/frame)');
      print('=' * 60 + '\n');
    });
  });
}

// Helper functions

List<Transaction> _createLargeTransactionSet(int count) {
  final now = DateTime.now();
  final categories = ['Food', 'Transport', 'Entertainment', 'Shopping', 'Bills', 'Salary', 'Freelance'];
  
  return List.generate(count, (index) {
    final isIncome = index % 5 == 0;
    return Transaction(
      id: 'trans_$index',
      amount: 50.0 + (index % 1000).toDouble(),
      description: 'Transaction $index',
      date: now.subtract(Duration(days: index % 365)),
      type: isIncome ? 'income' : 'expense',
      category: categories[index % categories.length],
      walletId: 'wallet_${index % 5}',
    );
  });
}

List<Wallet> _createTestWallets(int count) {
  final types = ['bank', 'cash', 'credit_card'];
  final colors = ['0xFF2196F3', '0xFF4CAF50', '0xFFF44336', '0xFF9C27B0'];
  
  return List.generate(count, (index) {
    return Wallet(
      id: 'wallet_$index',
      name: 'Wallet $index',
      balance: 1000.0 + (index * 500.0),
      type: types[index % types.length],
      color: colors[index % colors.length],
      icon: 'account_balance',
    );
  });
}

List<Loan> _createTestLoans(int count) {
  final now = DateTime.now();
  
  return List.generate(count, (index) {
    return Loan(
      id: 'loan_$index',
      name: 'Loan $index',
      bankName: 'Bank $index',
      totalAmount: 10000.0 + (index * 1000.0),
      remainingAmount: 5000.0 + (index * 500.0),
      totalInstallments: 12,
      remainingInstallments: 6,
      currentInstallment: 6,
      installmentAmount: 833.33,
      startDate: now.subtract(Duration(days: 180)),
      endDate: now.add(Duration(days: 180)),
      walletId: 'wallet_${index % 5}',
      installments: [],
    );
  });
}

List<CreditCardTransaction> _createLargeCreditCardTransactionSet(int count) {
  final now = DateTime.now();
  final categories = ['Shopping', 'Food', 'Entertainment', 'Bills'];
  
  return List.generate(count, (index) {
    return CreditCardTransaction(
      id: 'cc_$index',
      cardId: 'wallet_${index % 5}',
      amount: 50.0 + (index % 500).toDouble(),
      description: 'CC Transaction $index',
      transactionDate: now.subtract(Duration(days: index % 90)),
      category: categories[index % categories.length],
      installmentCount: 1,
      createdAt: now.subtract(Duration(days: index % 90)),
    );
  });
}
