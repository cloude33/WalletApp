import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:money/services/kmh_interest_scheduler_service.dart';
import 'package:money/services/kmh_service.dart';

import 'package:money/services/data_service.dart';
import 'package:money/services/kmh_box_service.dart';

import 'package:money/models/kmh_transaction.dart';
import 'package:money/models/kmh_transaction_type.dart';

void main() {
  group('KmhInterestSchedulerService', () {
    late KmhInterestSchedulerService scheduler;
    late KmhService kmhService;
    late DataService dataService;
    late Directory testDir;

    setUpAll(() async {
      // Create a temporary directory for testing
      testDir = await Directory.systemTemp.createTemp('kmh_scheduler_test_');

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

      kmhService = KmhService(dataService: dataService);

      scheduler = KmhInterestSchedulerService(kmhService: kmhService);
    });

    tearDown(() async {
      scheduler.dispose();
    });

    tearDownAll(() async {
      // Clean up
      await KmhBoxService.close();
      await Hive.close();
      if (await testDir.exists()) {
        await testDir.delete(recursive: true);
      }
    });

    test('initialize should run migration and check interest', () async {
      // Initialize scheduler
      await scheduler.initialize();

      // Verify scheduler is initialized (no errors thrown)
      expect(scheduler, isNotNull);
    });

    test('runNow should apply interest to all accounts', () async {
      // Create a test KMH account with negative balance
      final wallet = await kmhService.createKmhAccount(
        bankName: 'Test Bank',
        creditLimit: 10000,
        interestRate: 24.0,
        initialBalance: -5000,
      );

      final initialBalance = wallet.balance;

      // Run interest accrual
      await scheduler.runNow();

      // Get updated wallet
      final wallets = await dataService.getWallets();
      final updatedWallet = wallets.firstWhere((w) => w.id == wallet.id);

      // Balance should have decreased (more negative) due to interest
      expect(updatedWallet.balance, lessThan(initialBalance));
      expect(updatedWallet.accruedInterest, greaterThan(0));
    });

    test(
      'should not apply interest to accounts with positive balance',
      () async {
        // Create a test KMH account with positive balance
        final wallet = await kmhService.createKmhAccount(
          bankName: 'Test Bank',
          creditLimit: 10000,
          interestRate: 24.0,
          initialBalance: 5000,
        );

        final initialBalance = wallet.balance;

        // Run interest accrual
        await scheduler.runNow();

        // Get updated wallet
        final wallets = await dataService.getWallets();
        final updatedWallet = wallets.firstWhere((w) => w.id == wallet.id);

        // Balance should remain the same (no interest on positive balance)
        expect(updatedWallet.balance, equals(initialBalance));
        expect(updatedWallet.accruedInterest ?? 0, equals(0));
      },
    );

    test('should handle multiple KMH accounts', () async {
      // Create multiple test KMH accounts
      final wallet1 = await kmhService.createKmhAccount(
        bankName: 'Bank 1',
        creditLimit: 10000,
        interestRate: 24.0,
        initialBalance: -3000,
      );

      final wallet2 = await kmhService.createKmhAccount(
        bankName: 'Bank 2',
        creditLimit: 15000,
        interestRate: 18.0,
        initialBalance: -7000,
      );

      final wallet3 = await kmhService.createKmhAccount(
        bankName: 'Bank 3',
        creditLimit: 5000,
        interestRate: 30.0,
        initialBalance: 2000, // Positive balance
      );

      // Run interest accrual
      await scheduler.runNow();

      // Get updated wallets
      final wallets = await dataService.getWallets();
      final updated1 = wallets.firstWhere((w) => w.id == wallet1.id);
      final updated2 = wallets.firstWhere((w) => w.id == wallet2.id);
      final updated3 = wallets.firstWhere((w) => w.id == wallet3.id);

      // Accounts with negative balance should have interest applied
      expect(updated1.balance, lessThan(wallet1.balance));
      expect(updated2.balance, lessThan(wallet2.balance));

      // Account with positive balance should not have interest
      expect(updated3.balance, equals(wallet3.balance));
    });

    test('cancelSchedule should stop scheduled tasks', () async {
      await scheduler.initialize();

      // Cancel schedule
      await scheduler.cancelSchedule();

      // Verify no errors (scheduler should be stopped)
      expect(scheduler, isNotNull);
    });

    test('dispose should clean up resources', () {
      scheduler.dispose();

      // Verify no errors
      expect(scheduler, isNotNull);
    });
  });
}
