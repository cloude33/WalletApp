import 'package:flutter_test/flutter_test.dart';
import 'package:parion/models/transaction.dart';
import 'package:parion/models/credit_card_transaction.dart';
import 'package:parion/services/transaction_filter_service.dart';

void main() {
  group('TransactionFilterService - Search Tests', () {
    late List<Transaction> testTransactions;
    late List<CreditCardTransaction> testCreditCardTransactions;

    setUp(() {
      // Create test transactions
      testTransactions = [
        Transaction(
          id: '1',
          amount: 100.0,
          description: 'Market alışverişi',
          category: 'Gıda',
          type: 'expense',
          date: DateTime(2024, 1, 15),
          walletId: 'wallet1',
        ),
        Transaction(
          id: '2',
          amount: 50.0,
          description: 'Kahve',
          category: 'Yemek',
          type: 'expense',
          date: DateTime(2024, 1, 16),
          walletId: 'wallet1',
        ),
        Transaction(
          id: '3',
          amount: 200.0,
          description: 'Maaş',
          category: 'Gelir',
          type: 'income',
          date: DateTime(2024, 1, 20),
          walletId: 'wallet1',
        ),
        Transaction(
          id: '4',
          amount: 75.0,
          description: 'Benzin',
          category: 'Ulaşım',
          type: 'expense',
          date: DateTime(2024, 1, 22),
          walletId: 'wallet2',
        ),
      ];

      testCreditCardTransactions = [
        CreditCardTransaction(
          id: 'cc1',
          amount: 150.0,
          description: 'Online alışveriş',
          category: 'Alışveriş',
          transactionDate: DateTime(2024, 1, 18),
          cardId: 'card1',
          installmentCount: 1,
          createdAt: DateTime(2024, 1, 18),
        ),
        CreditCardTransaction(
          id: 'cc2',
          amount: 80.0,
          description: 'Restaurant',
          category: 'Yemek',
          transactionDate: DateTime(2024, 1, 19),
          cardId: 'card1',
          installmentCount: 1,
          createdAt: DateTime(2024, 1, 19),
        ),
      ];
    });

    test('should return all transactions when query is empty', () {
      final allTransactions = [
        ...testTransactions,
        ...testCreditCardTransactions
      ];
      
      final result = TransactionFilterService.searchTransactions(
        transactions: allTransactions,
        query: '',
      );

      expect(result.length, equals(6));
    });

    test('should search by description - exact match', () {
      final allTransactions = [
        ...testTransactions,
        ...testCreditCardTransactions
      ];
      
      final result = TransactionFilterService.searchTransactions(
        transactions: allTransactions,
        query: 'Market',
      );

      expect(result.length, equals(1));
      expect((result[0] as Transaction).description, contains('Market'));
    });

    test('should search by description - case insensitive', () {
      final allTransactions = [
        ...testTransactions,
        ...testCreditCardTransactions
      ];
      
      final result = TransactionFilterService.searchTransactions(
        transactions: allTransactions,
        query: 'market',
      );

      expect(result.length, equals(1));
      expect((result[0] as Transaction).description.toLowerCase(),
          contains('market'));
    });

    test('should search by category', () {
      final allTransactions = [
        ...testTransactions,
        ...testCreditCardTransactions
      ];
      
      final result = TransactionFilterService.searchTransactions(
        transactions: allTransactions,
        query: 'Yemek',
      );

      expect(result.length, equals(2));
      for (var transaction in result) {
        if (transaction is Transaction) {
          expect(transaction.category, equals('Yemek'));
        } else if (transaction is CreditCardTransaction) {
          expect(transaction.category, equals('Yemek'));
        }
      }
    });

    test('should search credit card transactions', () {
      final allTransactions = [
        ...testTransactions,
        ...testCreditCardTransactions
      ];
      
      final result = TransactionFilterService.searchTransactions(
        transactions: allTransactions,
        query: 'Online',
      );

      expect(result.length, equals(1));
      expect(result[0], isA<CreditCardTransaction>());
      expect((result[0] as CreditCardTransaction).description,
          contains('Online'));
    });

    test('should perform fuzzy search', () {
      final allTransactions = [
        ...testTransactions,
        ...testCreditCardTransactions
      ];
      
      // Search for "mkt" should match "Market"
      final result = TransactionFilterService.searchTransactions(
        transactions: allTransactions,
        query: 'mkt',
      );

      expect(result.length, greaterThan(0));
    });

    test('should match partial words', () {
      final allTransactions = [
        ...testTransactions,
        ...testCreditCardTransactions
      ];
      
      final result = TransactionFilterService.searchTransactions(
        transactions: allTransactions,
        query: 'alış',
      );

      expect(result.length, greaterThan(0));
    });

    test('should return empty list when no matches found', () {
      final allTransactions = [
        ...testTransactions,
        ...testCreditCardTransactions
      ];
      
      final result = TransactionFilterService.searchTransactions(
        transactions: allTransactions,
        query: 'xyz123notfound',
      );

      expect(result.length, equals(0));
    });

    test('should search in both description and category', () {
      final allTransactions = [
        ...testTransactions,
        ...testCreditCardTransactions
      ];
      
      // "Yemek" appears in both category and description
      final result = TransactionFilterService.searchTransactions(
        transactions: allTransactions,
        query: 'Yemek',
      );

      expect(result.length, greaterThan(0));
    });

    test('fuzzy match should work correctly', () {
      // Test the fuzzy match algorithm directly
      expect(
        TransactionFilterService.searchTransactions(
          transactions: testTransactions,
          query: 'mkt',
        ).isNotEmpty,
        isTrue,
      );
    });

    test('should handle special characters in search', () {
      final specialTransaction = Transaction(
        id: '5',
        amount: 100.0,
        description: 'Test & Special',
        category: 'Test',
        type: 'expense',
        date: DateTime(2024, 1, 15),
        walletId: 'wallet1',
      );

      final result = TransactionFilterService.searchTransactions(
        transactions: [specialTransaction],
        query: '&',
      );

      expect(result.length, equals(1));
    });

    test('should handle Turkish characters', () {
      final turkishTransaction = Transaction(
        id: '6',
        amount: 100.0,
        description: 'Çiçek alışverişi',
        category: 'Hediye',
        type: 'expense',
        date: DateTime(2024, 1, 15),
        walletId: 'wallet1',
      );

      final result = TransactionFilterService.searchTransactions(
        transactions: [turkishTransaction],
        query: 'çiçek',
      );

      expect(result.length, equals(1));
    });

    test('should work with combined filters and search', () {
      // Create transactions with current dates
      final now = DateTime.now();
      final currentTransactions = [
        Transaction(
          id: '1',
          amount: 100.0,
          description: 'Market alışverişi',
          category: 'Gıda',
          type: 'expense',
          date: now,
          walletId: 'wallet1',
        ),
        Transaction(
          id: '2',
          amount: 50.0,
          description: 'Kahve',
          category: 'Yemek',
          type: 'expense',
          date: now,
          walletId: 'wallet1',
        ),
      ];

      // First filter by time
      final filtered = TransactionFilterService.filterByTime(
        transactions: currentTransactions,
        creditCardTransactions: [],
        timeFilter: 'Aylık',
      );

      // Then search
      final result = TransactionFilterService.searchTransactions(
        transactions: filtered,
        query: 'Market',
      );

      expect(result.length, equals(1));
    });
  });
}
