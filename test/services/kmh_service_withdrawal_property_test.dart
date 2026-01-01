import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:parion/models/kmh_transaction.dart';
import 'package:parion/models/kmh_transaction_type.dart';
import 'package:parion/services/kmh_service.dart';
import 'package:parion/services/data_service.dart';
import 'package:parion/services/kmh_box_service.dart';
import 'package:parion/repositories/kmh_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../property_test_utils.dart';

/// **Feature: kmh-account-management, Property 6: Para Çekme Bakiye Etkisi**
/// **Validates: Requirements 2.1**
///
/// Property: For any KMH account withdrawal operation, the account balance should
/// decrease by the withdrawal amount and a transaction record should be created.
void main() {
  group('KMH Withdrawal Balance Effect Property Tests', () {
    late KmhService kmhService;
    late DataService dataService;
    late KmhRepository kmhRepository;
    late Directory testDir;

    setUpAll(() async {
      // Create a temporary directory for testing
      testDir = await Directory.systemTemp.createTemp('kmh_withdrawal_test_');

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
          'Property 6: Withdrawal decreases balance by withdrawal amount',
      generator: () {
        final creditLimit = PropertyTest.randomPositiveDouble(
          min: 5000,
          max: 100000,
        );
        final initialBalance = PropertyTest.randomDouble(
          min: -creditLimit / 2, // Can start negative but within limit
          max: creditLimit / 2, // Can start positive
        );
        // Ensure withdrawal doesn't exceed available credit
        final maxWithdrawal = creditLimit + initialBalance;
        final withdrawalAmount = PropertyTest.randomPositiveDouble(
          min: 100,
          max: maxWithdrawal * 0.9, // Use 90% to ensure we don't hit limit
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
        // Step 1: Create KMH account with initial balance
        final account = await kmhService.createKmhAccount(
          bankName: data['bankName'],
          creditLimit: data['creditLimit'],
          interestRate: data['interestRate'],
          initialBalance: data['initialBalance'],
        );

        final initialBalance = data['initialBalance'] as double;
        final withdrawalAmount = data['withdrawalAmount'] as double;
        final expectedNewBalance = initialBalance - withdrawalAmount;

        // Step 2: Record withdrawal
        await kmhService.recordWithdrawal(
          account.id,
          withdrawalAmount,
          data['description'],
        );

        // Step 3: Verify balance was decreased
        final wallets = await dataService.getWallets();
        final updatedAccount = wallets.firstWhere((w) => w.id == account.id);

        // Property 1: Balance should decrease by withdrawal amount
        expect(
          updatedAccount.balance,
          closeTo(expectedNewBalance, 0.001),
          reason: 'Balance should decrease by withdrawal amount',
        );

        // Property 2: Transaction record should be created
        final transactions = await kmhRepository.getTransactions(account.id);
        expect(
          transactions.length,
          equals(1),
          reason: 'Should have exactly one transaction',
        );

        final transaction = transactions.first;
        expect(
          transaction.type,
          equals(KmhTransactionType.withdrawal),
          reason: 'Transaction type should be withdrawal',
        );
        expect(
          transaction.amount,
          equals(withdrawalAmount),
          reason: 'Transaction amount should match withdrawal amount',
        );
        expect(
          transaction.walletId,
          equals(account.id),
          reason: 'Transaction should be linked to correct wallet',
        );
        expect(
          transaction.description,
          equals(data['description']),
          reason: 'Transaction description should be preserved',
        );

        // Property 3: Transaction should record balance after withdrawal
        expect(
          transaction.balanceAfter,
          closeTo(expectedNewBalance, 0.001),
          reason: 'Transaction should record correct balance after withdrawal',
        );

        return true;
      },
      iterations: 100,
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 6: Multiple withdrawals accumulate correctly',
      generator: () {
        final creditLimit = PropertyTest.randomPositiveDouble(
          min: 10000,
          max: 100000,
        );
        final initialBalance = PropertyTest.randomDouble(
          min: -creditLimit / 3,
          max: creditLimit / 3,
        );

        // Generate multiple withdrawal amounts that together don't exceed limit
        final availableCredit = creditLimit + initialBalance;
        final withdrawal1 = PropertyTest.randomPositiveDouble(
          min: 100,
          max: availableCredit * 0.3,
        );
        final withdrawal2 = PropertyTest.randomPositiveDouble(
          min: 100,
          max: availableCredit * 0.3,
        );
        final withdrawal3 = PropertyTest.randomPositiveDouble(
          min: 100,
          max: availableCredit * 0.3,
        );

        return {
          'bankName': PropertyTest.randomString(minLength: 5, maxLength: 30),
          'creditLimit': creditLimit,
          'interestRate': PropertyTest.randomPositiveDouble(min: 1, max: 50),
          'initialBalance': initialBalance,
          'withdrawal1': withdrawal1,
          'withdrawal2': withdrawal2,
          'withdrawal3': withdrawal3,
          'description1': PropertyTest.randomString(
            minLength: 5,
            maxLength: 50,
          ),
          'description2': PropertyTest.randomString(
            minLength: 5,
            maxLength: 50,
          ),
          'description3': PropertyTest.randomString(
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
        final withdrawal3 = data['withdrawal3'] as double;

        // Record three withdrawals
        await kmhService.recordWithdrawal(
          account.id,
          withdrawal1,
          data['description1'],
        );
        await kmhService.recordWithdrawal(
          account.id,
          withdrawal2,
          data['description2'],
        );
        await kmhService.recordWithdrawal(
          account.id,
          withdrawal3,
          data['description3'],
        );

        // Calculate expected final balance
        final expectedBalance =
            initialBalance - withdrawal1 - withdrawal2 - withdrawal3;

        // Verify final balance
        final wallets = await dataService.getWallets();
        final updatedAccount = wallets.firstWhere((w) => w.id == account.id);

        // Property: Total withdrawals should accumulate correctly
        expect(
          updatedAccount.balance,
          closeTo(expectedBalance, 0.001),
          reason: 'Multiple withdrawals should accumulate correctly',
        );

        // Property: Should have three transaction records
        final transactions = await kmhRepository.getTransactions(account.id);
        expect(
          transactions.length,
          equals(3),
          reason: 'Should have three transaction records',
        );

        // Property: Each transaction should have correct balanceAfter
        final sortedTransactions = transactions.toList()
          ..sort((a, b) => a.date.compareTo(b.date));

        expect(
          sortedTransactions[0].balanceAfter,
          closeTo(initialBalance - withdrawal1, 0.001),
          reason: 'First transaction should have correct balance',
        );
        expect(
          sortedTransactions[1].balanceAfter,
          closeTo(initialBalance - withdrawal1 - withdrawal2, 0.001),
          reason: 'Second transaction should have correct balance',
        );
        expect(
          sortedTransactions[2].balanceAfter,
          closeTo(expectedBalance, 0.001),
          reason: 'Third transaction should have correct balance',
        );

        return true;
      },
      iterations: 100,
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description:
          'Property 6: Withdrawal from positive balance can go negative',
      generator: () {
        final creditLimit = PropertyTest.randomPositiveDouble(
          min: 5000,
          max: 100000,
        );
        final initialBalance = PropertyTest.randomPositiveDouble(
          min: 1000,
          max: 10000,
        );
        // Withdrawal larger than balance but within credit limit
        final withdrawalAmount = PropertyTest.randomPositiveDouble(
          min: initialBalance + 100,
          max: initialBalance + creditLimit * 0.5,
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
        // Create account with positive balance
        final account = await kmhService.createKmhAccount(
          bankName: data['bankName'],
          creditLimit: data['creditLimit'],
          interestRate: data['interestRate'],
          initialBalance: data['initialBalance'],
        );

        final initialBalance = data['initialBalance'] as double;
        final withdrawalAmount = data['withdrawalAmount'] as double;
        final expectedNewBalance = initialBalance - withdrawalAmount;

        // Verify initial balance is positive
        expect(
          initialBalance,
          greaterThan(0),
          reason: 'Initial balance should be positive',
        );

        // Record withdrawal that exceeds positive balance
        await kmhService.recordWithdrawal(
          account.id,
          withdrawalAmount,
          data['description'],
        );

        // Verify balance went negative
        final wallets = await dataService.getWallets();
        final updatedAccount = wallets.firstWhere((w) => w.id == account.id);

        // Property: Balance should be negative after withdrawal
        expect(
          updatedAccount.balance,
          lessThan(0),
          reason: 'Balance should be negative after large withdrawal',
        );

        // Property: Balance should be exactly initial - withdrawal
        expect(
          updatedAccount.balance,
          closeTo(expectedNewBalance, 0.001),
          reason: 'Balance should decrease by exact withdrawal amount',
        );

        // Property: Should still be within credit limit
        expect(
          updatedAccount.balance,
          greaterThanOrEqualTo(-data['creditLimit']),
          reason: 'Balance should not exceed credit limit',
        );

        return true;
      },
      iterations: 100,
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description:
          'Property 6: Withdrawal updates computed properties correctly',
      generator: () {
        final creditLimit = PropertyTest.randomPositiveDouble(
          min: 5000,
          max: 100000,
        );
        final initialBalance = PropertyTest.randomDouble(
          min: -creditLimit / 2,
          max: creditLimit / 2,
        );
        final maxWithdrawal = creditLimit + initialBalance;
        final withdrawalAmount = PropertyTest.randomPositiveDouble(
          min: 100,
          max: maxWithdrawal * 0.8,
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
        // Create account
        final account = await kmhService.createKmhAccount(
          bankName: data['bankName'],
          creditLimit: data['creditLimit'],
          interestRate: data['interestRate'],
          initialBalance: data['initialBalance'],
        );

        final creditLimit = data['creditLimit'] as double;
        final withdrawalAmount = data['withdrawalAmount'] as double;
        final expectedNewBalance =
            (data['initialBalance'] as double) - withdrawalAmount;

        // Record withdrawal
        await kmhService.recordWithdrawal(
          account.id,
          withdrawalAmount,
          data['description'],
        );

        // Get updated account
        final wallets = await dataService.getWallets();
        final updatedAccount = wallets.firstWhere((w) => w.id == account.id);

        // Property: usedCredit should reflect new balance
        final expectedUsedCredit = expectedNewBalance < 0
            ? expectedNewBalance.abs()
            : 0.0;
        expect(
          updatedAccount.usedCredit,
          closeTo(expectedUsedCredit, 0.001),
          reason: 'usedCredit should be updated correctly',
        );

        // Property: availableCredit should reflect new balance
        final expectedAvailableCredit = creditLimit + expectedNewBalance;
        expect(
          updatedAccount.availableCredit,
          closeTo(expectedAvailableCredit, 0.001),
          reason: 'availableCredit should be updated correctly',
        );

        // Property: utilizationRate should reflect new balance
        final expectedUtilizationRate = expectedUsedCredit / creditLimit * 100;
        expect(
          updatedAccount.utilizationRate,
          closeTo(expectedUtilizationRate, 0.001),
          reason: 'utilizationRate should be updated correctly',
        );

        return true;
      },
      iterations: 100,
    );
  });
}
