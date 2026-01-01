import 'package:flutter_test/flutter_test.dart';
import 'package:parion/models/transaction.dart';
import 'package:parion/models/credit_card_transaction.dart';
import 'package:parion/services/transaction_filter_service.dart';

void main() {
  group('TransactionFilterService', () {
    late List<Transaction> testTransactions;
    late List<CreditCardTransaction> testCreditCardTransactions;

    setUp(() {
      final now = DateTime.now();
      
      // Create test transactions
      testTransactions = [
        Transaction(
          id: '1',
          amount: 100.0,
          description: 'Test 1',
          date: now,
          type: 'income',
          category: 'salary',
          walletId: 'wallet1',
        ),
        Transaction(
          id: '2',
          amount: 50.0,
          description: 'Test 2',
          date: now.subtract(const Duration(days: 5)),
          type: 'expense',
          category: 'food',
          walletId: 'wallet2',
        ),
        Transaction(
          id: '3',
          amount: 200.0,
          description: 'Test 3',
          date: now.subtract(const Duration(days: 40)),
          type: 'income',
          category: 'salary',
          walletId: 'wallet1',
        ),
        Transaction(
          id: '4',
          amount: 75.0,
          description: 'Test 4',
          date: now.subtract(const Duration(days: 400)),
          type: 'expense',
          category: 'shopping',
          walletId: 'wallet3',
        ),
      ];

      testCreditCardTransactions = [
        CreditCardTransaction(
          id: 'cc1',
          cardId: 'card1',
          amount: 120.0,
          description: 'CC Test 1',
          transactionDate: now,
          category: 'food',
          installmentCount: 1,
          createdAt: now,
        ),
        CreditCardTransaction(
          id: 'cc2',
          cardId: 'card2',
          amount: 80.0,
          description: 'CC Test 2',
          transactionDate: now.subtract(const Duration(days: 10)),
          category: 'shopping',
          installmentCount: 1,
          createdAt: now.subtract(const Duration(days: 10)),
        ),
      ];
    });

    group('filterByTime', () {
      test('filters transactions by daily period', () {
        final result = TransactionFilterService.filterByTime(
          transactions: testTransactions,
          creditCardTransactions: testCreditCardTransactions,
          timeFilter: 'Günlük',
        );

        // Should include today's transactions only
        expect(result.length, 2); // 1 regular + 1 credit card
      });

      test('filters transactions by weekly period', () {
        final result = TransactionFilterService.filterByTime(
          transactions: testTransactions,
          creditCardTransactions: testCreditCardTransactions,
          timeFilter: 'Haftalık',
        );

        // Should include last 7 days
        expect(result.length, 3); // 2 regular + 1 credit card
      });

      test('filters transactions by monthly period', () {
        final result = TransactionFilterService.filterByTime(
          transactions: testTransactions,
          creditCardTransactions: testCreditCardTransactions,
          timeFilter: 'Aylık',
        );

        // Should include current month
        expect(result.length, greaterThanOrEqualTo(2));
      });

      test('filters transactions by custom date range', () {
        final now = DateTime.now();
        final startDate = now.subtract(const Duration(days: 30));
        final endDate = now;

        final result = TransactionFilterService.filterByTime(
          transactions: testTransactions,
          creditCardTransactions: testCreditCardTransactions,
          timeFilter: 'Özel',
          customStartDate: startDate,
          customEndDate: endDate,
        );

        // Should include transactions within custom range
        expect(result.length, greaterThanOrEqualTo(2));
      });
    });

    group('filterByCategory', () {
      test('filters transactions by single category', () {
        final allTransactions = [
          ...testTransactions,
          ...testCreditCardTransactions,
        ];

        final result = TransactionFilterService.filterByCategory(
          transactions: allTransactions,
          categories: ['food'],
        );

        expect(result.length, 2); // 1 regular + 1 credit card with 'food'
        for (var t in result) {
          if (t is Transaction) {
            expect(t.category, 'food');
          } else if (t is CreditCardTransaction) {
            expect(t.category, 'food');
          }
        }
      });

      test('filters transactions by multiple categories', () {
        final allTransactions = [
          ...testTransactions,
          ...testCreditCardTransactions,
        ];

        final result = TransactionFilterService.filterByCategory(
          transactions: allTransactions,
          categories: ['food', 'shopping'],
        );

        // 1 regular transaction with 'food', 1 with 'shopping'
        // 1 credit card with 'food', 1 with 'shopping' = 4 total
        expect(result.length, 4);
      });

      test('returns all transactions when category is "all"', () {
        final allTransactions = [
          ...testTransactions,
          ...testCreditCardTransactions,
        ];

        final result = TransactionFilterService.filterByCategory(
          transactions: allTransactions,
          categories: ['all'],
        );

        expect(result.length, allTransactions.length);
      });

      test('returns all transactions when categories list is empty', () {
        final allTransactions = [
          ...testTransactions,
          ...testCreditCardTransactions,
        ];

        final result = TransactionFilterService.filterByCategory(
          transactions: allTransactions,
          categories: [],
        );

        expect(result.length, allTransactions.length);
      });
    });

    group('filterByWallet', () {
      test('filters transactions by single wallet', () {
        final allTransactions = [
          ...testTransactions,
          ...testCreditCardTransactions,
        ];

        final result = TransactionFilterService.filterByWallet(
          transactions: allTransactions,
          walletIds: ['wallet1'],
        );

        expect(result.length, 2); // 2 transactions with wallet1
        for (var t in result) {
          if (t is Transaction) {
            expect(t.walletId, 'wallet1');
          }
        }
      });

      test('filters transactions by multiple wallets', () {
        final allTransactions = [
          ...testTransactions,
          ...testCreditCardTransactions,
        ];

        final result = TransactionFilterService.filterByWallet(
          transactions: allTransactions,
          walletIds: ['wallet1', 'wallet2'],
        );

        expect(result.length, 3);
      });

      test('returns all transactions when wallet is "all"', () {
        final allTransactions = [
          ...testTransactions,
          ...testCreditCardTransactions,
        ];

        final result = TransactionFilterService.filterByWallet(
          transactions: allTransactions,
          walletIds: ['all'],
        );

        expect(result.length, allTransactions.length);
      });
    });

    group('filterByType', () {
      test('filters transactions by income type', () {
        final allTransactions = [
          ...testTransactions,
          ...testCreditCardTransactions,
        ];

        final result = TransactionFilterService.filterByType(
          transactions: allTransactions,
          type: 'income',
        );

        expect(result.length, 2); // 2 income transactions
        for (var t in result) {
          if (t is Transaction) {
            expect(t.type, 'income');
          }
        }
      });

      test('filters transactions by expense type', () {
        final allTransactions = [
          ...testTransactions,
          ...testCreditCardTransactions,
        ];

        final result = TransactionFilterService.filterByType(
          transactions: allTransactions,
          type: 'expense',
        );

        // Should include regular expenses + all credit card transactions
        expect(result.length, 4);
      });

      test('returns all transactions when type is "all"', () {
        final allTransactions = [
          ...testTransactions,
          ...testCreditCardTransactions,
        ];

        final result = TransactionFilterService.filterByType(
          transactions: allTransactions,
          type: 'all',
        );

        expect(result.length, allTransactions.length);
      });
    });

    group('applyFilters', () {
      test('applies multiple filters correctly', () {
        final result = TransactionFilterService.applyFilters(
          transactions: testTransactions,
          creditCardTransactions: testCreditCardTransactions,
          timeFilter: 'Haftalık',
          categories: ['food'],
          walletIds: null,
          transactionType: 'expense',
        );

        // Should filter by time (weekly), category (food), and type (expense)
        expect(result.isNotEmpty, true);
        for (var t in result) {
          if (t is Transaction) {
            expect(t.category, 'food');
            expect(t.type, 'expense');
          } else if (t is CreditCardTransaction) {
            expect(t.category, 'food');
          }
        }
      });

      test('applies all filters together', () {
        final result = TransactionFilterService.applyFilters(
          transactions: testTransactions,
          creditCardTransactions: testCreditCardTransactions,
          timeFilter: 'Aylık',
          categories: ['salary', 'food'],
          walletIds: ['wallet1', 'wallet2'],
          transactionType: null,
        );

        expect(result.isNotEmpty, true);
      });
    });

    group('clearFilters', () {
      test('returns all transactions when filters are cleared', () {
        final result = TransactionFilterService.clearFilters(
          transactions: testTransactions,
          creditCardTransactions: testCreditCardTransactions,
        );

        expect(
          result.length,
          testTransactions.length + testCreditCardTransactions.length,
        );
      });
    });

    group('getDateRange', () {
      test('returns correct date range for daily filter', () {
        final result = TransactionFilterService.getDateRange(
          timeFilter: 'Günlük',
        );

        expect(result['startDate'], isNotNull);
        expect(result['endDate'], isNotNull);
        
        final startDate = result['startDate'] as DateTime;
        final endDate = result['endDate'] as DateTime;
        
        expect(startDate.day, DateTime.now().day);
        expect(endDate.day, DateTime.now().day);
      });

      test('returns correct date range for monthly filter', () {
        final result = TransactionFilterService.getDateRange(
          timeFilter: 'Aylık',
        );

        expect(result['startDate'], isNotNull);
        expect(result['endDate'], isNotNull);
        
        final startDate = result['startDate'] as DateTime;
        
        expect(startDate.day, 1);
        expect(startDate.month, DateTime.now().month);
      });

      test('returns custom date range when provided', () {
        final customStart = DateTime(2024, 1, 1);
        final customEnd = DateTime(2024, 1, 31);

        final result = TransactionFilterService.getDateRange(
          timeFilter: 'Özel',
          customStartDate: customStart,
          customEndDate: customEnd,
        );

        expect(result['startDate'], customStart);
        expect(result['endDate'], customEnd);
      });
    });
  });
}
