import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:parion/models/kmh_transaction.dart';
import 'package:parion/models/kmh_transaction_type.dart';
import 'package:parion/services/kmh_service.dart';
import 'package:parion/services/data_service.dart';
import 'package:parion/services/kmh_box_service.dart';
import 'package:parion/repositories/kmh_repository.dart';
import 'package:parion/services/kmh_interest_calculator.dart';
import 'package:parion/services/kmh_interest_settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../property_test_utils.dart';

/// **Feature: kmh-account-management, Property 12: Faiz Tahakkuk Etkisi**
/// **Validates: Requirements 3.4**
///
/// Property: For any interest accrual operation, the account balance should
/// decrease by the interest amount and an interest type transaction record should be created.
void main() {
  group('KmhService Interest Accrual Property Tests', () {
    late KmhService service;
    late DataService dataService;
    late KmhRepository repository;

    late KmhInterestCalculator calculator;
    late KmhInterestSettingsService settingsService;
    late Directory testDir;

    setUpAll(() async {
      // Create a temporary directory for testing
      testDir = await Directory.systemTemp.createTemp('kmh_interest_test_');

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
      calculator = KmhInterestCalculator();
      settingsService = KmhInterestSettingsService();
      service = KmhService(
        repository: repository,
        dataService: dataService,
        calculator: calculator,
        settingsService: settingsService,
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

    // Feature: kmh-account-management, Property 12: Faiz Tahakkuk Etkisi
    // Validates: Requirements 3.4
    PropertyTest.forAll<Map<String, double>>(
      description:
          'Property 12: Interest accrual decreases balance and creates interest transaction',
      generator: () {
        // Generate random negative balance (debt) and interest rate
        final balance = -PropertyTest.randomPositiveDouble(
          min: 100.0,
          max: 50000.0,
        );
        final interestRate = PropertyTest.randomPositiveDouble(
          min: 1.0,
          max: 50.0,
        );

        return {'balance': balance, 'interestRate': interestRate};
      },
      property: (data) async {
        final initialBalance = data['balance']!;
        final interestRate = data['interestRate']!;

        // Create a KMH account with negative balance
        final wallet = await service.createKmhAccount(
          bankName: 'Test Bank ${PropertyTest.randomString(maxLength: 10)}',
          creditLimit: 100000.0,
          interestRate: interestRate,
          initialBalance: initialBalance,
        );

        // Calculate expected interest
        // Note: applyDailyInterest inside service now uses values from settingsService (defaults)
        // Default tax is 0.15 + 0.15 = 0.30
        final expectedInterest = calculator.calculateDailyInterest(
          balance: initialBalance,
          monthlyRate: interestRate, // Passing as monthlyRate
          kkdfRate: 0.15,
          bsmvRate: 0.15,
        );

        // Get transactions before interest accrual
        final transactionsBefore = await repository.getTransactions(wallet.id);
        final transactionCountBefore = transactionsBefore.length;

        // Apply daily interest
        await service.applyDailyInterest(wallet.id);

        // Get updated wallet
        final wallets = await dataService.getWallets();
        final updatedWallet = wallets.firstWhere((w) => w.id == wallet.id);

        // Get transactions after interest accrual
        final transactionsAfter = await repository.getTransactions(wallet.id);

        // Property 1: Balance should decrease by interest amount
        final expectedBalance = initialBalance - expectedInterest;
        final balanceCorrect =
            (updatedWallet.balance - expectedBalance).abs() < 0.01;

        // Property 2: A new interest transaction should be created
        final transactionCreated =
            transactionsAfter.length == transactionCountBefore + 1;

        // Property 3: The new transaction should be of type interest
        final interestTransactions = transactionsAfter
            .where((t) => t.type == KmhTransactionType.interest)
            .toList();
        final hasInterestTransaction = interestTransactions.isNotEmpty;

        // Property 4: The interest transaction should have correct amount
        final lastTransaction = transactionsAfter.last;
        final amountCorrect =
            (lastTransaction.amount - expectedInterest).abs() < 0.01;

        // Property 5: The transaction's balanceAfter should match wallet balance
        final balanceAfterCorrect =
            (lastTransaction.balanceAfter - updatedWallet.balance).abs() < 0.01;

        // Property 6: The transaction should have interestAmount field set
        final interestAmountSet =
            lastTransaction.interestAmount != null &&
            (lastTransaction.interestAmount! - expectedInterest).abs() < 0.01;

        // Property 7: lastInterestDate should be updated
        final lastInterestDateUpdated = updatedWallet.lastInterestDate != null;

        // Property 8: accruedInterest should be updated
        final accruedInterestUpdated =
            updatedWallet.accruedInterest != null &&
            updatedWallet.accruedInterest! >= expectedInterest;

        return balanceCorrect &&
            transactionCreated &&
            hasInterestTransaction &&
            amountCorrect &&
            balanceAfterCorrect &&
            interestAmountSet &&
            lastInterestDateUpdated &&
            accruedInterestUpdated;
      },
      iterations: 100,
    );

    // Additional property: No interest accrual for positive balances
    PropertyTest.forAll<Map<String, double>>(
      description: 'property: no interest accrual for positive balances',
      generator: () {
        // Generate random positive balance and interest rate
        final balance = PropertyTest.randomPositiveDouble(
          min: 0.0,
          max: 50000.0,
        );
        final interestRate = PropertyTest.randomPositiveDouble(
          min: 1.0,
          max: 50.0,
        );

        return {'balance': balance, 'interestRate': interestRate};
      },
      property: (data) async {
        final initialBalance = data['balance']!;
        final interestRate = data['interestRate']!;

        // Create a KMH account with positive balance
        final wallet = await service.createKmhAccount(
          bankName: 'Test Bank ${PropertyTest.randomString(maxLength: 10)}',
          creditLimit: 10000.0,
          interestRate: interestRate,
          initialBalance: initialBalance,
        );

        // Get transactions before interest accrual
        final transactionsBefore = await repository.getTransactions(wallet.id);
        final transactionCountBefore = transactionsBefore.length;

        // Apply daily interest (should do nothing for positive balance)
        await service.applyDailyInterest(wallet.id);

        // Get updated wallet
        final wallets = await dataService.getWallets();
        final updatedWallet = wallets.firstWhere((w) => w.id == wallet.id);

        // Get transactions after interest accrual
        final transactionsAfter = await repository.getTransactions(wallet.id);

        // Property 1: Balance should remain unchanged
        final balanceUnchanged =
            (updatedWallet.balance - initialBalance).abs() < 0.01;

        // Property 2: No new transaction should be created
        final noTransactionCreated =
            transactionsAfter.length == transactionCountBefore;

        return balanceUnchanged && noTransactionCreated;
      },
      iterations: 100,
    );

    // Additional property: Multiple interest accruals accumulate correctly
    PropertyTest.forAll<Map<String, double>>(
      description: 'property: multiple interest accruals accumulate correctly',
      generator: () {
        // Generate random negative balance and interest rate
        final balance = -PropertyTest.randomPositiveDouble(
          min: 100.0,
          max: 50000.0,
        );
        final interestRate = PropertyTest.randomPositiveDouble(
          min: 1.0,
          max: 50.0,
        );

        return {'balance': balance, 'interestRate': interestRate};
      },
      property: (data) async {
        final initialBalance = data['balance']!;
        final interestRate = data['interestRate']!;

        // Create a KMH account with negative balance
        final wallet = await service.createKmhAccount(
          bankName: 'Test Bank ${PropertyTest.randomString(maxLength: 10)}',
          creditLimit: 100000.0,
          interestRate: interestRate,
          initialBalance: initialBalance,
        );

        // Apply interest multiple times (simulate multiple days)
        final days = PropertyTest.randomInt(min: 2, max: 5);
        double expectedTotalInterest = 0.0;
        double currentBalance = initialBalance;

        for (int i = 0; i < days; i++) {
          // Calculate expected interest for current balance
          final dayInterest = calculator.calculateDailyInterest(
            balance: currentBalance,
            monthlyRate: interestRate,
            kkdfRate: 0.15,
            bsmvRate: 0.15,
          );
          expectedTotalInterest += dayInterest;
          currentBalance -= dayInterest;

          // Apply interest
          await service.applyDailyInterest(wallet.id);
        }

        // Get updated wallet
        final wallets = await dataService.getWallets();
        final updatedWallet = wallets.firstWhere((w) => w.id == wallet.id);

        // Get all transactions
        final transactions = await repository.getTransactions(wallet.id);
        final interestTransactions = transactions
            .where((t) => t.type == KmhTransactionType.interest)
            .toList();

        // Property 1: Correct number of interest transactions
        final correctTransactionCount = interestTransactions.length == days;

        // Property 2: Final balance should be initial balance minus total interest
        final expectedFinalBalance = initialBalance - expectedTotalInterest;
        final balanceCorrect =
            (updatedWallet.balance - expectedFinalBalance).abs() < 0.1;

        // Property 3: accruedInterest should equal total interest
        final accruedInterestCorrect =
            updatedWallet.accruedInterest != null &&
            (updatedWallet.accruedInterest! - expectedTotalInterest).abs() <
                0.1;

        return correctTransactionCount &&
            balanceCorrect &&
            accruedInterestCorrect;
      },
      iterations: 50, // Fewer iterations since this test is more complex
    );

    // Edge case: Very small interest amounts
    test('property: handles very small interest amounts correctly', () async {
      // Create account with very small debt
      final wallet = await service.createKmhAccount(
        bankName: 'Test Bank',
        creditLimit: 10000.0,
        interestRate: 1.0,
        initialBalance: -0.50, // Very small debt
      );

      final initialBalance = wallet.balance;

      // Apply interest
      await service.applyDailyInterest(wallet.id);

      // Get updated wallet
      final wallets = await dataService.getWallets();
      final updatedWallet = wallets.firstWhere((w) => w.id == wallet.id);

      // For very small amounts, interest might be < 0.01 and skipped
      // Balance should either be unchanged or slightly decreased
      expect(updatedWallet.balance, lessThanOrEqualTo(initialBalance));
    });

    // Edge case: Zero balance
    test('property: no interest for zero balance', () async {
      // Create account with zero balance
      final wallet = await service.createKmhAccount(
        bankName: 'Test Bank',
        creditLimit: 10000.0,
        interestRate: 24.0,
        initialBalance: 0.0,
      );

      // Apply interest
      await service.applyDailyInterest(wallet.id);

      // Get updated wallet
      final wallets = await dataService.getWallets();
      final updatedWallet = wallets.firstWhere((w) => w.id == wallet.id);

      // Get transactions
      final transactions = await repository.getTransactions(wallet.id);

      // Balance should remain zero
      expect(updatedWallet.balance, equals(0.0));

      // No interest transactions should be created
      final interestTransactions = transactions
          .where((t) => t.type == KmhTransactionType.interest)
          .toList();
      expect(interestTransactions, isEmpty);
    });
  });
}
