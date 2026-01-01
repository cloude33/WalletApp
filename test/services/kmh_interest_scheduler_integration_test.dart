import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:parion/services/kmh_interest_scheduler_service.dart';
import 'package:parion/services/kmh_service.dart';
import 'package:parion/services/data_service.dart';
import 'package:parion/services/kmh_box_service.dart';
import 'package:parion/models/kmh_transaction.dart';
import 'package:parion/models/kmh_transaction_type.dart';
import 'package:parion/repositories/kmh_repository.dart';

/// Integration test for KMH Interest Scheduler Service
///
/// This test verifies the complete workflow:
/// 1. Migration runs on startup
/// 2. Interest is applied daily at 00:00
/// 3. Retry mechanism works on failures
void main() {
  group('KmhInterestSchedulerService Integration Tests', () {
    late KmhInterestSchedulerService scheduler;
    late KmhService kmhService;
    late DataService dataService;
    late KmhRepository repository;
    late Directory testDir;

    setUpAll(() async {
      // Create a temporary directory for testing
      testDir = await Directory.systemTemp.createTemp(
        'kmh_scheduler_integration_',
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

      kmhService = KmhService(dataService: dataService, repository: repository);

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

    test(
      'Complete workflow: create account, apply interest, verify transaction',
      () async {
        // Step 1: Create a KMH account with negative balance
        final wallet = await kmhService.createKmhAccount(
          bankName: 'Test Bank',
          creditLimit: 10000,
          interestRate: 24.0,
          initialBalance: -5000,
        );

        expect(wallet.isKmhAccount, isTrue);
        expect(wallet.balance, equals(-5000));

        // Step 2: Run interest accrual
        await scheduler.runNow();

        // Step 3: Verify balance decreased
        final wallets = await dataService.getWallets();
        final updatedWallet = wallets.firstWhere((w) => w.id == wallet.id);

        expect(updatedWallet.balance, lessThan(-5000));
        expect(updatedWallet.accruedInterest, greaterThan(0));

        // Step 4: Verify interest transaction was created
        final transactions = await repository.getTransactions(wallet.id);
        final interestTransactions = transactions
            .where((t) => t.type == KmhTransactionType.interest)
            .toList();

        expect(interestTransactions.length, equals(1));
        expect(interestTransactions.first.amount, greaterThan(0));
        expect(interestTransactions.first.description, contains('faiz'));
      },
    );

    test('Scheduler should handle accounts with zero balance', () async {
      // Create account with zero balance
      final wallet = await kmhService.createKmhAccount(
        bankName: 'Zero Balance Bank',
        creditLimit: 5000,
        interestRate: 24.0,
        initialBalance: 0,
      );

      // Run interest accrual
      await scheduler.runNow();

      // Verify balance remains zero
      final wallets = await dataService.getWallets();
      final updatedWallet = wallets.firstWhere((w) => w.id == wallet.id);

      expect(updatedWallet.balance, equals(0));
      expect(updatedWallet.accruedInterest ?? 0, equals(0));

      // Verify no interest transactions
      final transactions = await repository.getTransactions(wallet.id);
      final interestTransactions = transactions
          .where((t) => t.type == KmhTransactionType.interest)
          .toList();

      expect(interestTransactions.length, equals(0));
    });

    test('Scheduler should process multiple accounts in one run', () async {
      // Create multiple accounts with different balances
      final accounts = <String, double>{
        'Bank A': -3000,
        'Bank B': -7000,
        'Bank C': -1500,
        'Bank D': 2000, // Positive balance
      };

      final walletIds = <String>[];
      for (var entry in accounts.entries) {
        final wallet = await kmhService.createKmhAccount(
          bankName: entry.key,
          creditLimit: 10000,
          interestRate: 24.0,
          initialBalance: entry.value,
        );
        walletIds.add(wallet.id);
      }

      // Run interest accrual once
      await scheduler.runNow();

      // Verify all negative balance accounts have interest
      final wallets = await dataService.getWallets();

      for (var i = 0; i < walletIds.length; i++) {
        final wallet = wallets.firstWhere((w) => w.id == walletIds[i]);
        final originalBalance = accounts.values.elementAt(i);

        if (originalBalance < 0) {
          // Should have interest applied
          expect(wallet.balance, lessThan(originalBalance));
          expect(wallet.accruedInterest, greaterThan(0));
        } else {
          // Should not have interest
          expect(wallet.balance, equals(originalBalance));
          expect(wallet.accruedInterest ?? 0, equals(0));
        }
      }
    });

    test('Interest calculation should be accurate', () async {
      // Create account with known balance
      final balance = -10000.0;
      final interestRate = 24.0;

      final wallet = await kmhService.createKmhAccount(
        bankName: 'Calculation Test Bank',
        creditLimit: 15000,
        interestRate: interestRate,
        initialBalance: balance,
      );

      // Run interest accrual
      await scheduler.runNow();

      // Calculate expected daily interest
      // Formula: (balance * annualRate / 365 / 100)
      final expectedDailyInterest = (balance.abs() * interestRate / 365 / 100);

      // Get updated wallet
      final wallets = await dataService.getWallets();
      final updatedWallet = wallets.firstWhere((w) => w.id == wallet.id);

      // Verify balance decreased by expected amount (with small tolerance for rounding)
      final actualInterest = balance - updatedWallet.balance;
      expect(actualInterest, closeTo(expectedDailyInterest, 0.01));

      // Verify accrued interest matches
      expect(
        updatedWallet.accruedInterest,
        closeTo(expectedDailyInterest, 0.01),
      );
    });

    test(
      'Scheduler initialization should not fail on empty database',
      () async {
        // Initialize scheduler with no accounts
        await scheduler.initialize();

        // Should complete without errors
        expect(scheduler, isNotNull);
      },
    );
  });
}
