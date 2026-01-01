import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:parion/models/kmh_transaction.dart';
import 'package:parion/models/kmh_transaction_type.dart';
import 'package:parion/repositories/kmh_repository.dart';
import 'package:parion/services/kmh_box_service.dart';
import 'package:parion/services/kmh_service.dart';
import 'package:parion/services/data_service.dart';
import 'package:parion/services/kmh_interest_calculator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../property_test_utils.dart';
import 'package:uuid/uuid.dart';

/// **Feature: kmh-account-management, Property 19: Rapor Toplam Doğruluğu**
/// **Validates: Requirements 5.4**
///
/// Property: For any monthly report, total withdrawals = sum of withdrawal transactions,
/// total deposits = sum of deposit transactions, total interest = sum of interest transactions.
void main() {
  group('KMH Statement Totals Property Tests', () {
    late KmhService service;
    late KmhRepository repository;
    late DataService dataService;
    late Directory testDir;

    setUpAll(() async {
      // Create a temporary directory for testing
      testDir = await Directory.systemTemp.createTemp('kmh_statement_test_');

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
          'Property 19: Report totals - withdrawals match sum of withdrawal transactions',
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

        // Calculate expected totals from transaction data
        final expectedWithdrawals = transactionsData
            .where((tx) => tx['type'] == KmhTransactionType.withdrawal)
            .fold<double>(0.0, (sum, tx) => sum + (tx['amount'] as double));

        final expectedDeposits = transactionsData
            .where((tx) => tx['type'] == KmhTransactionType.deposit)
            .fold<double>(0.0, (sum, tx) => sum + (tx['amount'] as double));

        final expectedInterest = transactionsData
            .where((tx) => tx['type'] == KmhTransactionType.interest)
            .fold<double>(0.0, (sum, tx) => sum + (tx['amount'] as double));

        // Property 1: Total withdrawals should match sum of withdrawal transactions
        expect(
          (statement.totalWithdrawals - expectedWithdrawals).abs(),
          lessThan(0.01),
          reason:
              'Total withdrawals ${statement.totalWithdrawals} should equal expected $expectedWithdrawals',
        );

        // Property 2: Total deposits should match sum of deposit transactions
        expect(
          (statement.totalDeposits - expectedDeposits).abs(),
          lessThan(0.01),
          reason:
              'Total deposits ${statement.totalDeposits} should equal expected $expectedDeposits',
        );

        // Property 3: Total interest should match sum of interest transactions
        expect(
          (statement.totalInterest - expectedInterest).abs(),
          lessThan(0.01),
          reason:
              'Total interest ${statement.totalInterest} should equal expected $expectedInterest',
        );

        return true;
      },
      iterations: 100,
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description:
          'Property 19: Report totals - all transaction types counted correctly',
      generator: () {
        // Generate a date range for the report
        final startDate = PropertyTest.randomDateTime(
          start: DateTime(2020, 1, 1),
          end: DateTime(2024, 12, 31),
        );
        final endDate = startDate.add(
          Duration(days: PropertyTest.randomInt(min: 28, max: 31)),
        );

        // Generate specific counts of each transaction type
        final withdrawalCount = PropertyTest.randomInt(min: 1, max: 10);
        final depositCount = PropertyTest.randomInt(min: 1, max: 10);
        final interestCount = PropertyTest.randomInt(min: 1, max: 10);
        final feeCount = PropertyTest.randomInt(min: 0, max: 5);
        final transferCount = PropertyTest.randomInt(min: 0, max: 5);

        final transactions = <Map<String, dynamic>>[];

        // Generate withdrawals
        for (int i = 0; i < withdrawalCount; i++) {
          final daysDiff = endDate.difference(startDate).inDays;
          final randomDays = PropertyTest.randomInt(min: 0, max: daysDiff);
          final date = startDate.add(Duration(days: randomDays));

          transactions.add({
            'id': const Uuid().v4(),
            'type': KmhTransactionType.withdrawal,
            'amount': PropertyTest.randomPositiveDouble(min: 0.01, max: 5000),
            'date': date,
            'description': 'Withdrawal $i',
          });
        }

        // Generate deposits
        for (int i = 0; i < depositCount; i++) {
          final daysDiff = endDate.difference(startDate).inDays;
          final randomDays = PropertyTest.randomInt(min: 0, max: daysDiff);
          final date = startDate.add(Duration(days: randomDays));

          transactions.add({
            'id': const Uuid().v4(),
            'type': KmhTransactionType.deposit,
            'amount': PropertyTest.randomPositiveDouble(min: 0.01, max: 5000),
            'date': date,
            'description': 'Deposit $i',
          });
        }

        // Generate interest
        for (int i = 0; i < interestCount; i++) {
          final daysDiff = endDate.difference(startDate).inDays;
          final randomDays = PropertyTest.randomInt(min: 0, max: daysDiff);
          final date = startDate.add(Duration(days: randomDays));

          transactions.add({
            'id': const Uuid().v4(),
            'type': KmhTransactionType.interest,
            'amount': PropertyTest.randomPositiveDouble(min: 0.01, max: 500),
            'date': date,
            'description': 'Interest $i',
          });
        }

        // Generate fees
        for (int i = 0; i < feeCount; i++) {
          final daysDiff = endDate.difference(startDate).inDays;
          final randomDays = PropertyTest.randomInt(min: 0, max: daysDiff);
          final date = startDate.add(Duration(days: randomDays));

          transactions.add({
            'id': const Uuid().v4(),
            'type': KmhTransactionType.fee,
            'amount': PropertyTest.randomPositiveDouble(min: 0.01, max: 100),
            'date': date,
            'description': 'Fee $i',
          });
        }

        // Generate transfers
        for (int i = 0; i < transferCount; i++) {
          final daysDiff = endDate.difference(startDate).inDays;
          final randomDays = PropertyTest.randomInt(min: 0, max: daysDiff);
          final date = startDate.add(Duration(days: randomDays));

          transactions.add({
            'id': const Uuid().v4(),
            'type': KmhTransactionType.transfer,
            'amount': PropertyTest.randomPositiveDouble(min: 0.01, max: 5000),
            'date': date,
            'description': 'Transfer $i',
          });
        }

        return {
          'transactions': transactions,
          'startDate': startDate,
          'endDate': endDate,
          'expectedWithdrawalCount': withdrawalCount,
          'expectedDepositCount': depositCount,
          'expectedInterestCount': interestCount,
        };
      },
      property: (data) async {
        final transactionsData =
            data['transactions'] as List<Map<String, dynamic>>;
        final startDate = data['startDate'] as DateTime;
        final endDate = data['endDate'] as DateTime;
        final expectedWithdrawalCount = data['expectedWithdrawalCount'] as int;
        final expectedDepositCount = data['expectedDepositCount'] as int;
        final expectedInterestCount = data['expectedInterestCount'] as int;

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

        // Calculate expected totals
        final expectedWithdrawals = transactionsData
            .where((tx) => tx['type'] == KmhTransactionType.withdrawal)
            .fold<double>(0.0, (sum, tx) => sum + (tx['amount'] as double));

        final expectedDeposits = transactionsData
            .where((tx) => tx['type'] == KmhTransactionType.deposit)
            .fold<double>(0.0, (sum, tx) => sum + (tx['amount'] as double));

        final expectedInterest = transactionsData
            .where((tx) => tx['type'] == KmhTransactionType.interest)
            .fold<double>(0.0, (sum, tx) => sum + (tx['amount'] as double));

        // Property 1: Total withdrawals should match sum
        expect(
          (statement.totalWithdrawals - expectedWithdrawals).abs(),
          lessThan(0.01),
          reason:
              'Total withdrawals should match sum of $expectedWithdrawalCount withdrawals',
        );

        // Property 2: Total deposits should match sum
        expect(
          (statement.totalDeposits - expectedDeposits).abs(),
          lessThan(0.01),
          reason:
              'Total deposits should match sum of $expectedDepositCount deposits',
        );

        // Property 3: Total interest should match sum
        expect(
          (statement.totalInterest - expectedInterest).abs(),
          lessThan(0.01),
          reason:
              'Total interest should match sum of $expectedInterestCount interest transactions',
        );

        // Property 4: Transaction count should match
        expect(
          statement.transactionCount,
          equals(transactionsData.length),
          reason:
              'Statement should contain all ${transactionsData.length} transactions',
        );

        return true;
      },
      iterations: 100,
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description:
          'Property 19: Report totals - zero totals when no transactions of that type',
      generator: () {
        // Generate a date range for the report
        final startDate = PropertyTest.randomDateTime(
          start: DateTime(2020, 1, 1),
          end: DateTime(2024, 12, 31),
        );
        final endDate = startDate.add(
          Duration(days: PropertyTest.randomInt(min: 28, max: 31)),
        );

        // Generate transactions of only one type
        final typeChoice = PropertyTest.randomInt(min: 0, max: 2);
        final selectedType = [
          KmhTransactionType.withdrawal,
          KmhTransactionType.deposit,
          KmhTransactionType.interest,
        ][typeChoice];

        final transactionCount = PropertyTest.randomInt(min: 3, max: 15);

        final transactions = List.generate(transactionCount, (index) {
          final daysDiff = endDate.difference(startDate).inDays;
          final randomDays = PropertyTest.randomInt(min: 0, max: daysDiff);
          final date = startDate.add(Duration(days: randomDays));

          return {
            'id': const Uuid().v4(),
            'type': selectedType,
            'amount': PropertyTest.randomPositiveDouble(min: 0.01, max: 5000),
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
          'selectedType': selectedType,
        };
      },
      property: (data) async {
        final transactionsData =
            data['transactions'] as List<Map<String, dynamic>>;
        final startDate = data['startDate'] as DateTime;
        final endDate = data['endDate'] as DateTime;
        final selectedType = data['selectedType'] as KmhTransactionType;

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

        // Calculate expected total for selected type
        final expectedTotal = transactionsData.fold<double>(
          0.0,
          (sum, tx) => sum + (tx['amount'] as double),
        );

        // Property 1: Selected type should have non-zero total
        if (selectedType == KmhTransactionType.withdrawal) {
          expect(
            statement.totalWithdrawals,
            greaterThan(0.0),
            reason: 'Total withdrawals should be greater than zero',
          );
          expect(
            (statement.totalWithdrawals - expectedTotal).abs(),
            lessThan(0.01),
            reason: 'Total withdrawals should match expected',
          );
        } else if (selectedType == KmhTransactionType.deposit) {
          expect(
            statement.totalDeposits,
            greaterThan(0.0),
            reason: 'Total deposits should be greater than zero',
          );
          expect(
            (statement.totalDeposits - expectedTotal).abs(),
            lessThan(0.01),
            reason: 'Total deposits should match expected',
          );
        } else if (selectedType == KmhTransactionType.interest) {
          expect(
            statement.totalInterest,
            greaterThan(0.0),
            reason: 'Total interest should be greater than zero',
          );
          expect(
            (statement.totalInterest - expectedTotal).abs(),
            lessThan(0.01),
            reason: 'Total interest should match expected',
          );
        }

        // Property 2: Other types should have zero total
        if (selectedType != KmhTransactionType.withdrawal) {
          expect(
            statement.totalWithdrawals,
            equals(0.0),
            reason: 'Total withdrawals should be zero when no withdrawals',
          );
        }
        if (selectedType != KmhTransactionType.deposit) {
          expect(
            statement.totalDeposits,
            equals(0.0),
            reason: 'Total deposits should be zero when no deposits',
          );
        }
        if (selectedType != KmhTransactionType.interest) {
          expect(
            statement.totalInterest,
            equals(0.0),
            reason: 'Total interest should be zero when no interest',
          );
        }

        return true;
      },
      iterations: 100,
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 19: Report totals - empty report has zero totals',
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

        // Property 1: All totals should be zero
        expect(
          statement.totalWithdrawals,
          equals(0.0),
          reason: 'Total withdrawals should be zero for empty report',
        );

        expect(
          statement.totalDeposits,
          equals(0.0),
          reason: 'Total deposits should be zero for empty report',
        );

        expect(
          statement.totalInterest,
          equals(0.0),
          reason: 'Total interest should be zero for empty report',
        );

        // Property 2: Transaction count should be zero
        expect(
          statement.transactionCount,
          equals(0),
          reason: 'Transaction count should be zero for empty report',
        );

        // Property 3: Net change should be zero
        expect(
          statement.netChange,
          equals(0.0),
          reason: 'Net change should be zero for empty report',
        );

        return true;
      },
      iterations: 100,
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description:
          'Property 19: Report totals - balance consistency with totals',
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

        final transactions = List.generate(transactionCount, (index) {
          final daysDiff = endDate.difference(startDate).inDays;
          final randomDays = PropertyTest.randomInt(min: 0, max: daysDiff);
          final date = startDate.add(Duration(days: randomDays));

          // Mix of withdrawals, deposits, and interest
          final typeChoice = PropertyTest.randomInt(min: 0, max: 2);
          final type = [
            KmhTransactionType.withdrawal,
            KmhTransactionType.deposit,
            KmhTransactionType.interest,
          ][typeChoice];

          return {
            'id': const Uuid().v4(),
            'type': type,
            'amount': PropertyTest.randomPositiveDouble(min: 0.01, max: 5000),
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

        // Calculate expected net change from totals
        final expectedNetChange =
            statement.totalDeposits -
            statement.totalWithdrawals -
            statement.totalInterest;

        // Property 1: Net change should equal deposits - withdrawals - interest
        expect(
          (statement.netChange - expectedNetChange).abs(),
          lessThan(0.01),
          reason:
              'Net change ${statement.netChange} should equal deposits - withdrawals - interest = $expectedNetChange',
        );

        // Property 2: Closing balance should equal opening balance + net change
        final expectedClosingBalance =
            statement.openingBalance + statement.netChange;
        expect(
          (statement.closingBalance - expectedClosingBalance).abs(),
          lessThan(0.01),
          reason:
              'Closing balance ${statement.closingBalance} should equal opening balance + net change = $expectedClosingBalance',
        );

        return true;
      },
      iterations: 100,
    );
  });
}
