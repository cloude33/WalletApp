import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:parion/models/wallet.dart';
import 'package:parion/models/transaction.dart';
import 'package:parion/models/kmh_transaction.dart';
import 'package:parion/models/kmh_transaction_type.dart';
import 'package:parion/services/kmh_migration_service.dart';
import 'package:parion/services/data_service.dart';
import 'package:parion/services/kmh_box_service.dart';
import 'package:parion/repositories/kmh_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../property_test_utils.dart';
import 'package:uuid/uuid.dart';

/// **Feature: kmh-account-management, Property 40: Migrasyon Idempotency**
/// **Validates: Requirements 10.5**
/// 
/// Property: For any migration, when run multiple times, it should only
/// perform operations on the first run and skip subsequent runs without
/// causing data corruption or duplication.
void main() {
  late KmhMigrationService migrationService;
  late DataService dataService;
  late KmhRepository kmhRepository;
  late Directory testDir;

  setUpAll(() async {
    // Create a temporary directory for testing
    testDir = await Directory.systemTemp.createTemp('kmh_migration_idempotency_');
    
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
    
    // Clear all existing data
    await dataService.clearAllData();
    
    migrationService = KmhMigrationService();
    kmhRepository = KmhRepository();
    
    // Reset migration flag
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  });

  tearDownAll(() async {
    // Clean up
    await KmhBoxService.close();
    await Hive.close();
    if (await testDir.exists()) {
      await testDir.delete(recursive: true);
    }
  });

  group('KMH Migration Idempotency Property Tests', () {
    test('Property 40: Running migration multiple times should only migrate on first run', () async {
      for (int i = 0; i < 100; i++) {
        // Create a KMH account
        final wallet = Wallet(
          id: const Uuid().v4(),
          name: PropertyTest.randomString(minLength: 5, maxLength: 30),
          balance: PropertyTest.randomDouble(min: -50000, max: 50000),
          type: 'bank',
          color: '#${PropertyTest.randomInt(min: 0, max: 0xFFFFFF).toRadixString(16).padLeft(6, '0')}',
          icon: 'account_balance',
          creditLimit: PropertyTest.randomPositiveDouble(min: 1000, max: 100000),
        );

        await dataService.addWallet(wallet);

        // Run migration first time
        final result1 = await migrationService.migrateKmhAccounts();

        // Property: First migration should succeed and migrate the account
        expect(result1.success, isTrue,
            reason: 'First migration should succeed (iteration $i)');
        expect(result1.accountsMigrated, equals(1),
            reason: 'First migration should migrate 1 account (iteration $i)');

        // Run migration second time
        final result2 = await migrationService.migrateKmhAccounts();

        // Property: Second migration should succeed but not migrate again (idempotency)
        expect(result2.success, isTrue,
            reason: 'Second migration should succeed (iteration $i)');
        expect(result2.accountsMigrated, equals(0),
            reason: 'Second migration should not migrate accounts again - idempotency (iteration $i)');

        // Run migration third time
        final result3 = await migrationService.migrateKmhAccounts();

        // Property: Third migration should also skip (idempotency)
        expect(result3.success, isTrue,
            reason: 'Third migration should succeed (iteration $i)');
        expect(result3.accountsMigrated, equals(0),
            reason: 'Third migration should not migrate accounts again - idempotency (iteration $i)');

        // Clean up for next iteration
        await migrationService.rollbackMigration();
        await dataService.clearAllData();
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
      }
    });

    test('Property 40: Migration flag should be set after first run and persist', () async {
      for (int i = 0; i < 100; i++) {
        // Create a KMH account
        final wallet = Wallet(
          id: const Uuid().v4(),
          name: PropertyTest.randomString(minLength: 5, maxLength: 30),
          balance: PropertyTest.randomDouble(min: -50000, max: 50000),
          type: 'bank',
          color: '#FF0000',
          icon: 'account_balance',
          creditLimit: PropertyTest.randomPositiveDouble(min: 1000, max: 100000),
        );

        await dataService.addWallet(wallet);

        // Property: Migration should not be completed before first run
        final statusBefore = await migrationService.isMigrationCompleted();
        expect(statusBefore, isFalse,
            reason: 'Migration should not be completed before first run (iteration $i)');

        // Run migration first time
        await migrationService.migrateKmhAccounts();

        // Property: Migration should be marked as completed after first run
        final statusAfter = await migrationService.isMigrationCompleted();
        expect(statusAfter, isTrue,
            reason: 'Migration should be marked as completed after first run (iteration $i)');

        // Run migration second time
        await migrationService.migrateKmhAccounts();

        // Property: Migration flag should still be set
        final statusAfterSecond = await migrationService.isMigrationCompleted();
        expect(statusAfterSecond, isTrue,
            reason: 'Migration flag should persist after second run (iteration $i)');

        // Clean up for next iteration
        await migrationService.rollbackMigration();
        await dataService.clearAllData();
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
      }
    });

    test('Property 40: Wallet data should not be modified on subsequent migration runs', () async {
      for (int i = 0; i < 100; i++) {
        // Create a KMH account without KMH fields
        final wallet = Wallet(
          id: const Uuid().v4(),
          name: PropertyTest.randomString(minLength: 5, maxLength: 30),
          balance: PropertyTest.randomDouble(min: -50000, max: 50000),
          type: 'bank',
          color: '#FF0000',
          icon: 'account_balance',
          creditLimit: PropertyTest.randomPositiveDouble(min: 1000, max: 100000),
          interestRate: null,
          lastInterestDate: null,
          accruedInterest: null,
        );

        await dataService.addWallet(wallet);

        // Run migration first time
        await migrationService.migrateKmhAccounts();

        // Get wallet after first migration
        final walletsAfterFirst = await dataService.getWallets();
        final walletAfterFirst = walletsAfterFirst.firstWhere((w) => w.id == wallet.id);
        
        final firstInterestRate = walletAfterFirst.interestRate;
        final firstLastInterestDate = walletAfterFirst.lastInterestDate;
        final firstAccruedInterest = walletAfterFirst.accruedInterest;
        final firstBalance = walletAfterFirst.balance;
        final firstCreditLimit = walletAfterFirst.creditLimit;

        // Property: Wallet should have KMH fields after first migration
        expect(firstInterestRate, isNotNull,
            reason: 'Wallet should have interestRate after first migration (iteration $i)');
        expect(firstLastInterestDate, isNotNull,
            reason: 'Wallet should have lastInterestDate after first migration (iteration $i)');
        expect(firstAccruedInterest, isNotNull,
            reason: 'Wallet should have accruedInterest after first migration (iteration $i)');

        // Run migration second time
        await migrationService.migrateKmhAccounts();

        // Get wallet after second migration
        final walletsAfterSecond = await dataService.getWallets();
        final walletAfterSecond = walletsAfterSecond.firstWhere((w) => w.id == wallet.id);

        // Property: All wallet fields should remain unchanged (idempotency)
        expect(walletAfterSecond.interestRate, equals(firstInterestRate),
            reason: 'interestRate should not change on second migration (iteration $i)');
        expect(walletAfterSecond.lastInterestDate, equals(firstLastInterestDate),
            reason: 'lastInterestDate should not change on second migration (iteration $i)');
        expect(walletAfterSecond.accruedInterest, equals(firstAccruedInterest),
            reason: 'accruedInterest should not change on second migration (iteration $i)');
        expect(walletAfterSecond.balance, equals(firstBalance),
            reason: 'balance should not change on second migration (iteration $i)');
        expect(walletAfterSecond.creditLimit, equals(firstCreditLimit),
            reason: 'creditLimit should not change on second migration (iteration $i)');

        // Run migration third time
        await migrationService.migrateKmhAccounts();

        // Get wallet after third migration
        final walletsAfterThird = await dataService.getWallets();
        final walletAfterThird = walletsAfterThird.firstWhere((w) => w.id == wallet.id);

        // Property: All wallet fields should still remain unchanged
        expect(walletAfterThird.interestRate, equals(firstInterestRate),
            reason: 'interestRate should not change on third migration (iteration $i)');
        expect(walletAfterThird.lastInterestDate, equals(firstLastInterestDate),
            reason: 'lastInterestDate should not change on third migration (iteration $i)');
        expect(walletAfterThird.accruedInterest, equals(firstAccruedInterest),
            reason: 'accruedInterest should not change on third migration (iteration $i)');

        // Clean up for next iteration
        await migrationService.rollbackMigration();
        await dataService.clearAllData();
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
      }
    });

    test('Property 40: KmhTransactions should not be duplicated on subsequent migration runs', () async {
      for (int i = 0; i < 100; i++) {
        // Create a KMH account
        final wallet = Wallet(
          id: const Uuid().v4(),
          name: PropertyTest.randomString(minLength: 5, maxLength: 30),
          balance: PropertyTest.randomDouble(min: -50000, max: 50000),
          type: 'bank',
          color: '#FF0000',
          icon: 'account_balance',
          creditLimit: PropertyTest.randomPositiveDouble(min: 1000, max: 100000),
        );

        await dataService.addWallet(wallet);

        // Create transactions
        final transactionCount = PropertyTest.randomInt(min: 2, max: 10);
        
        for (int j = 0; j < transactionCount; j++) {
          final transaction = Transaction(
            id: const Uuid().v4(),
            type: 'expense',
            amount: PropertyTest.randomPositiveDouble(min: 10, max: 1000),
            description: 'Transaction ${j + 1}',
            category: 'Category',
            walletId: wallet.id,
            date: DateTime.now(),
            isIncome: false,
          );
          
          await dataService.addTransaction(transaction);
        }

        // Run migration first time
        final result1 = await migrationService.migrateKmhAccounts();

        // Property: First migration should convert all transactions
        expect(result1.transactionsConverted, equals(transactionCount),
            reason: 'First migration should convert all transactions (iteration $i)');

        // Get KmhTransactions after first migration
        final kmhTransactionsAfterFirst = await kmhRepository.getTransactions(wallet.id);
        final countAfterFirst = kmhTransactionsAfterFirst.length;

        // Property: Should have correct number of KmhTransactions
        expect(countAfterFirst, equals(transactionCount),
            reason: 'Should have $transactionCount KmhTransactions after first migration (iteration $i)');

        // Run migration second time
        final result2 = await migrationService.migrateKmhAccounts();

        // Property: Second migration should not convert any transactions
        expect(result2.transactionsConverted, equals(0),
            reason: 'Second migration should not convert transactions again (iteration $i)');

        // Get KmhTransactions after second migration
        final kmhTransactionsAfterSecond = await kmhRepository.getTransactions(wallet.id);
        final countAfterSecond = kmhTransactionsAfterSecond.length;

        // Property: Number of KmhTransactions should remain the same (no duplicates)
        expect(countAfterSecond, equals(countAfterFirst),
            reason: 'KmhTransactions should not be duplicated on second migration (iteration $i)');

        // Run migration third time
        final result3 = await migrationService.migrateKmhAccounts();

        // Property: Third migration should also not convert any transactions
        expect(result3.transactionsConverted, equals(0),
            reason: 'Third migration should not convert transactions again (iteration $i)');

        // Get KmhTransactions after third migration
        final kmhTransactionsAfterThird = await kmhRepository.getTransactions(wallet.id);
        final countAfterThird = kmhTransactionsAfterThird.length;

        // Property: Number of KmhTransactions should still remain the same
        expect(countAfterThird, equals(countAfterFirst),
            reason: 'KmhTransactions should not be duplicated on third migration (iteration $i)');

        // Clean up for next iteration
        await migrationService.rollbackMigration();
        await dataService.clearAllData();
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
      }
    });

    test('Property 40: Multiple KMH accounts should not be re-migrated on subsequent runs', () async {
      for (int iteration = 0; iteration < 100; iteration++) {
        // Create multiple KMH accounts
        final accountCount = PropertyTest.randomInt(min: 2, max: 5);
        final walletIds = <String>[];
        
        for (int i = 0; i < accountCount; i++) {
          final wallet = Wallet(
            id: const Uuid().v4(),
            name: 'KMH Bank ${i + 1}',
            balance: PropertyTest.randomDouble(min: -50000, max: 50000),
            type: 'bank',
            color: '#FF0000',
            icon: 'account_balance',
            creditLimit: PropertyTest.randomPositiveDouble(min: 1000, max: 100000),
            interestRate: null,
          );
          
          await dataService.addWallet(wallet);
          walletIds.add(wallet.id);
        }

        // Run migration first time
        final result1 = await migrationService.migrateKmhAccounts();

        // Property: First migration should migrate all accounts
        expect(result1.accountsMigrated, equals(accountCount),
            reason: 'First migration should migrate all $accountCount accounts (iteration $iteration)');

        // Get all wallets after first migration
        final walletsAfterFirst = await dataService.getWallets();
        final kmhAccountsAfterFirst = walletsAfterFirst.where((w) => w.isKmhAccount).toList();

        // Property: All accounts should be KMH accounts with fields set
        expect(kmhAccountsAfterFirst.length, equals(accountCount),
            reason: 'All accounts should be KMH accounts after first migration (iteration $iteration)');
        
        for (var account in kmhAccountsAfterFirst) {
          expect(account.interestRate, isNotNull,
              reason: 'Account ${account.name} should have interestRate (iteration $iteration)');
        }

        // Run migration second time
        final result2 = await migrationService.migrateKmhAccounts();

        // Property: Second migration should not migrate any accounts
        expect(result2.accountsMigrated, equals(0),
            reason: 'Second migration should not migrate accounts again (iteration $iteration)');

        // Get all wallets after second migration
        final walletsAfterSecond = await dataService.getWallets();
        final kmhAccountsAfterSecond = walletsAfterSecond.where((w) => w.isKmhAccount).toList();

        // Property: Number of KMH accounts should remain the same
        expect(kmhAccountsAfterSecond.length, equals(accountCount),
            reason: 'Number of KMH accounts should not change (iteration $iteration)');

        // Property: All account data should remain unchanged
        for (int i = 0; i < accountCount; i++) {
          final accountFirst = kmhAccountsAfterFirst[i];
          final accountSecond = kmhAccountsAfterSecond.firstWhere((w) => w.id == accountFirst.id);
          
          expect(accountSecond.interestRate, equals(accountFirst.interestRate),
              reason: 'Account ${accountFirst.name} interestRate should not change (iteration $iteration)');
          expect(accountSecond.lastInterestDate, equals(accountFirst.lastInterestDate),
              reason: 'Account ${accountFirst.name} lastInterestDate should not change (iteration $iteration)');
          expect(accountSecond.accruedInterest, equals(accountFirst.accruedInterest),
              reason: 'Account ${accountFirst.name} accruedInterest should not change (iteration $iteration)');
        }

        // Clean up for next iteration
        await migrationService.rollbackMigration();
        await dataService.clearAllData();
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
      }
    });

    test('Property 40: Migration status should correctly reflect completion state', () async {
      for (int i = 0; i < 100; i++) {
        // Create a KMH account
        final wallet = Wallet(
          id: const Uuid().v4(),
          name: PropertyTest.randomString(minLength: 5, maxLength: 30),
          balance: PropertyTest.randomDouble(min: -50000, max: 50000),
          type: 'bank',
          color: '#FF0000',
          icon: 'account_balance',
          creditLimit: PropertyTest.randomPositiveDouble(min: 1000, max: 100000),
        );

        await dataService.addWallet(wallet);

        // Get status before migration
        final statusBefore = await migrationService.getMigrationStatus();

        // Property: Migration should not be completed before first run
        expect(statusBefore.isCompleted, isFalse,
            reason: 'Migration should not be completed before first run (iteration $i)');
        expect(statusBefore.migrationDate, isNull,
            reason: 'Migration date should be null before first run (iteration $i)');

        // Run migration first time
        await migrationService.migrateKmhAccounts();

        // Get status after first migration
        final statusAfterFirst = await migrationService.getMigrationStatus();

        // Property: Migration should be completed after first run
        expect(statusAfterFirst.isCompleted, isTrue,
            reason: 'Migration should be completed after first run (iteration $i)');
        expect(statusAfterFirst.migrationDate, isNotNull,
            reason: 'Migration date should be set after first run (iteration $i)');

        final firstMigrationDate = statusAfterFirst.migrationDate;

        // Run migration second time
        await migrationService.migrateKmhAccounts();

        // Get status after second migration
        final statusAfterSecond = await migrationService.getMigrationStatus();

        // Property: Migration should still be completed
        expect(statusAfterSecond.isCompleted, isTrue,
            reason: 'Migration should still be completed after second run (iteration $i)');
        
        // Property: Migration date should not change
        expect(statusAfterSecond.migrationDate, equals(firstMigrationDate),
            reason: 'Migration date should not change on subsequent runs (iteration $i)');

        // Clean up for next iteration
        await migrationService.rollbackMigration();
        await dataService.clearAllData();
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
      }
    });

    test('Property 40: Idempotency should work even with mixed account types', () async {
      for (int iteration = 0; iteration < 100; iteration++) {
        // Create a mix of KMH and non-KMH accounts
        final kmhCount = PropertyTest.randomInt(min: 1, max: 3);
        final nonKmhCount = PropertyTest.randomInt(min: 1, max: 3);
        
        // Create KMH accounts
        for (int i = 0; i < kmhCount; i++) {
          final wallet = Wallet(
            id: const Uuid().v4(),
            name: 'KMH Bank ${i + 1}',
            balance: PropertyTest.randomDouble(min: -50000, max: 50000),
            type: 'bank',
            color: '#FF0000',
            icon: 'account_balance',
            creditLimit: PropertyTest.randomPositiveDouble(min: 1000, max: 100000),
          );
          
          await dataService.addWallet(wallet);
        }
        
        // Create non-KMH accounts
        for (int i = 0; i < nonKmhCount; i++) {
          final types = ['cash', 'credit_card', 'bank'];
          final type = types[PropertyTest.randomInt(min: 0, max: types.length - 1)];
          
          final wallet = Wallet(
            id: const Uuid().v4(),
            name: 'Non-KMH ${i + 1}',
            balance: PropertyTest.randomDouble(min: -50000, max: 50000),
            type: type,
            color: '#00FF00',
            icon: 'account_balance_wallet',
            creditLimit: type == 'bank' ? 0.0 : PropertyTest.randomPositiveDouble(min: 0, max: 100000),
          );
          
          await dataService.addWallet(wallet);
        }

        // Run migration first time
        final result1 = await migrationService.migrateKmhAccounts();

        // Property: First migration should migrate only KMH accounts
        expect(result1.accountsMigrated, equals(kmhCount),
            reason: 'First migration should migrate only $kmhCount KMH accounts (iteration $iteration)');

        // Get total wallet count
        final walletsAfterFirst = await dataService.getWallets();
        final totalCountAfterFirst = walletsAfterFirst.length;

        // Property: Total wallet count should be kmhCount + nonKmhCount
        expect(totalCountAfterFirst, equals(kmhCount + nonKmhCount),
            reason: 'Total wallet count should be ${kmhCount + nonKmhCount} (iteration $iteration)');

        // Run migration second time
        final result2 = await migrationService.migrateKmhAccounts();

        // Property: Second migration should not migrate any accounts
        expect(result2.accountsMigrated, equals(0),
            reason: 'Second migration should not migrate accounts (iteration $iteration)');

        // Get total wallet count after second migration
        final walletsAfterSecond = await dataService.getWallets();
        final totalCountAfterSecond = walletsAfterSecond.length;

        // Property: Total wallet count should remain the same
        expect(totalCountAfterSecond, equals(totalCountAfterFirst),
            reason: 'Total wallet count should not change (iteration $iteration)');

        // Property: Non-KMH accounts should remain unchanged
        final nonKmhAccountsAfterSecond = walletsAfterSecond.where((w) => !w.isKmhAccount).toList();
        expect(nonKmhAccountsAfterSecond.length, equals(nonKmhCount),
            reason: 'Non-KMH account count should remain $nonKmhCount (iteration $iteration)');

        // Clean up for next iteration
        await migrationService.rollbackMigration();
        await dataService.clearAllData();
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
      }
    });

    test('Property 40: Idempotency should be maintained even after app restart simulation', () async {
      for (int i = 0; i < 100; i++) {
        // Create a KMH account
        final wallet = Wallet(
          id: const Uuid().v4(),
          name: PropertyTest.randomString(minLength: 5, maxLength: 30),
          balance: PropertyTest.randomDouble(min: -50000, max: 50000),
          type: 'bank',
          color: '#FF0000',
          icon: 'account_balance',
          creditLimit: PropertyTest.randomPositiveDouble(min: 1000, max: 100000),
        );

        await dataService.addWallet(wallet);

        // Run migration first time
        final result1 = await migrationService.migrateKmhAccounts();

        // Property: First migration should succeed
        expect(result1.accountsMigrated, equals(1),
            reason: 'First migration should migrate 1 account (iteration $i)');

        // Simulate app restart by creating new service instances
        // (but keep SharedPreferences data)
        final newMigrationService = KmhMigrationService();

        // Run migration with new service instance
        final result2 = await newMigrationService.migrateKmhAccounts();

        // Property: Migration should still be idempotent after "restart"
        expect(result2.accountsMigrated, equals(0),
            reason: 'Migration should be idempotent even after service restart (iteration $i)');

        // Property: Migration should still be marked as completed
        final isCompleted = await newMigrationService.isMigrationCompleted();
        expect(isCompleted, isTrue,
            reason: 'Migration should still be marked as completed after restart (iteration $i)');

        // Clean up for next iteration
        await migrationService.rollbackMigration();
        await dataService.clearAllData();
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
      }
    });

    test('Property 40: Idempotency should handle edge case of zero KMH accounts', () async {
      for (int i = 0; i < 100; i++) {
        // Create only non-KMH accounts
        final nonKmhCount = PropertyTest.randomInt(min: 1, max: 5);
        
        for (int j = 0; j < nonKmhCount; j++) {
          final wallet = Wallet(
            id: const Uuid().v4(),
            name: 'Non-KMH ${j + 1}',
            balance: PropertyTest.randomDouble(min: -50000, max: 50000),
            type: 'cash',
            color: '#00FF00',
            icon: 'account_balance_wallet',
            creditLimit: 0.0,
          );
          
          await dataService.addWallet(wallet);
        }

        // Run migration first time
        final result1 = await migrationService.migrateKmhAccounts();

        // Property: First migration should succeed but migrate nothing
        expect(result1.success, isTrue,
            reason: 'First migration should succeed (iteration $i)');
        expect(result1.accountsMigrated, equals(0),
            reason: 'First migration should migrate 0 accounts when no KMH accounts exist (iteration $i)');

        // Property: Migration should be marked as completed even with no accounts
        final isCompletedAfterFirst = await migrationService.isMigrationCompleted();
        expect(isCompletedAfterFirst, isTrue,
            reason: 'Migration should be marked as completed even with no KMH accounts (iteration $i)');

        // Run migration second time
        final result2 = await migrationService.migrateKmhAccounts();

        // Property: Second migration should also succeed and migrate nothing
        expect(result2.success, isTrue,
            reason: 'Second migration should succeed (iteration $i)');
        expect(result2.accountsMigrated, equals(0),
            reason: 'Second migration should migrate 0 accounts (idempotency) (iteration $i)');

        // Clean up for next iteration
        await migrationService.rollbackMigration();
        await dataService.clearAllData();
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
      }
    });
  });
}
