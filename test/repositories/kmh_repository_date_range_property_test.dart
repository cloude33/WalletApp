import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:parion/models/kmh_transaction.dart';
import 'package:parion/models/kmh_transaction_type.dart';
import 'package:parion/repositories/kmh_repository.dart';
import 'package:parion/services/kmh_box_service.dart';
import '../property_test_utils.dart';
import 'package:uuid/uuid.dart';

/// **Feature: kmh-account-management, Property 18: Tarih Aralığı Filtreleme**
/// **Validates: Requirements 5.2**
/// 
/// Property: For any date range [start, end], returned transactions should only 
/// include transactions within that range and total interest should be calculated correctly.
void main() {
  group('KMH Repository Date Range Filtering Property Tests', () {
    late KmhRepository repository;
    late Directory testDir;

    setUpAll(() async {
      // Create a temporary directory for testing
      testDir = await Directory.systemTemp.createTemp('kmh_date_range_test_');
      
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
      description: 'Property 18: Date range filtering - only transactions within range returned',
      generator: () {
        final walletId = const Uuid().v4();
        
        // Generate a date range
        final startDate = PropertyTest.randomDateTime(
          start: DateTime(2020, 1, 1),
          end: DateTime(2024, 12, 31),
        );
        final endDate = startDate.add(
          Duration(days: PropertyTest.randomInt(min: 7, max: 365)),
        );
        
        // Generate transactions: some inside range, some outside
        final transactionCount = PropertyTest.randomInt(min: 5, max: 30);
        final types = [
          KmhTransactionType.withdrawal,
          KmhTransactionType.deposit,
          KmhTransactionType.interest,
          KmhTransactionType.fee,
          KmhTransactionType.transfer,
        ];
        
        final transactions = List.generate(transactionCount, (index) {
          // Randomly decide if transaction is inside or outside the range
          final inRange = PropertyTest.randomBool();
          
          DateTime date;
          if (inRange) {
            // Generate date within range
            final daysDiff = endDate.difference(startDate).inDays;
            final randomDays = PropertyTest.randomInt(min: 0, max: daysDiff);
            date = startDate.add(Duration(days: randomDays));
          } else {
            // Generate date outside range (before or after)
            if (PropertyTest.randomBool()) {
              // Before start date
              final daysBeforeStart = PropertyTest.randomInt(min: 1, max: 365);
              date = startDate.subtract(Duration(days: daysBeforeStart));
            } else {
              // After end date
              final daysAfterEnd = PropertyTest.randomInt(min: 1, max: 365);
              date = endDate.add(Duration(days: daysAfterEnd));
            }
          }
          
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

        // Count expected transactions in range
        final expectedInRange = transactionsData.where((tx) {
          final date = tx['date'] as DateTime;
          return date.isAfter(startDate.subtract(const Duration(seconds: 1))) &&
              date.isBefore(endDate.add(const Duration(seconds: 1)));
        }).length;

        // Property 1: Only transactions within date range should be returned
        expect(retrieved.length, equals(expectedInRange));

        // Property 2: All returned transactions should be within the date range
        for (var tx in retrieved) {
          expect(
            tx.date.isAfter(startDate.subtract(const Duration(seconds: 1))) &&
            tx.date.isBefore(endDate.add(const Duration(seconds: 1))),
            isTrue,
            reason: 'Transaction date ${tx.date} should be within range [$startDate, $endDate]',
          );
        }

        // Property 3: No transactions outside the range should be returned
        for (var tx in retrieved) {
          final originalTx = transactionsData.firstWhere((t) => t['id'] == tx.id);
          expect(
            originalTx['inRange'],
            isTrue,
            reason: 'Transaction ${tx.id} should have been marked as in range',
          );
        }

        return true;
      },
      iterations: 100,
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 18: Date range filtering - total interest calculated correctly',
      generator: () {
        final walletId = const Uuid().v4();
        
        // Generate a date range
        final startDate = PropertyTest.randomDateTime(
          start: DateTime(2020, 1, 1),
          end: DateTime(2024, 12, 31),
        );
        final endDate = startDate.add(
          Duration(days: PropertyTest.randomInt(min: 30, max: 365)),
        );
        
        // Generate transactions with interest transactions
        final transactionCount = PropertyTest.randomInt(min: 5, max: 25);
        final types = [
          KmhTransactionType.withdrawal,
          KmhTransactionType.deposit,
          KmhTransactionType.interest,
          KmhTransactionType.fee,
          KmhTransactionType.transfer,
        ];
        
        final transactions = List.generate(transactionCount, (index) {
          // Randomly decide if transaction is inside or outside the range
          final inRange = PropertyTest.randomBool();
          
          DateTime date;
          if (inRange) {
            // Generate date within range
            final daysDiff = endDate.difference(startDate).inDays;
            final randomDays = PropertyTest.randomInt(min: 0, max: daysDiff);
            date = startDate.add(Duration(days: randomDays));
          } else {
            // Generate date outside range
            if (PropertyTest.randomBool()) {
              final daysBeforeStart = PropertyTest.randomInt(min: 1, max: 365);
              date = startDate.subtract(Duration(days: daysBeforeStart));
            } else {
              final daysAfterEnd = PropertyTest.randomInt(min: 1, max: 365);
              date = endDate.add(Duration(days: daysAfterEnd));
            }
          }
          
          final type = types[PropertyTest.randomInt(min: 0, max: types.length - 1)];
          final amount = PropertyTest.randomPositiveDouble(min: 0.01, max: 10000);
          
          return {
            'id': const Uuid().v4(),
            'walletId': walletId,
            'type': type,
            'amount': amount,
            'date': date,
            'description': type == KmhTransactionType.interest 
                ? 'Faiz tahakkuku' 
                : PropertyTest.randomString(minLength: 5, maxLength: 100),
            'balanceAfter': PropertyTest.randomDouble(min: -100000, max: 100000),
            'interestAmount': type == KmhTransactionType.interest ? amount : null,
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
            interestAmount: txData['interestAmount'],
          );
          await repository.addTransaction(transaction);
        }

        // Calculate expected total interest for transactions in range
        final expectedTotalInterest = transactionsData.where((tx) {
          final date = tx['date'] as DateTime;
          final inRange = date.isAfter(startDate.subtract(const Duration(seconds: 1))) &&
              date.isBefore(endDate.add(const Duration(seconds: 1)));
          return inRange && tx['type'] == KmhTransactionType.interest;
        }).fold<double>(0.0, (sum, tx) => sum + (tx['amount'] as double));

        // Get total interest from repository
        final actualTotalInterest = await repository.getTotalInterest(
          walletId,
          startDate,
          endDate,
        );

        // Property 1: Total interest should match expected value
        expect(
          (actualTotalInterest - expectedTotalInterest).abs(),
          lessThan(0.01),
          reason: 'Total interest $actualTotalInterest should equal expected $expectedTotalInterest',
        );

        return true;
      },
      iterations: 100,
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 18: Date range filtering - boundary dates included correctly',
      generator: () {
        final walletId = const Uuid().v4();
        
        // Generate a date range
        final startDate = DateTime(
          PropertyTest.randomInt(min: 2020, max: 2024),
          PropertyTest.randomInt(min: 1, max: 12),
          PropertyTest.randomInt(min: 1, max: 28),
        );
        final endDate = startDate.add(
          Duration(days: PropertyTest.randomInt(min: 7, max: 90)),
        );
        
        // Generate transactions at boundaries and around them
        final transactions = [
          // Transaction exactly at start date
          {
            'id': const Uuid().v4(),
            'walletId': walletId,
            'type': KmhTransactionType.deposit,
            'amount': PropertyTest.randomPositiveDouble(min: 0.01, max: 1000),
            'date': startDate,
            'description': 'At start boundary',
            'balanceAfter': PropertyTest.randomDouble(min: -100000, max: 100000),
            'shouldBeIncluded': true,
          },
          // Transaction exactly at end date
          {
            'id': const Uuid().v4(),
            'walletId': walletId,
            'type': KmhTransactionType.withdrawal,
            'amount': PropertyTest.randomPositiveDouble(min: 0.01, max: 1000),
            'date': endDate,
            'description': 'At end boundary',
            'balanceAfter': PropertyTest.randomDouble(min: -100000, max: 100000),
            'shouldBeIncluded': true,
          },
          // Transaction just before start date
          {
            'id': const Uuid().v4(),
            'walletId': walletId,
            'type': KmhTransactionType.interest,
            'amount': PropertyTest.randomPositiveDouble(min: 0.01, max: 1000),
            'date': startDate.subtract(const Duration(seconds: 2)),
            'description': 'Before start boundary',
            'balanceAfter': PropertyTest.randomDouble(min: -100000, max: 100000),
            'shouldBeIncluded': false,
          },
          // Transaction just after end date
          {
            'id': const Uuid().v4(),
            'walletId': walletId,
            'type': KmhTransactionType.fee,
            'amount': PropertyTest.randomPositiveDouble(min: 0.01, max: 1000),
            'date': endDate.add(const Duration(seconds: 2)),
            'description': 'After end boundary',
            'balanceAfter': PropertyTest.randomDouble(min: -100000, max: 100000),
            'shouldBeIncluded': false,
          },
          // Transaction in the middle
          {
            'id': const Uuid().v4(),
            'walletId': walletId,
            'type': KmhTransactionType.transfer,
            'amount': PropertyTest.randomPositiveDouble(min: 0.01, max: 1000),
            'date': startDate.add(Duration(days: endDate.difference(startDate).inDays ~/ 2)),
            'description': 'In middle',
            'balanceAfter': PropertyTest.randomDouble(min: -100000, max: 100000),
            'shouldBeIncluded': true,
          },
        ];
        
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

        // Property 1: Correct number of transactions should be returned
        final expectedCount = transactionsData.where((tx) => tx['shouldBeIncluded'] == true).length;
        expect(retrieved.length, equals(expectedCount));

        // Property 2: All transactions that should be included are included
        for (var txData in transactionsData) {
          if (txData['shouldBeIncluded'] == true) {
            final found = retrieved.any((t) => t.id == txData['id']);
            expect(
              found,
              isTrue,
              reason: 'Transaction ${txData['id']} (${txData['description']}) should be included',
            );
          }
        }

        // Property 3: No transactions that should be excluded are included
        for (var txData in transactionsData) {
          if (txData['shouldBeIncluded'] == false) {
            final found = retrieved.any((t) => t.id == txData['id']);
            expect(
              found,
              isFalse,
              reason: 'Transaction ${txData['id']} (${txData['description']}) should be excluded',
            );
          }
        }

        return true;
      },
      iterations: 100,
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 18: Date range filtering - empty range returns no transactions',
      generator: () {
        final walletId = const Uuid().v4();
        
        // Generate a date range where no transactions exist
        final startDate = DateTime(2025, 1, 1);
        final endDate = DateTime(2025, 1, 7);
        
        // Generate transactions outside this range
        final transactionCount = PropertyTest.randomInt(min: 3, max: 15);
        final types = [
          KmhTransactionType.withdrawal,
          KmhTransactionType.deposit,
          KmhTransactionType.interest,
          KmhTransactionType.fee,
          KmhTransactionType.transfer,
        ];
        
        final transactions = List.generate(transactionCount, (index) {
          // All transactions are outside the range
          final date = PropertyTest.randomBool()
              ? DateTime(2024, 12, PropertyTest.randomInt(min: 1, max: 31))
              : DateTime(2025, 2, PropertyTest.randomInt(min: 1, max: 28));
          
          return {
            'id': const Uuid().v4(),
            'walletId': walletId,
            'type': types[PropertyTest.randomInt(min: 0, max: types.length - 1)],
            'amount': PropertyTest.randomPositiveDouble(min: 0.01, max: 10000),
            'date': date,
            'description': PropertyTest.randomString(minLength: 5, maxLength: 100),
            'balanceAfter': PropertyTest.randomDouble(min: -100000, max: 100000),
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

        // Property 1: No transactions should be returned
        expect(retrieved.length, equals(0));

        // Property 2: Total interest should be zero
        final totalInterest = await repository.getTotalInterest(walletId, startDate, endDate);
        expect(totalInterest, equals(0.0));

        return true;
      },
      iterations: 100,
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 18: Date range filtering - total withdrawals and deposits calculated correctly',
      generator: () {
        final walletId = const Uuid().v4();
        
        // Generate a date range
        final startDate = PropertyTest.randomDateTime(
          start: DateTime(2020, 1, 1),
          end: DateTime(2024, 12, 31),
        );
        final endDate = startDate.add(
          Duration(days: PropertyTest.randomInt(min: 30, max: 180)),
        );
        
        // Generate transactions
        final transactionCount = PropertyTest.randomInt(min: 10, max: 30);
        
        final transactions = List.generate(transactionCount, (index) {
          final inRange = PropertyTest.randomBool();
          
          DateTime date;
          if (inRange) {
            final daysDiff = endDate.difference(startDate).inDays;
            final randomDays = PropertyTest.randomInt(min: 0, max: daysDiff);
            date = startDate.add(Duration(days: randomDays));
          } else {
            if (PropertyTest.randomBool()) {
              final daysBeforeStart = PropertyTest.randomInt(min: 1, max: 365);
              date = startDate.subtract(Duration(days: daysBeforeStart));
            } else {
              final daysAfterEnd = PropertyTest.randomInt(min: 1, max: 365);
              date = endDate.add(Duration(days: daysAfterEnd));
            }
          }
          
          // Mix of withdrawal, deposit, and other types
          final typeChoice = PropertyTest.randomInt(min: 0, max: 4);
          final type = [
            KmhTransactionType.withdrawal,
            KmhTransactionType.deposit,
            KmhTransactionType.interest,
            KmhTransactionType.fee,
            KmhTransactionType.transfer,
          ][typeChoice];
          
          return {
            'id': const Uuid().v4(),
            'walletId': walletId,
            'type': type,
            'amount': PropertyTest.randomPositiveDouble(min: 0.01, max: 10000),
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

        // Calculate expected totals for transactions in range
        final expectedWithdrawals = transactionsData.where((tx) {
          final date = tx['date'] as DateTime;
          final inRange = date.isAfter(startDate.subtract(const Duration(seconds: 1))) &&
              date.isBefore(endDate.add(const Duration(seconds: 1)));
          return inRange && tx['type'] == KmhTransactionType.withdrawal;
        }).fold<double>(0.0, (sum, tx) => sum + (tx['amount'] as double));

        final expectedDeposits = transactionsData.where((tx) {
          final date = tx['date'] as DateTime;
          final inRange = date.isAfter(startDate.subtract(const Duration(seconds: 1))) &&
              date.isBefore(endDate.add(const Duration(seconds: 1)));
          return inRange && tx['type'] == KmhTransactionType.deposit;
        }).fold<double>(0.0, (sum, tx) => sum + (tx['amount'] as double));

        // Get totals from repository
        final actualWithdrawals = await repository.getTotalWithdrawals(
          walletId,
          startDate,
          endDate,
        );
        final actualDeposits = await repository.getTotalDeposits(
          walletId,
          startDate,
          endDate,
        );

        // Property 1: Total withdrawals should match expected value
        expect(
          (actualWithdrawals - expectedWithdrawals).abs(),
          lessThan(0.01),
          reason: 'Total withdrawals $actualWithdrawals should equal expected $expectedWithdrawals',
        );

        // Property 2: Total deposits should match expected value
        expect(
          (actualDeposits - expectedDeposits).abs(),
          lessThan(0.01),
          reason: 'Total deposits $actualDeposits should equal expected $expectedDeposits',
        );

        return true;
      },
      iterations: 100,
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 18: Date range filtering - single day range works correctly',
      generator: () {
        final walletId = const Uuid().v4();
        
        // Generate a single day range
        final targetDate = PropertyTest.randomDateTime(
          start: DateTime(2020, 1, 1),
          end: DateTime(2024, 12, 31),
        );
        
        // Generate transactions on and around the target date
        final transactions = [
          // Transaction on target date
          {
            'id': const Uuid().v4(),
            'walletId': walletId,
            'type': KmhTransactionType.deposit,
            'amount': PropertyTest.randomPositiveDouble(min: 0.01, max: 1000),
            'date': targetDate,
            'description': 'On target date',
            'balanceAfter': PropertyTest.randomDouble(min: -100000, max: 100000),
            'shouldBeIncluded': true,
          },
          // Transaction day before
          {
            'id': const Uuid().v4(),
            'walletId': walletId,
            'type': KmhTransactionType.withdrawal,
            'amount': PropertyTest.randomPositiveDouble(min: 0.01, max: 1000),
            'date': targetDate.subtract(const Duration(days: 1)),
            'description': 'Day before',
            'balanceAfter': PropertyTest.randomDouble(min: -100000, max: 100000),
            'shouldBeIncluded': false,
          },
          // Transaction day after
          {
            'id': const Uuid().v4(),
            'walletId': walletId,
            'type': KmhTransactionType.interest,
            'amount': PropertyTest.randomPositiveDouble(min: 0.01, max: 1000),
            'date': targetDate.add(const Duration(days: 1)),
            'description': 'Day after',
            'balanceAfter': PropertyTest.randomDouble(min: -100000, max: 100000),
            'shouldBeIncluded': false,
          },
        ];
        
        return {
          'walletId': walletId,
          'transactions': transactions,
          'targetDate': targetDate,
        };
      },
      property: (data) async {
        final walletId = data['walletId'] as String;
        final transactionsData = data['transactions'] as List<Map<String, dynamic>>;
        final targetDate = data['targetDate'] as DateTime;

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

        // Retrieve transactions for single day range
        final retrieved = await repository.getTransactionsByDateRange(
          walletId,
          targetDate,
          targetDate,
        );

        // Property 1: Only transaction on target date should be returned
        final expectedCount = transactionsData.where((tx) => tx['shouldBeIncluded'] == true).length;
        expect(retrieved.length, equals(expectedCount));

        // Property 2: Returned transaction should be on target date
        for (var tx in retrieved) {
          expect(
            tx.date.year == targetDate.year &&
            tx.date.month == targetDate.month &&
            tx.date.day == targetDate.day,
            isTrue,
            reason: 'Transaction date ${tx.date} should be on target date $targetDate',
          );
        }

        return true;
      },
      iterations: 100,
    );
  });
}
