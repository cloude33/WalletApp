import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:money/models/wallet.dart';
import 'package:money/models/kmh_transaction.dart';
import 'package:money/models/kmh_transaction_type.dart';
import 'package:money/services/kmh_migration_service.dart';
import 'package:money/services/data_service.dart';
import 'package:money/services/kmh_box_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../property_test_utils.dart';
import 'package:uuid/uuid.dart';

/// **Feature: kmh-account-management, Property 37: Migrasyon Default Değerler**
/// **Validates: Requirements 10.2**
/// 
/// Property: For any migrated KMH account, if interestRate is null,
/// the default value of 24% should be assigned.
void main() {
  late KmhMigrationService migrationService;
  late DataService dataService;
  late Directory testDir;

  setUpAll(() async {
    // Create a temporary directory for testing
    testDir = await Directory.systemTemp.createTemp('kmh_migration_default_');
    
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

  group('KMH Migration Default Values Property Tests', () {
    test('Property 37: KMH accounts without interestRate should get default 24% after migration', () async {
      for (int i = 0; i < 100; i++) {
        // Create a bank account with creditLimit > 0 but NO interestRate
        final wallet = Wallet(
          id: const Uuid().v4(),
          name: PropertyTest.randomString(minLength: 5, maxLength: 30),
          balance: PropertyTest.randomDouble(min: -50000, max: 50000),
          type: 'bank',
          color: '#${PropertyTest.randomInt(min: 0, max: 0xFFFFFF).toRadixString(16).padLeft(6, '0')}',
          icon: 'account_balance',
          creditLimit: PropertyTest.randomPositiveDouble(min: 1000, max: 100000),
          // Explicitly set interestRate to null (simulating old data)
          interestRate: null,
          lastInterestDate: null,
          accruedInterest: null,
        );

        // Add wallet to database
        await dataService.addWallet(wallet);

        // Verify wallet doesn't have interestRate before migration
        final walletsBeforeMigration = await dataService.getWallets();
        final walletBeforeMigration = walletsBeforeMigration.firstWhere((w) => w.id == wallet.id);
        expect(walletBeforeMigration.interestRate, isNull,
            reason: 'Wallet should not have interestRate before migration (iteration $i)');

        // Run migration
        final result = await migrationService.migrateKmhAccounts();

        // Property: Migration should succeed
        expect(result.success, isTrue,
            reason: 'Migration should succeed (iteration $i)');

        // Property: Should migrate exactly 1 account
        expect(result.accountsMigrated, equals(1),
            reason: 'Should migrate the KMH account (iteration $i)');

        // Verify the wallet after migration
        final walletsAfterMigration = await dataService.getWallets();
        final migratedWallet = walletsAfterMigration.firstWhere((w) => w.id == wallet.id);
        
        // Property: Migrated wallet should have default interestRate of 24%
        expect(migratedWallet.interestRate, equals(24.0),
            reason: 'Migrated wallet should have default interestRate of 24% (iteration $i)');
        
        // Property: Migrated wallet should have lastInterestDate set
        expect(migratedWallet.lastInterestDate, isNotNull,
            reason: 'Migrated wallet should have lastInterestDate set (iteration $i)');
        
        // Property: Migrated wallet should have accruedInterest set to 0
        expect(migratedWallet.accruedInterest, equals(0.0),
            reason: 'Migrated wallet should have accruedInterest set to 0 (iteration $i)');

        // Clean up for next iteration
        await migrationService.rollbackMigration();
        await dataService.clearAllData();
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
      }
    });

    test('Property 37: KMH accounts with existing interestRate should preserve their value', () async {
      for (int i = 0; i < 100; i++) {
        // Generate a random interest rate different from default
        final existingRate = PropertyTest.randomDouble(min: 10.0, max: 50.0);
        
        // Create a bank account with creditLimit > 0 AND an existing interestRate
        final wallet = Wallet(
          id: const Uuid().v4(),
          name: PropertyTest.randomString(minLength: 5, maxLength: 30),
          balance: PropertyTest.randomDouble(min: -50000, max: 50000),
          type: 'bank',
          color: '#${PropertyTest.randomInt(min: 0, max: 0xFFFFFF).toRadixString(16).padLeft(6, '0')}',
          icon: 'account_balance',
          creditLimit: PropertyTest.randomPositiveDouble(min: 1000, max: 100000),
          // Set a custom interestRate
          interestRate: existingRate,
          lastInterestDate: DateTime.now(),
          accruedInterest: PropertyTest.randomDouble(min: 0, max: 1000),
        );

        // Add wallet to database
        await dataService.addWallet(wallet);

        // Verify wallet has the custom interestRate before migration
        final walletsBeforeMigration = await dataService.getWallets();
        final walletBeforeMigration = walletsBeforeMigration.firstWhere((w) => w.id == wallet.id);
        expect(walletBeforeMigration.interestRate, equals(existingRate),
            reason: 'Wallet should have custom interestRate before migration (iteration $i)');

        // Run migration
        final result = await migrationService.migrateKmhAccounts();

        // Property: Migration should succeed
        expect(result.success, isTrue,
            reason: 'Migration should succeed (iteration $i)');

        // Property: Should NOT migrate the account (no changes needed)
        expect(result.accountsMigrated, equals(0),
            reason: 'Should not migrate account that already has all fields (iteration $i)');

        // Verify the wallet after migration
        final walletsAfterMigration = await dataService.getWallets();
        final unchangedWallet = walletsAfterMigration.firstWhere((w) => w.id == wallet.id);
        
        // Property: Wallet should preserve its existing interestRate
        expect(unchangedWallet.interestRate, equals(existingRate),
            reason: 'Wallet should preserve existing interestRate of $existingRate, not change to default (iteration $i)');
        
        // Property: Other fields should also be preserved
        expect(unchangedWallet.lastInterestDate, equals(wallet.lastInterestDate),
            reason: 'Wallet should preserve existing lastInterestDate (iteration $i)');
        expect(unchangedWallet.accruedInterest, equals(wallet.accruedInterest),
            reason: 'Wallet should preserve existing accruedInterest (iteration $i)');

        // Clean up for next iteration
        await migrationService.rollbackMigration();
        await dataService.clearAllData();
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
      }
    });

    test('Property 37: Migration should set all missing default values correctly', () async {
      for (int i = 0; i < 100; i++) {
        // Create a bank account with creditLimit > 0 but missing all KMH fields
        final wallet = Wallet(
          id: const Uuid().v4(),
          name: PropertyTest.randomString(minLength: 5, maxLength: 30),
          balance: PropertyTest.randomDouble(min: -50000, max: 50000),
          type: 'bank',
          color: '#${PropertyTest.randomInt(min: 0, max: 0xFFFFFF).toRadixString(16).padLeft(6, '0')}',
          icon: 'account_balance',
          creditLimit: PropertyTest.randomPositiveDouble(min: 1000, max: 100000),
          interestRate: null,
          lastInterestDate: null,
          accruedInterest: null,
        );

        // Add wallet to database
        await dataService.addWallet(wallet);

        // Record the time before migration
        final beforeMigration = DateTime.now();

        // Run migration
        final result = await migrationService.migrateKmhAccounts();

        // Record the time after migration
        final afterMigration = DateTime.now();

        // Property: Migration should succeed
        expect(result.success, isTrue,
            reason: 'Migration should succeed (iteration $i)');

        // Verify the wallet after migration
        final walletsAfterMigration = await dataService.getWallets();
        final migratedWallet = walletsAfterMigration.firstWhere((w) => w.id == wallet.id);
        
        // Property: interestRate should be set to default 24%
        expect(migratedWallet.interestRate, equals(24.0),
            reason: 'interestRate should be set to default 24% (iteration $i)');
        
        // Property: lastInterestDate should be set to a recent date
        expect(migratedWallet.lastInterestDate, isNotNull,
            reason: 'lastInterestDate should be set (iteration $i)');
        expect(migratedWallet.lastInterestDate!.isAfter(beforeMigration.subtract(const Duration(seconds: 5))),
            isTrue,
            reason: 'lastInterestDate should be recent (iteration $i)');
        expect(migratedWallet.lastInterestDate!.isBefore(afterMigration.add(const Duration(seconds: 5))),
            isTrue,
            reason: 'lastInterestDate should not be in the future (iteration $i)');
        
        // Property: accruedInterest should be set to 0.0
        expect(migratedWallet.accruedInterest, equals(0.0),
            reason: 'accruedInterest should be set to 0.0 (iteration $i)');

        // Clean up for next iteration
        await migrationService.rollbackMigration();
        await dataService.clearAllData();
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
      }
    });

    test('Property 37: Migration should handle partial field presence correctly', () async {
      for (int i = 0; i < 100; i++) {
        // Randomly decide which fields to include
        final hasInterestRate = PropertyTest.randomBool();
        final hasLastInterestDate = PropertyTest.randomBool();
        final hasAccruedInterest = PropertyTest.randomBool();
        
        final customRate = PropertyTest.randomDouble(min: 10.0, max: 50.0);
        final customDate = DateTime.now().subtract(Duration(days: PropertyTest.randomInt(min: 1, max: 365)));
        final customAccrued = PropertyTest.randomDouble(min: 0, max: 5000);
        
        // Create a bank account with some fields present and some missing
        final wallet = Wallet(
          id: const Uuid().v4(),
          name: PropertyTest.randomString(minLength: 5, maxLength: 30),
          balance: PropertyTest.randomDouble(min: -50000, max: 50000),
          type: 'bank',
          color: '#${PropertyTest.randomInt(min: 0, max: 0xFFFFFF).toRadixString(16).padLeft(6, '0')}',
          icon: 'account_balance',
          creditLimit: PropertyTest.randomPositiveDouble(min: 1000, max: 100000),
          interestRate: hasInterestRate ? customRate : null,
          lastInterestDate: hasLastInterestDate ? customDate : null,
          accruedInterest: hasAccruedInterest ? customAccrued : null,
        );

        // Add wallet to database
        await dataService.addWallet(wallet);

        // Run migration
        final result = await migrationService.migrateKmhAccounts();

        // Property: Migration should succeed
        expect(result.success, isTrue,
            reason: 'Migration should succeed (iteration $i)');

        // Verify the wallet after migration
        final walletsAfterMigration = await dataService.getWallets();
        final migratedWallet = walletsAfterMigration.firstWhere((w) => w.id == wallet.id);
        
        // Property: If interestRate was null, it should now be 24%, otherwise preserved
        if (hasInterestRate) {
          expect(migratedWallet.interestRate, equals(customRate),
              reason: 'Existing interestRate should be preserved (iteration $i)');
        } else {
          expect(migratedWallet.interestRate, equals(24.0),
              reason: 'Missing interestRate should be set to default 24% (iteration $i)');
        }
        
        // Property: If lastInterestDate was null, it should now be set, otherwise preserved
        if (hasLastInterestDate) {
          expect(migratedWallet.lastInterestDate, equals(customDate),
              reason: 'Existing lastInterestDate should be preserved (iteration $i)');
        } else {
          expect(migratedWallet.lastInterestDate, isNotNull,
              reason: 'Missing lastInterestDate should be set (iteration $i)');
        }
        
        // Property: If accruedInterest was null, it should now be 0.0, otherwise preserved
        if (hasAccruedInterest) {
          expect(migratedWallet.accruedInterest, equals(customAccrued),
              reason: 'Existing accruedInterest should be preserved (iteration $i)');
        } else {
          expect(migratedWallet.accruedInterest, equals(0.0),
              reason: 'Missing accruedInterest should be set to 0.0 (iteration $i)');
        }

        // Clean up for next iteration
        await migrationService.rollbackMigration();
        await dataService.clearAllData();
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
      }
    });

    test('Property 37: Multiple KMH accounts should all receive default values correctly', () async {
      for (int iteration = 0; iteration < 100; iteration++) {
        // Create multiple KMH accounts without interestRate
        final accountCount = PropertyTest.randomInt(min: 2, max: 5);
        final walletIds = <String>[];
        
        for (int i = 0; i < accountCount; i++) {
          final wallet = Wallet(
            id: const Uuid().v4(),
            name: 'KMH Bank ${i + 1}',
            balance: PropertyTest.randomDouble(min: -50000, max: 50000),
            type: 'bank',
            color: '#${PropertyTest.randomInt(min: 0, max: 0xFFFFFF).toRadixString(16).padLeft(6, '0')}',
            icon: 'account_balance',
            creditLimit: PropertyTest.randomPositiveDouble(min: 1000, max: 100000),
            interestRate: null,
            lastInterestDate: null,
            accruedInterest: null,
          );
          
          await dataService.addWallet(wallet);
          walletIds.add(wallet.id);
        }

        // Run migration
        final result = await migrationService.migrateKmhAccounts();

        // Property: Migration should succeed
        expect(result.success, isTrue,
            reason: 'Migration should succeed (iteration $iteration)');

        // Property: Should migrate all accounts
        expect(result.accountsMigrated, equals(accountCount),
            reason: 'Should migrate all $accountCount KMH accounts (iteration $iteration)');

        // Verify all wallets after migration
        final walletsAfterMigration = await dataService.getWallets();
        
        for (var walletId in walletIds) {
          final migratedWallet = walletsAfterMigration.firstWhere((w) => w.id == walletId);
          
          // Property: Each wallet should have default interestRate of 24%
          expect(migratedWallet.interestRate, equals(24.0),
              reason: 'Wallet $walletId should have default interestRate of 24% (iteration $iteration)');
          
          // Property: Each wallet should have lastInterestDate set
          expect(migratedWallet.lastInterestDate, isNotNull,
              reason: 'Wallet $walletId should have lastInterestDate set (iteration $iteration)');
          
          // Property: Each wallet should have accruedInterest set to 0
          expect(migratedWallet.accruedInterest, equals(0.0),
              reason: 'Wallet $walletId should have accruedInterest set to 0 (iteration $iteration)');
        }

        // Clean up for next iteration
        await migrationService.rollbackMigration();
        await dataService.clearAllData();
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
      }
    });

    test('Property 37: Default values should remain consistent across migration reruns', () async {
      for (int i = 0; i < 100; i++) {
        // Create a bank account without interestRate
        final wallet = Wallet(
          id: const Uuid().v4(),
          name: PropertyTest.randomString(minLength: 5, maxLength: 30),
          balance: PropertyTest.randomDouble(min: -50000, max: 50000),
          type: 'bank',
          color: '#${PropertyTest.randomInt(min: 0, max: 0xFFFFFF).toRadixString(16).padLeft(6, '0')}',
          icon: 'account_balance',
          creditLimit: PropertyTest.randomPositiveDouble(min: 1000, max: 100000),
          interestRate: null,
          lastInterestDate: null,
          accruedInterest: null,
        );

        // Add wallet to database
        await dataService.addWallet(wallet);

        // Run migration first time
        final result1 = await migrationService.migrateKmhAccounts();

        // Property: First migration should succeed
        expect(result1.success, isTrue,
            reason: 'First migration should succeed (iteration $i)');

        // Get wallet after first migration
        final walletsAfterFirst = await dataService.getWallets();
        final walletAfterFirst = walletsAfterFirst.firstWhere((w) => w.id == wallet.id);
        
        // Property: Should have default values
        expect(walletAfterFirst.interestRate, equals(24.0),
            reason: 'Should have default interestRate after first migration (iteration $i)');
        
        final firstInterestRate = walletAfterFirst.interestRate;
        final firstLastInterestDate = walletAfterFirst.lastInterestDate;
        final firstAccruedInterest = walletAfterFirst.accruedInterest;

        // Reset migration flag to allow second run
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('kmh_migration_v1_completed');

        // Run migration second time
        final result2 = await migrationService.migrateKmhAccounts();

        // Property: Second migration should succeed
        expect(result2.success, isTrue,
            reason: 'Second migration should succeed (iteration $i)');

        // Get wallet after second migration
        final walletsAfterSecond = await dataService.getWallets();
        final walletAfterSecond = walletsAfterSecond.firstWhere((w) => w.id == wallet.id);
        
        // Property: Values should remain the same (not overwritten)
        expect(walletAfterSecond.interestRate, equals(firstInterestRate),
            reason: 'interestRate should remain consistent across reruns (iteration $i)');
        expect(walletAfterSecond.lastInterestDate, equals(firstLastInterestDate),
            reason: 'lastInterestDate should remain consistent across reruns (iteration $i)');
        expect(walletAfterSecond.accruedInterest, equals(firstAccruedInterest),
            reason: 'accruedInterest should remain consistent across reruns (iteration $i)');

        // Clean up for next iteration
        await migrationService.rollbackMigration();
        await dataService.clearAllData();
        await prefs.clear();
      }
    });
  });
}
