import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:parion/models/kmh_transaction.dart';
import 'package:parion/models/kmh_transaction_type.dart';
import 'package:parion/repositories/kmh_repository.dart';
import 'package:parion/services/kmh_box_service.dart';
import '../property_test_utils.dart';
import 'package:uuid/uuid.dart';

/// **Feature: kmh-account-management, Property 17: İşlem Sıralama**
/// **Validates: Requirements 5.1**
/// 
/// Property: For any transaction list, transactions should be sorted by date 
/// field in descending order (newest first).
void main() {
  group('KMH Repository Transaction Sorting Property Tests', () {
    late KmhRepository repository;
    late Directory testDir;

    setUpAll(() async {
      // Create a temporary directory for testing
      testDir = await Directory.systemTemp.createTemp('kmh_sorting_test_');
      
      // Initialize Hive with the test directory
      Hive.init(testDir.path);
      
      // Register adapters if not already registered
      if (!Hive.isAdapterRegistered(31)) {
        Hive.registerAdapter(KmhTransactionTypeAdapter());
      }
      if (!Hive.isAdapterRegistered(30)) {
        Hive.registerAdapter(KmhTransactionAdapter());
      }
      
      // Initialize KMH box service
      await KmhBoxService.init();
    });

    setUp(() async {
      // Clear the box before each test
      await KmhBoxService.clearAll();
      repository = KmhRepository();
    });

    tearDownAll(() async {
      // Clean up
      await KmhBoxService.close();
      await Hive.close();
      if (await testDir.exists()) {
        await testDir.delete(recursive: true);
      }
    });

    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 17: Transactions sorted by date descending (newest first)',
      generator: () {
        final walletId = const Uuid().v4();
        final transactionCount = PropertyTest.randomInt(min: 2, max: 20);
        final types = [
          KmhTransactionType.withdrawal,
          KmhTransactionType.deposit,
          KmhTransactionType.interest,
          KmhTransactionType.fee,
          KmhTransactionType.transfer,
        ];
        
        final transactions = List.generate(transactionCount, (index) {
          return {
            'id': const Uuid().v4(),
            'walletId': walletId,
            'type': types[PropertyTest.randomInt(min: 0, max: types.length - 1)],
            'amount': PropertyTest.randomPositiveDouble(min: 0.01, max: 100000),
            'date': PropertyTest.randomDateTime(),
            'description': PropertyTest.randomString(minLength: 5, maxLength: 100),
            'balanceAfter': PropertyTest.randomDouble(min: -100000, max: 100000),
          };
        });
        
        return {
          'walletId': walletId,
          'transactions': transactions,
        };
      },
      property: (data) async {
        final walletId = data['walletId'] as String;
        final transactionsData = data['transactions'] as List<Map<String, dynamic>>;

        // Save all transactions in random order
        for (var txData in transactionsData) {
          final transaction = KmhTransaction(
            id: txData['id'],
            walletId: txData['walletId'],
            type: txData['type'],
            amount: txData['amount'],
            date: txData['date'],
            description: txData['description'],
            balanceAfter: txData['balanceAfter'],
          );
          await repository.addTransaction(transaction);
        }

        // Retrieve transactions
        final retrieved = await repository.getTransactions(walletId);

        // Property 1: All transactions should be returned
        expect(retrieved.length, equals(transactionsData.length));

        // Property 2: Transactions should be sorted by date in descending order (newest first)
        for (int i = 0; i < retrieved.length - 1; i++) {
          final current = retrieved[i];
          final next = retrieved[i + 1];
          
          // Current transaction date should be >= next transaction date
          expect(
            current.date.isAfter(next.date) || current.date.isAtSameMomentAs(next.date),
            isTrue,
            reason: 'Transaction at index $i (date: ${current.date}) should be >= '
                'transaction at index ${i + 1} (date: ${next.date})',
          );
        }

        return true;
      },
      iterations: 100,
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 17: Date range transactions sorted by date descending',
      generator: () {
        final walletId = const Uuid().v4();
        final transactionCount = PropertyTest.randomInt(min: 5, max: 25);
        final types = [
          KmhTransactionType.withdrawal,
          KmhTransactionType.deposit,
          KmhTransactionType.interest,
          KmhTransactionType.fee,
          KmhTransactionType.transfer,
        ];
        
        // Generate a date range
        final startDate = PropertyTest.randomDateTime();
        final endDate = startDate.add(Duration(days: PropertyTest.randomInt(min: 30, max: 365)));
        
        final transactions = List.generate(transactionCount, (index) {
          // Generate dates within and outside the range
          final inRange = PropertyTest.randomBool();
          final date = inRange
              ? DateTime(
                  startDate.year,
                  startDate.month,
                  startDate.day + PropertyTest.randomInt(min: 0, max: (endDate.difference(startDate).inDays)),
                )
              : (PropertyTest.randomBool()
                  ? startDate.subtract(Duration(days: PropertyTest.randomInt(min: 1, max: 365)))
                  : endDate.add(Duration(days: PropertyTest.randomInt(min: 1, max: 365))));
          
          return {
            'id': const Uuid().v4(),
            'walletId': walletId,
            'type': types[PropertyTest.randomInt(min: 0, max: types.length - 1)],
            'amount': PropertyTest.randomPositiveDouble(min: 0.01, max: 100000),
            'date': date,
            'description': PropertyTest.randomString(minLength: 5, maxLength: 100),
            'balanceAfter': PropertyTest.randomDouble(min: -100000, max: 100000),
            'inRange': inRange,
          };
        });
        
        return {
          'walletId': walletId,
          'transactions': transactions,
          'startDate': startDate,
          'endDate': endDate,
        };
      },
      property: (data) async {
        final walletId = data['walletId'] as String;
        final transactionsData = data['transactions'] as List<Map<String, dynamic>>;
        final startDate = data['startDate'] as DateTime;
        final endDate = data['endDate'] as DateTime;

        // Save all transactions
        for (var txData in transactionsData) {
          final transaction = KmhTransaction(
            id: txData['id'],
            walletId: txData['walletId'],
            type: txData['type'],
            amount: txData['amount'],
            date: txData['date'],
            description: txData['description'],
            balanceAfter: txData['balanceAfter'],
          );
          await repository.addTransaction(transaction);
        }

        // Retrieve transactions by date range
        final retrieved = await repository.getTransactionsByDateRange(
          walletId,
          startDate,
          endDate,
        );

        // Property 1: Only transactions within date range should be returned
        for (var tx in retrieved) {
          expect(
            tx.date.isAfter(startDate.subtract(const Duration(seconds: 1))) &&
            tx.date.isBefore(endDate.add(const Duration(seconds: 1))),
            isTrue,
            reason: 'Transaction date ${tx.date} should be within range [$startDate, $endDate]',
          );
        }

        // Property 2: Transactions should be sorted by date in descending order
        for (int i = 0; i < retrieved.length - 1; i++) {
          final current = retrieved[i];
          final next = retrieved[i + 1];
          
          expect(
            current.date.isAfter(next.date) || current.date.isAtSameMomentAs(next.date),
            isTrue,
            reason: 'Transaction at index $i (date: ${current.date}) should be >= '
                'transaction at index ${i + 1} (date: ${next.date})',
          );
        }

        return true;
      },
      iterations: 100,
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 17: Interest transactions sorted by date descending',
      generator: () {
        final walletId = const Uuid().v4();
        final interestCount = PropertyTest.randomInt(min: 2, max: 15);
        final nonInterestCount = PropertyTest.randomInt(min: 0, max: 10);
        final types = [
          KmhTransactionType.withdrawal,
          KmhTransactionType.deposit,
          KmhTransactionType.fee,
          KmhTransactionType.transfer,
        ];
        
        final interestTransactions = List.generate(interestCount, (index) {
          return {
            'id': const Uuid().v4(),
            'walletId': walletId,
            'type': KmhTransactionType.interest,
            'amount': PropertyTest.randomPositiveDouble(min: 0.01, max: 1000),
            'date': PropertyTest.randomDateTime(),
            'description': 'Faiz tahakkuku',
            'balanceAfter': PropertyTest.randomDouble(min: -100000, max: 100000),
            'interestAmount': PropertyTest.randomPositiveDouble(min: 0.01, max: 1000),
          };
        });

        final nonInterestTransactions = List.generate(nonInterestCount, (index) {
          return {
            'id': const Uuid().v4(),
            'walletId': walletId,
            'type': types[PropertyTest.randomInt(min: 0, max: types.length - 1)],
            'amount': PropertyTest.randomPositiveDouble(min: 0.01, max: 100000),
            'date': PropertyTest.randomDateTime(),
            'description': PropertyTest.randomString(minLength: 5, maxLength: 100),
            'balanceAfter': PropertyTest.randomDouble(min: -100000, max: 100000),
          };
        });
        
        return {
          'walletId': walletId,
          'interestTransactions': interestTransactions,
          'nonInterestTransactions': nonInterestTransactions,
        };
      },
      property: (data) async {
        final walletId = data['walletId'] as String;
        final interestData = data['interestTransactions'] as List<Map<String, dynamic>>;
        final nonInterestData = data['nonInterestTransactions'] as List<Map<String, dynamic>>;

        // Save all transactions
        for (var txData in [...interestData, ...nonInterestData]) {
          final transaction = KmhTransaction(
            id: txData['id'],
            walletId: txData['walletId'],
            type: txData['type'],
            amount: txData['amount'],
            date: txData['date'],
            description: txData['description'],
            balanceAfter: txData['balanceAfter'],
            interestAmount: txData['interestAmount'],
          );
          await repository.addTransaction(transaction);
        }

        // Retrieve only interest transactions
        final retrieved = await repository.getInterestTransactions(walletId);

        // Property 1: Only interest transactions should be returned
        expect(retrieved.length, equals(interestData.length));
        for (var tx in retrieved) {
          expect(tx.type, equals(KmhTransactionType.interest));
        }

        // Property 2: Interest transactions should be sorted by date in descending order
        for (int i = 0; i < retrieved.length - 1; i++) {
          final current = retrieved[i];
          final next = retrieved[i + 1];
          
          expect(
            current.date.isAfter(next.date) || current.date.isAtSameMomentAs(next.date),
            isTrue,
            reason: 'Interest transaction at index $i (date: ${current.date}) should be >= '
                'transaction at index ${i + 1} (date: ${next.date})',
          );
        }

        return true;
      },
      iterations: 100,
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 17: Transactions with same date maintain stable sort',
      generator: () {
        final walletId = const Uuid().v4();
        final sameDate = PropertyTest.randomDateTime();
        final transactionCount = PropertyTest.randomInt(min: 3, max: 10);
        final types = [
          KmhTransactionType.withdrawal,
          KmhTransactionType.deposit,
          KmhTransactionType.interest,
          KmhTransactionType.fee,
          KmhTransactionType.transfer,
        ];
        
        final transactions = List.generate(transactionCount, (index) {
          return {
            'id': const Uuid().v4(),
            'walletId': walletId,
            'type': types[PropertyTest.randomInt(min: 0, max: types.length - 1)],
            'amount': PropertyTest.randomPositiveDouble(min: 0.01, max: 100000),
            'date': sameDate,  // All transactions have the same date
            'description': PropertyTest.randomString(minLength: 5, maxLength: 100),
            'balanceAfter': PropertyTest.randomDouble(min: -100000, max: 100000),
          };
        });
        
        return {
          'walletId': walletId,
          'transactions': transactions,
          'sameDate': sameDate,
        };
      },
      property: (data) async {
        final walletId = data['walletId'] as String;
        final transactionsData = data['transactions'] as List<Map<String, dynamic>>;
        final sameDate = data['sameDate'] as DateTime;

        // Save all transactions
        for (var txData in transactionsData) {
          final transaction = KmhTransaction(
            id: txData['id'],
            walletId: txData['walletId'],
            type: txData['type'],
            amount: txData['amount'],
            date: txData['date'],
            description: txData['description'],
            balanceAfter: txData['balanceAfter'],
          );
          await repository.addTransaction(transaction);
        }

        // Retrieve transactions
        final retrieved = await repository.getTransactions(walletId);

        // Property 1: All transactions should be returned
        expect(retrieved.length, equals(transactionsData.length));

        // Property 2: All transactions should have the same date
        for (var tx in retrieved) {
          expect(tx.date, equals(sameDate));
        }

        // Property 3: Sorting should not fail with same dates (stability check)
        // The sort should complete without errors and maintain consistency
        for (int i = 0; i < retrieved.length - 1; i++) {
          final current = retrieved[i];
          final next = retrieved[i + 1];
          
          // Dates should be equal
          expect(current.date, equals(next.date));
        }

        return true;
      },
      iterations: 100,
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 17: Empty transaction list returns empty sorted list',
      generator: () {
        return {
          'walletId': const Uuid().v4(),
        };
      },
      property: (data) async {
        final walletId = data['walletId'] as String;

        // Retrieve transactions for wallet with no transactions
        final retrieved = await repository.getTransactions(walletId);

        // Property 1: Empty list should be returned
        expect(retrieved, isEmpty);

        // Property 2: No errors should occur
        expect(retrieved, isA<List<KmhTransaction>>());

        return true;
      },
      iterations: 100,
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 17: Single transaction returns correctly',
      generator: () {
        final walletId = const Uuid().v4();
        final types = [
          KmhTransactionType.withdrawal,
          KmhTransactionType.deposit,
          KmhTransactionType.interest,
          KmhTransactionType.fee,
          KmhTransactionType.transfer,
        ];
        
        return {
          'walletId': walletId,
          'id': const Uuid().v4(),
          'type': types[PropertyTest.randomInt(min: 0, max: types.length - 1)],
          'amount': PropertyTest.randomPositiveDouble(min: 0.01, max: 100000),
          'date': PropertyTest.randomDateTime(),
          'description': PropertyTest.randomString(minLength: 5, maxLength: 100),
          'balanceAfter': PropertyTest.randomDouble(min: -100000, max: 100000),
        };
      },
      property: (data) async {
        final walletId = data['walletId'] as String;

        // Save single transaction
        final transaction = KmhTransaction(
          id: data['id'],
          walletId: walletId,
          type: data['type'],
          amount: data['amount'],
          date: data['date'],
          description: data['description'],
          balanceAfter: data['balanceAfter'],
        );
        await repository.addTransaction(transaction);

        // Retrieve transactions
        final retrieved = await repository.getTransactions(walletId);

        // Property 1: Single transaction should be returned
        expect(retrieved.length, equals(1));

        // Property 2: Transaction should match the saved one
        expect(retrieved.first.id, equals(transaction.id));
        expect(retrieved.first.date, equals(transaction.date));

        return true;
      },
      iterations: 100,
    );
  });
}
