import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:money/models/kmh_transaction.dart';
import 'package:money/models/kmh_transaction_type.dart';
import 'package:money/repositories/kmh_repository.dart';
import 'package:money/services/kmh_box_service.dart';
import 'package:money/services/kmh_service.dart';
import 'package:money/services/data_service.dart';
import 'package:money/services/kmh_interest_calculator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../property_test_utils.dart';
import 'package:uuid/uuid.dart';

/// **Feature: kmh-account-management, Property 20: Ekstre Veri Bütünlüğü**
/// **Validates: Requirements 5.5**
///
/// Property: For any KMH statement, each transaction must have date, type, amount, and balanceAfter fields.
void main() {
  group('KMH Statement Data Integrity Property Tests', () {
    late KmhService service;
    late KmhRepository repository;
    late DataService dataService;
    late Directory testDir;

    setUpAll(() async {
      // Create a temporary directory for testing
      testDir = await Directory.systemTemp.createTemp(
        'kmh_statement_integrity_',
      );

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
      // Initialize SharedPreferences with empty data for each test
      SharedPreferences.setMockInitialValues({});

      // Clear the box before each test
      await KmhBoxService.clearAll();

      // Initialize services
      dataService = DataService();
      await dataService.init();
      repository = KmhRepository();
      service = KmhService(
        repository: repository,
        dataService: dataService,
        calculator: KmhInterestCalculator(),
      );
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
      description:
          'Property 20: Statement data integrity - all transactions have required fields',
      generator: () {
        // Generate a date range for the report
        final startDate = PropertyTest.randomDateTime(
          start: DateTime(2020, 1, 1),
          end: DateTime(2024, 12, 31),
        );
        final endDate = startDate.add(
          Duration(days: PropertyTest.randomInt(min: 28, max: 31)),
        );

        // Generate random transactions
        final transactionCount = PropertyTest.randomInt(min: 5, max: 30);
        final types = [
          KmhTransactionType.withdrawal,
          KmhTransactionType.deposit,
          KmhTransactionType.interest,
          KmhTransactionType.fee,
          KmhTransactionType.transfer,
        ];

        final transactions = List.generate(transactionCount, (index) {
          // Generate date within range
          final daysDiff = endDate.difference(startDate).inDays;
          final randomDays = PropertyTest.randomInt(min: 0, max: daysDiff);
          final date = startDate.add(Duration(days: randomDays));

          final type =
              types[PropertyTest.randomInt(min: 0, max: types.length - 1)];
          final amount = PropertyTest.randomPositiveDouble(
            min: 0.01,
            max: 10000,
          );

          return {
            'id': const Uuid().v4(),
            'type': type,
            'amount': amount,
            'date': date,
            'description': PropertyTest.randomString(
              minLength: 5,
              maxLength: 100,
            ),
          };
        });

        return {
          'transactions': transactions,
          'startDate': startDate,
          'endDate': endDate,
        };
      },
      property: (data) async {
        final transactionsData =
            data['transactions'] as List<Map<String, dynamic>>;
        final startDate = data['startDate'] as DateTime;
        final endDate = data['endDate'] as DateTime;

        // Create a KMH account
        final wallet = await service.createKmhAccount(
          bankName: 'Test Bank',
          creditLimit: 50000.0,
          interestRate: 24.0,
          initialBalance: 0.0,
        );

        // Calculate running balance and save transactions
        double currentBalance = wallet.balance;
        for (var txData in transactionsData) {
          final type = txData['type'] as KmhTransactionType;
          final amount = txData['amount'] as double;

          // Update balance based on transaction type
          if (type == KmhTransactionType.deposit) {
            currentBalance += amount;
          } else {
            currentBalance -= amount;
          }

          final transaction = KmhTransaction(
            id: txData['id'],
            walletId: wallet.id,
            type: type,
            amount: amount,
            date: txData['date'],
            description: txData['description'],
            balanceAfter: currentBalance,
            interestAmount: type == KmhTransactionType.interest ? amount : null,
          );

          await repository.addTransaction(transaction);
        }

        // Update wallet with final balance
        final updatedWallet = wallet.copyWith(balance: currentBalance);
        await dataService.updateWallet(updatedWallet);

        // Generate statement
        final statement = await service.generateStatement(
          wallet.id,
          startDate,
          endDate,
        );

        // Property 1: Every transaction in the statement must have a date
        for (var transaction in statement.transactions) {
          expect(
            transaction.date,
            isNotNull,
            reason: 'Transaction ${transaction.id} must have a date',
          );
        }

        // Property 2: Every transaction in the statement must have a type
        for (var transaction in statement.transactions) {
          expect(
            transaction.type,
            isNotNull,
            reason: 'Transaction ${transaction.id} must have a type',
          );
        }

        // Property 3: Every transaction in the statement must have an amount
        for (var transaction in statement.transactions) {
          expect(
            transaction.amount,
            isNotNull,
            reason: 'Transaction ${transaction.id} must have an amount',
          );
          expect(
            transaction.amount,
            greaterThan(0.0),
            reason: 'Transaction ${transaction.id} amount must be positive',
          );
        }

        // Property 4: Every transaction in the statement must have a balanceAfter
        for (var transaction in statement.transactions) {
          expect(
            transaction.balanceAfter,
            isNotNull,
            reason: 'Transaction ${transaction.id} must have a balanceAfter',
          );
        }

        return true;
      },
      iterations: 100,
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description:
          'Property 20: Statement data integrity - empty statement has no transactions',
      generator: () {
        // Generate a date range with no transactions
        final startDate = DateTime(2025, 6, 1);
        final endDate = DateTime(2025, 6, 30);

        return {'startDate': startDate, 'endDate': endDate};
      },
      property: (data) async {
        final startDate = data['startDate'] as DateTime;
        final endDate = data['endDate'] as DateTime;

        // Create a KMH account
        final wallet = await service.createKmhAccount(
          bankName: 'Test Bank',
          creditLimit: 50000.0,
          interestRate: 24.0,
          initialBalance: 0.0,
        );

        // Generate statement without any transactions
        final statement = await service.generateStatement(
          wallet.id,
          startDate,
          endDate,
        );

        // Property: Empty statement should have empty transaction list
        expect(
          statement.transactions,
          isEmpty,
          reason: 'Empty statement should have no transactions',
        );

        // Property: Transaction count should be zero
        expect(
          statement.transactionCount,
          equals(0),
          reason: 'Empty statement transaction count should be zero',
        );

        return true;
      },
      iterations: 100,
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description:
          'Property 20: Statement data integrity - transaction dates within range',
      generator: () {
        // Generate a date range for the report
        final startDate = PropertyTest.randomDateTime(
          start: DateTime(2020, 1, 1),
          end: DateTime(2024, 12, 31),
        );
        final endDate = startDate.add(
          Duration(days: PropertyTest.randomInt(min: 28, max: 31)),
        );

        // Generate random transactions within and outside the range
        final transactionCount = PropertyTest.randomInt(min: 10, max: 30);
        final types = [
          KmhTransactionType.withdrawal,
          KmhTransactionType.deposit,
          KmhTransactionType.interest,
        ];

        final transactions = List.generate(transactionCount, (index) {
          // Generate date within range
          final daysDiff = endDate.difference(startDate).inDays;
          final randomDays = PropertyTest.randomInt(min: 0, max: daysDiff);
          final date = startDate.add(Duration(days: randomDays));

          final type =
              types[PropertyTest.randomInt(min: 0, max: types.length - 1)];
          final amount = PropertyTest.randomPositiveDouble(
            min: 0.01,
            max: 10000,
          );

          return {
            'id': const Uuid().v4(),
            'type': type,
            'amount': amount,
            'date': date,
            'description': PropertyTest.randomString(
              minLength: 5,
              maxLength: 100,
            ),
          };
        });

        // Add some transactions outside the range
        final outsideCount = PropertyTest.randomInt(min: 3, max: 10);
        for (int i = 0; i < outsideCount; i++) {
          // Generate date before start or after end
          final beforeStart = PropertyTest.randomInt(min: 0, max: 1) == 0;
          final date = beforeStart
              ? startDate.subtract(
                  Duration(days: PropertyTest.randomInt(min: 1, max: 365)),
                )
              : endDate.add(
                  Duration(days: PropertyTest.randomInt(min: 1, max: 365)),
                );

          final type =
              types[PropertyTest.randomInt(min: 0, max: types.length - 1)];
          final amount = PropertyTest.randomPositiveDouble(
            min: 0.01,
            max: 10000,
          );

          transactions.add({
            'id': const Uuid().v4(),
            'type': type,
            'amount': amount,
            'date': date,
            'description': PropertyTest.randomString(
              minLength: 5,
              maxLength: 100,
            ),
          });
        }

        return {
          'transactions': transactions,
          'startDate': startDate,
          'endDate': endDate,
        };
      },
      property: (data) async {
        final transactionsData =
            data['transactions'] as List<Map<String, dynamic>>;
        final startDate = data['startDate'] as DateTime;
        final endDate = data['endDate'] as DateTime;

        // Create a KMH account
        final wallet = await service.createKmhAccount(
          bankName: 'Test Bank',
          creditLimit: 100000.0,
          interestRate: 24.0,
          initialBalance: 0.0,
        );

        // Calculate running balance and save transactions
        double currentBalance = wallet.balance;
        for (var txData in transactionsData) {
          final type = txData['type'] as KmhTransactionType;
          final amount = txData['amount'] as double;

          // Update balance based on transaction type
          if (type == KmhTransactionType.deposit) {
            currentBalance += amount;
          } else {
            currentBalance -= amount;
          }

          final transaction = KmhTransaction(
            id: txData['id'],
            walletId: wallet.id,
            type: type,
            amount: amount,
            date: txData['date'],
            description: txData['description'],
            balanceAfter: currentBalance,
            interestAmount: type == KmhTransactionType.interest ? amount : null,
          );

          await repository.addTransaction(transaction);
        }

        // Update wallet with final balance
        final updatedWallet = wallet.copyWith(balance: currentBalance);
        await dataService.updateWallet(updatedWallet);

        // Generate statement
        final statement = await service.generateStatement(
          wallet.id,
          startDate,
          endDate,
        );

        // Property: All transactions in statement must be within date range
        for (var transaction in statement.transactions) {
          expect(
            transaction.date.isAfter(
                  startDate.subtract(const Duration(seconds: 1)),
                ) &&
                transaction.date.isBefore(endDate.add(const Duration(days: 1))),
            isTrue,
            reason:
                'Transaction ${transaction.id} date ${transaction.date} must be within range [$startDate, $endDate]',
          );
        }

        // Property: Count transactions that should be in range
        final expectedCount = transactionsData.where((tx) {
          final date = tx['date'] as DateTime;
          return date.isAfter(startDate.subtract(const Duration(seconds: 1))) &&
              date.isBefore(endDate.add(const Duration(days: 1)));
        }).length;

        expect(
          statement.transactionCount,
          equals(expectedCount),
          reason:
              'Statement should contain exactly $expectedCount transactions within date range',
        );

        return true;
      },
      iterations: 100,
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description:
          'Property 20: Statement data integrity - balanceAfter sequence is consistent',
      generator: () {
        // Generate a date range for the report
        final startDate = PropertyTest.randomDateTime(
          start: DateTime(2020, 1, 1),
          end: DateTime(2024, 12, 31),
        );
        final endDate = startDate.add(
          Duration(days: PropertyTest.randomInt(min: 28, max: 31)),
        );

        // Generate random transactions
        final transactionCount = PropertyTest.randomInt(min: 5, max: 20);
        final types = [
          KmhTransactionType.withdrawal,
          KmhTransactionType.deposit,
          KmhTransactionType.interest,
        ];

        final transactions = List.generate(transactionCount, (index) {
          // Generate date within range
          final daysDiff = endDate.difference(startDate).inDays;
          final randomDays = PropertyTest.randomInt(min: 0, max: daysDiff);
          final date = startDate.add(Duration(days: randomDays));

          final type =
              types[PropertyTest.randomInt(min: 0, max: types.length - 1)];
          final amount = PropertyTest.randomPositiveDouble(
            min: 0.01,
            max: 5000,
          );

          return {
            'id': const Uuid().v4(),
            'type': type,
            'amount': amount,
            'date': date,
            'description': PropertyTest.randomString(
              minLength: 5,
              maxLength: 100,
            ),
          };
        });

        return {
          'transactions': transactions,
          'startDate': startDate,
          'endDate': endDate,
          'initialBalance': PropertyTest.randomDouble(min: -10000, max: 50000),
        };
      },
      property: (data) async {
        final transactionsData =
            data['transactions'] as List<Map<String, dynamic>>;
        final startDate = data['startDate'] as DateTime;
        final endDate = data['endDate'] as DateTime;
        final initialBalance = data['initialBalance'] as double;

        // Create a KMH account
        final wallet = await service.createKmhAccount(
          bankName: 'Test Bank',
          creditLimit: 100000.0,
          interestRate: 24.0,
          initialBalance: initialBalance,
        );

        // Calculate running balance and save transactions
        double currentBalance = wallet.balance;
        final expectedBalances = <String, double>{};

        for (var txData in transactionsData) {
          final type = txData['type'] as KmhTransactionType;
          final amount = txData['amount'] as double;

          // Update balance based on transaction type
          if (type == KmhTransactionType.deposit) {
            currentBalance += amount;
          } else {
            currentBalance -= amount;
          }

          expectedBalances[txData['id']] = currentBalance;

          final transaction = KmhTransaction(
            id: txData['id'],
            walletId: wallet.id,
            type: type,
            amount: amount,
            date: txData['date'],
            description: txData['description'],
            balanceAfter: currentBalance,
            interestAmount: type == KmhTransactionType.interest ? amount : null,
          );

          await repository.addTransaction(transaction);
        }

        // Update wallet with final balance
        final updatedWallet = wallet.copyWith(balance: currentBalance);
        await dataService.updateWallet(updatedWallet);

        // Generate statement
        final statement = await service.generateStatement(
          wallet.id,
          startDate,
          endDate,
        );

        // Property: Each transaction's balanceAfter must match the expected balance
        for (var transaction in statement.transactions) {
          final expectedBalance = expectedBalances[transaction.id];
          if (expectedBalance != null) {
            expect(
              (transaction.balanceAfter - expectedBalance).abs(),
              lessThan(0.01),
              reason:
                  'Transaction ${transaction.id} balanceAfter ${transaction.balanceAfter} must match expected $expectedBalance',
            );
          }
        }

        return true;
      },
      iterations: 100,
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description:
          'Property 20: Statement data integrity - all transaction types are valid',
      generator: () {
        // Generate a date range for the report
        final startDate = PropertyTest.randomDateTime(
          start: DateTime(2020, 1, 1),
          end: DateTime(2024, 12, 31),
        );
        final endDate = startDate.add(
          Duration(days: PropertyTest.randomInt(min: 28, max: 31)),
        );

        // Generate random transactions with all types
        final transactionCount = PropertyTest.randomInt(min: 10, max: 30);
        final types = [
          KmhTransactionType.withdrawal,
          KmhTransactionType.deposit,
          KmhTransactionType.interest,
          KmhTransactionType.fee,
          KmhTransactionType.transfer,
        ];

        final transactions = List.generate(transactionCount, (index) {
          // Generate date within range
          final daysDiff = endDate.difference(startDate).inDays;
          final randomDays = PropertyTest.randomInt(min: 0, max: daysDiff);
          final date = startDate.add(Duration(days: randomDays));

          final type =
              types[PropertyTest.randomInt(min: 0, max: types.length - 1)];
          final amount = PropertyTest.randomPositiveDouble(
            min: 0.01,
            max: 10000,
          );

          return {
            'id': const Uuid().v4(),
            'type': type,
            'amount': amount,
            'date': date,
            'description': PropertyTest.randomString(
              minLength: 5,
              maxLength: 100,
            ),
          };
        });

        return {
          'transactions': transactions,
          'startDate': startDate,
          'endDate': endDate,
        };
      },
      property: (data) async {
        final transactionsData =
            data['transactions'] as List<Map<String, dynamic>>;
        final startDate = data['startDate'] as DateTime;
        final endDate = data['endDate'] as DateTime;

        // Create a KMH account
        final wallet = await service.createKmhAccount(
          bankName: 'Test Bank',
          creditLimit: 100000.0,
          interestRate: 24.0,
          initialBalance: 50000.0,
        );

        // Calculate running balance and save transactions
        double currentBalance = wallet.balance;
        for (var txData in transactionsData) {
          final type = txData['type'] as KmhTransactionType;
          final amount = txData['amount'] as double;

          // Update balance based on transaction type
          if (type == KmhTransactionType.deposit) {
            currentBalance += amount;
          } else {
            currentBalance -= amount;
          }

          final transaction = KmhTransaction(
            id: txData['id'],
            walletId: wallet.id,
            type: type,
            amount: amount,
            date: txData['date'],
            description: txData['description'],
            balanceAfter: currentBalance,
            interestAmount: type == KmhTransactionType.interest ? amount : null,
          );

          await repository.addTransaction(transaction);
        }

        // Update wallet with final balance
        final updatedWallet = wallet.copyWith(balance: currentBalance);
        await dataService.updateWallet(updatedWallet);

        // Generate statement
        final statement = await service.generateStatement(
          wallet.id,
          startDate,
          endDate,
        );

        // Property: All transaction types must be valid KmhTransactionType values
        final validTypes = [
          KmhTransactionType.withdrawal,
          KmhTransactionType.deposit,
          KmhTransactionType.interest,
          KmhTransactionType.fee,
          KmhTransactionType.transfer,
        ];

        for (var transaction in statement.transactions) {
          expect(
            validTypes.contains(transaction.type),
            isTrue,
            reason:
                'Transaction ${transaction.id} type ${transaction.type} must be a valid KmhTransactionType',
          );
        }

        return true;
      },
      iterations: 100,
    );
  });
}
