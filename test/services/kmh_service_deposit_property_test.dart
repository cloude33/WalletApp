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

/// **Feature: kmh-account-management, Property 7: Para Yatırma Bakiye Etkisi**
/// **Validates: Requirements 2.2**
///
/// Property: For any KMH account deposit operation, the account balance should
/// increase by the deposit amount and a transaction record should be created.
void main() {
  group('KMH Deposit Balance Effect Property Tests', () {
    late KmhService kmhService;
    late DataService dataService;
    late KmhRepository kmhRepository;
    late Directory testDir;

    setUpAll(() async {
      // Create a temporary directory for testing
      testDir = await Directory.systemTemp.createTemp('kmh_deposit_test_');

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
      description: 'Property 7: Deposit increases balance by deposit amount',
      generator: () {
        final creditLimit = PropertyTest.randomPositiveDouble(
          min: 5000,
          max: 100000,
        );
        final initialBalance = PropertyTest.randomDouble(
          min: -creditLimit / 2, // Can start negative
          max: creditLimit / 2, // Can start positive
        );
        final depositAmount = PropertyTest.randomPositiveDouble(
          min: 100,
          max: 50000,
        );

        return {
          'bankName': PropertyTest.randomString(minLength: 5, maxLength: 30),
          'creditLimit': creditLimit,
          'interestRate': PropertyTest.randomPositiveDouble(min: 1, max: 50),
          'initialBalance': initialBalance,
          'depositAmount': depositAmount,
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
        final depositAmount = data['depositAmount'] as double;
        final expectedNewBalance = initialBalance + depositAmount;

        // Step 2: Record deposit
        await kmhService.recordDeposit(
          account.id,
          depositAmount,
          data['description'],
        );

        // Step 3: Verify balance was increased
        final wallets = await dataService.getWallets();
        final updatedAccount = wallets.firstWhere((w) => w.id == account.id);

        // Property 1: Balance should increase by deposit amount
        expect(
          updatedAccount.balance,
          closeTo(expectedNewBalance, 0.001),
          reason: 'Balance should increase by deposit amount',
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
          equals(KmhTransactionType.deposit),
          reason: 'Transaction type should be deposit',
        );
        expect(
          transaction.amount,
          equals(depositAmount),
          reason: 'Transaction amount should match deposit amount',
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

        // Property 3: Transaction should record balance after deposit
        expect(
          transaction.balanceAfter,
          closeTo(expectedNewBalance, 0.001),
          reason: 'Transaction should record correct balance after deposit',
        );

        return true;
      },
      iterations: 100,
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 7: Multiple deposits accumulate correctly',
      generator: () {
        final creditLimit = PropertyTest.randomPositiveDouble(
          min: 10000,
          max: 100000,
        );
        final initialBalance = PropertyTest.randomDouble(
          min: -creditLimit / 2,
          max: creditLimit / 2,
        );

        final deposit1 = PropertyTest.randomPositiveDouble(
          min: 100,
          max: 10000,
        );
        final deposit2 = PropertyTest.randomPositiveDouble(
          min: 100,
          max: 10000,
        );
        final deposit3 = PropertyTest.randomPositiveDouble(
          min: 100,
          max: 10000,
        );

        return {
          'bankName': PropertyTest.randomString(minLength: 5, maxLength: 30),
          'creditLimit': creditLimit,
          'interestRate': PropertyTest.randomPositiveDouble(min: 1, max: 50),
          'initialBalance': initialBalance,
          'deposit1': deposit1,
          'deposit2': deposit2,
          'deposit3': deposit3,
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
        final deposit1 = data['deposit1'] as double;
        final deposit2 = data['deposit2'] as double;
        final deposit3 = data['deposit3'] as double;

        // Record three deposits
        await kmhService.recordDeposit(
          account.id,
          deposit1,
          data['description1'],
        );
        await kmhService.recordDeposit(
          account.id,
          deposit2,
          data['description2'],
        );
        await kmhService.recordDeposit(
          account.id,
          deposit3,
          data['description3'],
        );

        // Calculate expected final balance
        final expectedBalance = initialBalance + deposit1 + deposit2 + deposit3;

        // Verify final balance
        final wallets = await dataService.getWallets();
        final updatedAccount = wallets.firstWhere((w) => w.id == account.id);

        // Property: Total deposits should accumulate correctly
        expect(
          updatedAccount.balance,
          closeTo(expectedBalance, 0.001),
          reason: 'Multiple deposits should accumulate correctly',
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
          closeTo(initialBalance + deposit1, 0.001),
          reason: 'First transaction should have correct balance',
        );
        expect(
          sortedTransactions[1].balanceAfter,
          closeTo(initialBalance + deposit1 + deposit2, 0.001),
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
      description: 'Property 7: Deposit from negative balance can go positive',
      generator: () {
        final creditLimit = PropertyTest.randomPositiveDouble(
          min: 5000,
          max: 100000,
        );
        final initialBalance = PropertyTest.randomDouble(
          min: -creditLimit * 0.8,
          max: -100, // Start with negative balance
        );
        // Deposit larger than debt to go positive
        final depositAmount = PropertyTest.randomPositiveDouble(
          min: initialBalance.abs() + 100,
          max: initialBalance.abs() + 10000,
        );

        return {
          'bankName': PropertyTest.randomString(minLength: 5, maxLength: 30),
          'creditLimit': creditLimit,
          'interestRate': PropertyTest.randomPositiveDouble(min: 1, max: 50),
          'initialBalance': initialBalance,
          'depositAmount': depositAmount,
          'description': PropertyTest.randomString(minLength: 5, maxLength: 50),
        };
      },
      property: (data) async {
        // Create account with negative balance
        final account = await kmhService.createKmhAccount(
          bankName: data['bankName'],
          creditLimit: data['creditLimit'],
          interestRate: data['interestRate'],
          initialBalance: data['initialBalance'],
        );

        final initialBalance = data['initialBalance'] as double;
        final depositAmount = data['depositAmount'] as double;
        final expectedNewBalance = initialBalance + depositAmount;

        // Verify initial balance is negative
        expect(
          initialBalance,
          lessThan(0),
          reason: 'Initial balance should be negative',
        );

        // Record deposit that exceeds debt
        await kmhService.recordDeposit(
          account.id,
          depositAmount,
          data['description'],
        );

        // Verify balance went positive
        final wallets = await dataService.getWallets();
        final updatedAccount = wallets.firstWhere((w) => w.id == account.id);

        // Property: Balance should be positive after deposit
        expect(
          updatedAccount.balance,
          greaterThan(0),
          reason: 'Balance should be positive after large deposit',
        );

        // Property: Balance should be exactly initial + deposit
        expect(
          updatedAccount.balance,
          closeTo(expectedNewBalance, 0.001),
          reason: 'Balance should increase by exact deposit amount',
        );

        return true;
      },
      iterations: 100,
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 7: Deposit updates computed properties correctly',
      generator: () {
        final creditLimit = PropertyTest.randomPositiveDouble(
          min: 5000,
          max: 100000,
        );
        final initialBalance = PropertyTest.randomDouble(
          min: -creditLimit * 0.8,
          max: creditLimit / 2,
        );
        final depositAmount = PropertyTest.randomPositiveDouble(
          min: 100,
          max: 20000,
        );

        return {
          'bankName': PropertyTest.randomString(minLength: 5, maxLength: 30),
          'creditLimit': creditLimit,
          'interestRate': PropertyTest.randomPositiveDouble(min: 1, max: 50),
          'initialBalance': initialBalance,
          'depositAmount': depositAmount,
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
        final depositAmount = data['depositAmount'] as double;
        final expectedNewBalance =
            (data['initialBalance'] as double) + depositAmount;

        // Record deposit
        await kmhService.recordDeposit(
          account.id,
          depositAmount,
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

    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 7: Deposit and withdrawal are inverse operations',
      generator: () {
        final creditLimit = PropertyTest.randomPositiveDouble(
          min: 10000,
          max: 100000,
        );
        final initialBalance = PropertyTest.randomDouble(
          min: -creditLimit / 3,
          max: creditLimit / 3,
        );
        final amount = PropertyTest.randomPositiveDouble(min: 100, max: 5000);

        return {
          'bankName': PropertyTest.randomString(minLength: 5, maxLength: 30),
          'creditLimit': creditLimit,
          'interestRate': PropertyTest.randomPositiveDouble(min: 1, max: 50),
          'initialBalance': initialBalance,
          'amount': amount,
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

        final initialBalance = data['initialBalance'] as double;
        final amount = data['amount'] as double;

        // Record deposit then withdrawal of same amount
        await kmhService.recordDeposit(account.id, amount, data['description']);
        await kmhService.recordWithdrawal(
          account.id,
          amount,
          data['description'],
        );

        // Verify balance returned to initial
        final wallets = await dataService.getWallets();
        final updatedAccount = wallets.firstWhere((w) => w.id == account.id);

        // Property: Deposit then withdrawal should return to initial balance
        expect(
          updatedAccount.balance,
          closeTo(initialBalance, 0.001),
          reason: 'Deposit then withdrawal should return to initial balance',
        );

        // Property: Should have two transaction records
        final transactions = await kmhRepository.getTransactions(account.id);
        expect(
          transactions.length,
          equals(2),
          reason: 'Should have two transaction records',
        );

        return true;
      },
      iterations: 100,
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description:
          'Property 7: Deposit reduces used credit when balance is negative',
      generator: () {
        final creditLimit = PropertyTest.randomPositiveDouble(
          min: 5000,
          max: 100000,
        );
        final initialBalance = PropertyTest.randomDouble(
          min: -creditLimit * 0.8,
          max: -100, // Start with negative balance (debt)
        );
        final depositAmount = PropertyTest.randomPositiveDouble(
          min: 100,
          max: initialBalance.abs() * 0.8, // Partial payment
        );

        return {
          'bankName': PropertyTest.randomString(minLength: 5, maxLength: 30),
          'creditLimit': creditLimit,
          'interestRate': PropertyTest.randomPositiveDouble(min: 1, max: 50),
          'initialBalance': initialBalance,
          'depositAmount': depositAmount,
          'description': PropertyTest.randomString(minLength: 5, maxLength: 50),
        };
      },
      property: (data) async {
        // Create account with negative balance
        final account = await kmhService.createKmhAccount(
          bankName: data['bankName'],
          creditLimit: data['creditLimit'],
          interestRate: data['interestRate'],
          initialBalance: data['initialBalance'],
        );

        final initialBalance = data['initialBalance'] as double;
        final depositAmount = data['depositAmount'] as double;
        final creditLimit = data['creditLimit'] as double;

        // Calculate initial used credit
        final initialUsedCredit = initialBalance.abs();

        // Record deposit
        await kmhService.recordDeposit(
          account.id,
          depositAmount,
          data['description'],
        );

        // Get updated account
        final wallets = await dataService.getWallets();
        final updatedAccount = wallets.firstWhere((w) => w.id == account.id);

        // Property: Used credit should decrease by deposit amount
        final expectedUsedCredit = initialUsedCredit - depositAmount;
        expect(
          updatedAccount.usedCredit,
          closeTo(expectedUsedCredit, 0.001),
          reason: 'Used credit should decrease by deposit amount',
        );

        // Property: Available credit should increase by deposit amount
        final initialAvailableCredit = creditLimit + initialBalance;
        final expectedAvailableCredit = initialAvailableCredit + depositAmount;
        expect(
          updatedAccount.availableCredit,
          closeTo(expectedAvailableCredit, 0.001),
          reason: 'Available credit should increase by deposit amount',
        );

        // Property: Balance should still be negative (partial payment)
        expect(
          updatedAccount.balance,
          lessThan(0),
          reason: 'Balance should still be negative after partial payment',
        );

        return true;
      },
      iterations: 100,
    );
  });
}
