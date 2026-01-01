import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:parion/models/kmh_transaction.dart';
import 'package:parion/models/kmh_transaction_type.dart';
import 'package:parion/services/kmh_service.dart';
import 'package:parion/services/data_service.dart';
import 'package:parion/services/kmh_box_service.dart';
import 'package:parion/repositories/kmh_repository.dart';
import 'package:parion/exceptions/kmh_exception.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../property_test_utils.dart';

/// **Feature: kmh-account-management, Property 8: Limit Kontrolü**
/// **Validates: Requirements 2.3, 2.4**
///
/// Property: For any withdrawal operation, if the withdrawal would cause the
/// balance to exceed the credit limit (balance < -creditLimit), the operation
/// should not be executed.
void main() {
  group('KMH Limit Control Property Tests', () {
    late KmhService kmhService;
    late DataService dataService;
    late KmhRepository kmhRepository;
    late Directory testDir;

    setUpAll(() async {
      // Create a temporary directory for testing
      testDir = await Directory.systemTemp.createTemp('kmh_limit_test_');

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
      kmhRepository = KmhRepository();
      kmhService = KmhService(
        dataService: dataService,
        repository: kmhRepository,
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
          'Property 8: Withdrawal exceeding credit limit should be rejected',
      generator: () {
        final creditLimit = PropertyTest.randomPositiveDouble(
          min: 5000,
          max: 100000,
        );
        final initialBalance = PropertyTest.randomDouble(
          min: -creditLimit / 2,
          max: creditLimit / 2,
        );

        // Generate a withdrawal that WILL exceed the limit
        // Available credit = creditLimit + initialBalance
        final availableCredit = creditLimit + initialBalance;
        // Request more than available (exceeds limit)
        final withdrawalAmount = PropertyTest.randomPositiveDouble(
          min: availableCredit + 100,
          max: availableCredit + creditLimit,
        );

        return {
          'bankName': PropertyTest.randomString(minLength: 5, maxLength: 30),
          'creditLimit': creditLimit,
          'interestRate': PropertyTest.randomPositiveDouble(min: 1, max: 50),
          'initialBalance': initialBalance,
          'withdrawalAmount': withdrawalAmount,
          'description': PropertyTest.randomString(minLength: 5, maxLength: 50),
        };
      },
      property: (data) async {
        // Create KMH account
        final account = await kmhService.createKmhAccount(
          bankName: data['bankName'],
          creditLimit: data['creditLimit'],
          interestRate: data['interestRate'],
          initialBalance: data['initialBalance'],
        );

        final initialBalance = data['initialBalance'] as double;
        final withdrawalAmount = data['withdrawalAmount'] as double;
        final creditLimit = data['creditLimit'] as double;

        // Verify that withdrawal would exceed limit
        final balanceAfter = initialBalance - withdrawalAmount;
        expect(
          balanceAfter,
          lessThan(-creditLimit),
          reason: 'Test setup: withdrawal should exceed credit limit',
        );

        // Property 1: Withdrawal should throw KmhException
        bool exceptionThrown = false;
        try {
          await kmhService.recordWithdrawal(
            account.id,
            withdrawalAmount,
            data['description'],
          );
        } on KmhException catch (e) {
          exceptionThrown = true;
          // Verify it's a limit exceeded exception
          expect(
            e.message,
            contains('limit'),
            reason: 'Exception should mention limit',
          );
        }

        expect(
          exceptionThrown,
          isTrue,
          reason: 'Should throw KmhException when limit is exceeded',
        );

        // Property 2: Balance should remain unchanged
        final wallets = await dataService.getWallets();
        final unchangedAccount = wallets.firstWhere((w) => w.id == account.id);
        expect(
          unchangedAccount.balance,
          closeTo(initialBalance, 0.001),
          reason: 'Balance should not change when withdrawal is rejected',
        );

        // Property 3: No transaction should be recorded
        final transactions = await kmhRepository.getTransactions(account.id);
        expect(
          transactions.length,
          equals(0),
          reason:
              'No transaction should be recorded when withdrawal is rejected',
        );

        return true;
      },
      iterations: 100,
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 8: Withdrawal within credit limit should succeed',
      generator: () {
        final creditLimit = PropertyTest.randomPositiveDouble(
          min: 5000,
          max: 100000,
        );
        final initialBalance = PropertyTest.randomDouble(
          min: -creditLimit / 2,
          max: creditLimit / 2,
        );

        // Generate a withdrawal that will NOT exceed the limit
        final availableCredit = creditLimit + initialBalance;
        // Request less than available (within limit)
        final withdrawalAmount = PropertyTest.randomPositiveDouble(
          min: 100,
          max: availableCredit * 0.95, // Use 95% to ensure we stay within limit
        );

        return {
          'bankName': PropertyTest.randomString(minLength: 5, maxLength: 30),
          'creditLimit': creditLimit,
          'interestRate': PropertyTest.randomPositiveDouble(min: 1, max: 50),
          'initialBalance': initialBalance,
          'withdrawalAmount': withdrawalAmount,
          'description': PropertyTest.randomString(minLength: 5, maxLength: 50),
        };
      },
      property: (data) async {
        // Create KMH account
        final account = await kmhService.createKmhAccount(
          bankName: data['bankName'],
          creditLimit: data['creditLimit'],
          interestRate: data['interestRate'],
          initialBalance: data['initialBalance'],
        );

        final initialBalance = data['initialBalance'] as double;
        final withdrawalAmount = data['withdrawalAmount'] as double;
        final creditLimit = data['creditLimit'] as double;

        // Verify that withdrawal will NOT exceed limit
        final balanceAfter = initialBalance - withdrawalAmount;
        expect(
          balanceAfter,
          greaterThanOrEqualTo(-creditLimit),
          reason: 'Test setup: withdrawal should be within credit limit',
        );

        // Property 1: Withdrawal should succeed without exception
        bool exceptionThrown = false;
        try {
          await kmhService.recordWithdrawal(
            account.id,
            withdrawalAmount,
            data['description'],
          );
        } catch (e) {
          exceptionThrown = true;
        }

        expect(
          exceptionThrown,
          isFalse,
          reason: 'Should not throw exception when withdrawal is within limit',
        );

        // Property 2: Balance should be updated
        final wallets = await dataService.getWallets();
        final updatedAccount = wallets.firstWhere((w) => w.id == account.id);
        expect(
          updatedAccount.balance,
          closeTo(balanceAfter, 0.001),
          reason: 'Balance should be updated when withdrawal is within limit',
        );

        // Property 3: Transaction should be recorded
        final transactions = await kmhRepository.getTransactions(account.id);
        expect(
          transactions.length,
          equals(1),
          reason:
              'Transaction should be recorded when withdrawal is within limit',
        );

        return true;
      },
      iterations: 100,
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 8: checkLimitAvailability returns correct result',
      generator: () {
        final creditLimit = PropertyTest.randomPositiveDouble(
          min: 5000,
          max: 100000,
        );
        final initialBalance = PropertyTest.randomDouble(
          min: -creditLimit / 2,
          max: creditLimit / 2,
        );

        // Generate two amounts: one within limit, one exceeding limit
        final availableCredit = creditLimit + initialBalance;
        final withinLimitAmount = PropertyTest.randomPositiveDouble(
          min: 100,
          max: availableCredit * 0.9,
        );
        final exceedingLimitAmount = PropertyTest.randomPositiveDouble(
          min: availableCredit + 100,
          max: availableCredit + creditLimit,
        );

        return {
          'bankName': PropertyTest.randomString(minLength: 5, maxLength: 30),
          'creditLimit': creditLimit,
          'interestRate': PropertyTest.randomPositiveDouble(min: 1, max: 50),
          'initialBalance': initialBalance,
          'withinLimitAmount': withinLimitAmount,
          'exceedingLimitAmount': exceedingLimitAmount,
        };
      },
      property: (data) async {
        // Create KMH account
        final account = await kmhService.createKmhAccount(
          bankName: data['bankName'],
          creditLimit: data['creditLimit'],
          interestRate: data['interestRate'],
          initialBalance: data['initialBalance'],
        );

        final withinLimitAmount = data['withinLimitAmount'] as double;
        final exceedingLimitAmount = data['exceedingLimitAmount'] as double;

        // Property 1: checkLimitAvailability should return true for amount within limit
        final withinLimitResult = await kmhService.checkLimitAvailability(
          account.id,
          withinLimitAmount,
        );
        expect(
          withinLimitResult,
          isTrue,
          reason:
              'checkLimitAvailability should return true for amount within limit',
        );

        // Property 2: checkLimitAvailability should return false for amount exceeding limit
        final exceedingLimitResult = await kmhService.checkLimitAvailability(
          account.id,
          exceedingLimitAmount,
        );
        expect(
          exceedingLimitResult,
          isFalse,
          reason:
              'checkLimitAvailability should return false for amount exceeding limit',
        );

        return true;
      },
      iterations: 100,
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 8: getAvailableCredit returns correct amount',
      generator: () {
        final creditLimit = PropertyTest.randomPositiveDouble(
          min: 5000,
          max: 100000,
        );
        final initialBalance = PropertyTest.randomDouble(
          min: -creditLimit / 2,
          max: creditLimit / 2,
        );

        return {
          'bankName': PropertyTest.randomString(minLength: 5, maxLength: 30),
          'creditLimit': creditLimit,
          'interestRate': PropertyTest.randomPositiveDouble(min: 1, max: 50),
          'initialBalance': initialBalance,
        };
      },
      property: (data) async {
        // Create KMH account
        final account = await kmhService.createKmhAccount(
          bankName: data['bankName'],
          creditLimit: data['creditLimit'],
          interestRate: data['interestRate'],
          initialBalance: data['initialBalance'],
        );

        final creditLimit = data['creditLimit'] as double;
        final initialBalance = data['initialBalance'] as double;
        final expectedAvailableCredit = creditLimit + initialBalance;

        // Property: getAvailableCredit should return creditLimit + balance
        final availableCredit = await kmhService.getAvailableCredit(account.id);
        expect(
          availableCredit,
          closeTo(expectedAvailableCredit, 0.001),
          reason: 'Available credit should equal creditLimit + balance',
        );

        return true;
      },
      iterations: 100,
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 8: Exact limit boundary is allowed',
      generator: () {
        final creditLimit = PropertyTest.randomPositiveDouble(
          min: 5000,
          max: 100000,
        );
        final initialBalance = PropertyTest.randomDouble(
          min: -creditLimit / 2,
          max: creditLimit / 2,
        );

        // Calculate exact amount to reach the limit boundary
        // Use slightly less to avoid floating-point precision issues
        final availableCredit = creditLimit + initialBalance;
        final withdrawalAmount =
            availableCredit - 0.01; // Stay just within boundary

        return {
          'bankName': PropertyTest.randomString(minLength: 5, maxLength: 30),
          'creditLimit': creditLimit,
          'interestRate': PropertyTest.randomPositiveDouble(min: 1, max: 50),
          'initialBalance': initialBalance,
          'withdrawalAmount': withdrawalAmount,
          'description': PropertyTest.randomString(minLength: 5, maxLength: 50),
        };
      },
      property: (data) async {
        // Create KMH account
        final account = await kmhService.createKmhAccount(
          bankName: data['bankName'],
          creditLimit: data['creditLimit'],
          interestRate: data['interestRate'],
          initialBalance: data['initialBalance'],
        );

        final initialBalance = data['initialBalance'] as double;
        final withdrawalAmount = data['withdrawalAmount'] as double;
        final creditLimit = data['creditLimit'] as double;

        // Verify that withdrawal will be very close to the limit
        final balanceAfter = initialBalance - withdrawalAmount;
        expect(
          balanceAfter,
          greaterThanOrEqualTo(-creditLimit),
          reason:
              'Test setup: withdrawal should be at or near the credit limit',
        );

        // Property: Withdrawal at exact limit boundary should succeed
        bool exceptionThrown = false;
        try {
          await kmhService.recordWithdrawal(
            account.id,
            withdrawalAmount,
            data['description'],
          );
        } catch (e) {
          exceptionThrown = true;
        }

        expect(
          exceptionThrown,
          isFalse,
          reason: 'Should allow withdrawal that reaches near the credit limit',
        );

        // Verify balance is at or near the limit
        final wallets = await dataService.getWallets();
        final updatedAccount = wallets.firstWhere((w) => w.id == account.id);
        expect(
          updatedAccount.balance,
          closeTo(balanceAfter, 0.001),
          reason: 'Balance should be updated correctly',
        );
        expect(
          updatedAccount.balance,
          greaterThanOrEqualTo(-creditLimit),
          reason: 'Balance should not exceed credit limit',
        );

        return true;
      },
      iterations: 100,
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 8: Multiple withdrawals respect cumulative limit',
      generator: () {
        final creditLimit = PropertyTest.randomPositiveDouble(
          min: 10000,
          max: 100000,
        );
        final initialBalance = PropertyTest.randomDouble(
          min: -creditLimit / 3,
          max: creditLimit / 3,
        );

        // First withdrawal within limit
        final availableCredit = creditLimit + initialBalance;
        final withdrawal1 = PropertyTest.randomPositiveDouble(
          min: 100,
          max: availableCredit * 0.6,
        );

        // Second withdrawal that would exceed limit
        final remainingCredit = availableCredit - withdrawal1;
        final withdrawal2 = PropertyTest.randomPositiveDouble(
          min: remainingCredit + 100,
          max: remainingCredit + creditLimit,
        );

        return {
          'bankName': PropertyTest.randomString(minLength: 5, maxLength: 30),
          'creditLimit': creditLimit,
          'interestRate': PropertyTest.randomPositiveDouble(min: 1, max: 50),
          'initialBalance': initialBalance,
          'withdrawal1': withdrawal1,
          'withdrawal2': withdrawal2,
          'description1': PropertyTest.randomString(
            minLength: 5,
            maxLength: 50,
          ),
          'description2': PropertyTest.randomString(
            minLength: 5,
            maxLength: 50,
          ),
        };
      },
      property: (data) async {
        // Create account
        final account = await kmhService.createKmhAccount(
          bankName: data['bankName'],
          creditLimit: data['creditLimit'],
          interestRate: data['interestRate'],
          initialBalance: data['initialBalance'],
        );

        final initialBalance = data['initialBalance'] as double;
        final withdrawal1 = data['withdrawal1'] as double;
        final withdrawal2 = data['withdrawal2'] as double;

        // Property 1: First withdrawal should succeed
        await kmhService.recordWithdrawal(
          account.id,
          withdrawal1,
          data['description1'],
        );

        final balanceAfterFirst = initialBalance - withdrawal1;
        final wallets1 = await dataService.getWallets();
        final accountAfterFirst = wallets1.firstWhere(
          (w) => w.id == account.id,
        );
        expect(
          accountAfterFirst.balance,
          closeTo(balanceAfterFirst, 0.001),
          reason: 'First withdrawal should succeed',
        );

        // Property 2: Second withdrawal should be rejected
        bool exceptionThrown = false;
        try {
          await kmhService.recordWithdrawal(
            account.id,
            withdrawal2,
            data['description2'],
          );
        } on KmhException {
          exceptionThrown = true;
        }

        expect(
          exceptionThrown,
          isTrue,
          reason:
              'Second withdrawal should be rejected when it would exceed limit',
        );

        // Property 3: Balance should remain at first withdrawal level
        final wallets2 = await dataService.getWallets();
        final finalAccount = wallets2.firstWhere((w) => w.id == account.id);
        expect(
          finalAccount.balance,
          closeTo(balanceAfterFirst, 0.001),
          reason: 'Balance should not change after rejected withdrawal',
        );

        // Property 4: Only one transaction should be recorded
        final transactions = await kmhRepository.getTransactions(account.id);
        expect(
          transactions.length,
          equals(1),
          reason: 'Only the successful withdrawal should be recorded',
        );

        return true;
      },
      iterations: 100,
    );
  });
}
