import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:parion/models/wallet.dart';
import 'package:parion/models/kmh_transaction.dart';
import 'package:parion/models/kmh_transaction_type.dart';
import 'package:parion/services/kmh_migration_service.dart';
import 'package:parion/services/data_service.dart';
import 'package:parion/services/kmh_box_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../property_test_utils.dart';
import 'package:uuid/uuid.dart';

/// **Feature: kmh-account-management, Property 36: Migrasyon Tespit**
/// **Validates: Requirements 10.1**
///
/// Property: For any existing wallet, if type='bank' and creditLimit > 0,
/// the migration should detect it as a KMH account candidate.
void main() {
  late KmhMigrationService migrationService;
  late DataService dataService;
  late Directory testDir;

  setUpAll(() async {
    // Create a temporary directory for testing
    testDir = await Directory.systemTemp.createTemp('kmh_migration_test_');

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

  group('KMH Migration Detection Property Tests', () {
    test(
      'Property 36: Bank accounts with creditLimit > 0 should be detected as KMH candidates',
      () async {
        for (int i = 0; i < 100; i++) {
          // Create a bank account with creditLimit > 0 (KMH candidate)
          final wallet = Wallet(
            id: const Uuid().v4(),
            name: PropertyTest.randomString(minLength: 5, maxLength: 30),
            balance: PropertyTest.randomDouble(min: -50000, max: 50000),
            type: 'bank',
            color:
                '#${PropertyTest.randomInt(min: 0, max: 0xFFFFFF).toRadixString(16).padLeft(6, '0')}',
            icon: 'account_balance',
            creditLimit: PropertyTest.randomPositiveDouble(
              min: 1000,
              max: 100000,
            ),
          );

          // Add wallet to database
          await dataService.addWallet(wallet);

          // Run migration
          final result = await migrationService.migrateKmhAccounts();

          // Property: Migration should succeed
          expect(
            result.success,
            isTrue,
            reason:
                'Migration should succeed for valid KMH candidate (iteration $i)',
          );

          // Property: Should detect and migrate exactly 1 account
          expect(
            result.accountsMigrated,
            equals(1),
            reason:
                'Should detect and migrate the KMH candidate account (iteration $i)',
          );

          // Verify the wallet was detected as KMH
          final wallets = await dataService.getWallets();
          final migratedWallet = wallets.firstWhere((w) => w.id == wallet.id);

          // Property: Migrated wallet should be identified as KMH account
          expect(
            migratedWallet.isKmhAccount,
            isTrue,
            reason:
                'Migrated wallet should be identified as KMH account (iteration $i)',
          );

          // Property: Migrated wallet should have required KMH fields
          expect(
            migratedWallet.interestRate,
            isNotNull,
            reason: 'Migrated wallet should have interestRate (iteration $i)',
          );
          expect(
            migratedWallet.lastInterestDate,
            isNotNull,
            reason:
                'Migrated wallet should have lastInterestDate (iteration $i)',
          );
          expect(
            migratedWallet.accruedInterest,
            isNotNull,
            reason:
                'Migrated wallet should have accruedInterest (iteration $i)',
          );

          // Clean up for next iteration
          await migrationService.rollbackMigration();
          await dataService.clearAllData();
          final prefs = await SharedPreferences.getInstance();
          await prefs.clear();
        }
      },
    );

    test(
      'Property 36: Bank accounts with creditLimit = 0 should NOT be detected as KMH candidates',
      () async {
        for (int i = 0; i < 100; i++) {
          // Create a bank account with creditLimit = 0 (NOT a KMH candidate)
          final wallet = Wallet(
            id: const Uuid().v4(),
            name: PropertyTest.randomString(minLength: 5, maxLength: 30),
            balance: PropertyTest.randomDouble(min: -50000, max: 50000),
            type: 'bank',
            color:
                '#${PropertyTest.randomInt(min: 0, max: 0xFFFFFF).toRadixString(16).padLeft(6, '0')}',
            icon: 'account_balance',
            creditLimit: 0.0,
          );

          // Add wallet to database
          await dataService.addWallet(wallet);

          // Run migration
          final result = await migrationService.migrateKmhAccounts();

          // Property: Migration should succeed but find no candidates
          expect(
            result.success,
            isTrue,
            reason:
                'Migration should succeed even with no candidates (iteration $i)',
          );

          // Property: Should NOT detect or migrate any accounts
          expect(
            result.accountsMigrated,
            equals(0),
            reason:
                'Should not detect bank account with creditLimit = 0 as KMH candidate (iteration $i)',
          );

          // Verify the wallet was NOT modified
          final wallets = await dataService.getWallets();
          final unchangedWallet = wallets.firstWhere((w) => w.id == wallet.id);

          // Property: Wallet should NOT be identified as KMH account
          expect(
            unchangedWallet.isKmhAccount,
            isFalse,
            reason:
                'Bank account with creditLimit = 0 should not be KMH (iteration $i)',
          );

          // Property: Wallet should NOT have KMH fields added
          expect(
            unchangedWallet.interestRate,
            isNull,
            reason:
                'Non-KMH wallet should not have interestRate added (iteration $i)',
          );

          // Clean up for next iteration
          await migrationService.rollbackMigration();
          await dataService.clearAllData();
          final prefs = await SharedPreferences.getInstance();
          await prefs.clear();
        }
      },
    );

    test(
      'Property 36: Non-bank accounts should NOT be detected as KMH candidates regardless of creditLimit',
      () async {
        for (int i = 0; i < 100; i++) {
          final types = ['cash', 'credit_card'];
          final type =
              types[PropertyTest.randomInt(min: 0, max: types.length - 1)];

          // Create a non-bank account with creditLimit > 0 (NOT a KMH candidate)
          final wallet = Wallet(
            id: const Uuid().v4(),
            name: PropertyTest.randomString(minLength: 5, maxLength: 30),
            balance: PropertyTest.randomDouble(min: -50000, max: 50000),
            type: type,
            color:
                '#${PropertyTest.randomInt(min: 0, max: 0xFFFFFF).toRadixString(16).padLeft(6, '0')}',
            icon: 'account_balance_wallet',
            creditLimit: PropertyTest.randomPositiveDouble(
              min: 1000,
              max: 100000,
            ),
          );

          // Add wallet to database
          await dataService.addWallet(wallet);

          // Run migration
          final result = await migrationService.migrateKmhAccounts();

          // Property: Migration should succeed but find no candidates
          expect(
            result.success,
            isTrue,
            reason:
                'Migration should succeed even with no candidates (iteration $i)',
          );

          // Property: Should NOT detect or migrate any accounts
          expect(
            result.accountsMigrated,
            equals(0),
            reason:
                'Should not detect non-bank account ($type) as KMH candidate even with creditLimit > 0 (iteration $i)',
          );

          // Verify the wallet was NOT modified
          final wallets = await dataService.getWallets();
          final unchangedWallet = wallets.firstWhere((w) => w.id == wallet.id);

          // Property: Wallet should NOT be identified as KMH account
          expect(
            unchangedWallet.isKmhAccount,
            isFalse,
            reason: 'Non-bank account should not be KMH (iteration $i)',
          );

          // Property: Wallet should NOT have KMH fields added
          expect(
            unchangedWallet.interestRate,
            isNull,
            reason:
                'Non-KMH wallet should not have interestRate added (iteration $i)',
          );

          // Clean up for next iteration
          await migrationService.rollbackMigration();
          await dataService.clearAllData();
          final prefs = await SharedPreferences.getInstance();
          await prefs.clear();
        }
      },
    );

    test(
      'Property 36: Migration should detect all KMH candidates in a mixed wallet set',
      () async {
        for (int iteration = 0; iteration < 100; iteration++) {
          // Generate a random number of KMH candidates (1-5)
          final kmhCount = PropertyTest.randomInt(min: 1, max: 5);
          final wallets = <Wallet>[];

          // Create KMH candidates (bank + creditLimit > 0)
          for (int i = 0; i < kmhCount; i++) {
            wallets.add(
              Wallet(
                id: const Uuid().v4(),
                name: 'KMH Bank ${i + 1}',
                balance: PropertyTest.randomDouble(min: -50000, max: 50000),
                type: 'bank',
                color: '#FF0000',
                icon: 'account_balance',
                creditLimit: PropertyTest.randomPositiveDouble(
                  min: 1000,
                  max: 100000,
                ),
              ),
            );
          }

          // Create non-KMH wallets (random types, some with creditLimit = 0)
          final nonKmhCount = PropertyTest.randomInt(min: 1, max: 5);
          for (int i = 0; i < nonKmhCount; i++) {
            final types = ['cash', 'credit_card', 'bank'];
            final type =
                types[PropertyTest.randomInt(min: 0, max: types.length - 1)];

            wallets.add(
              Wallet(
                id: const Uuid().v4(),
                name: 'Non-KMH ${i + 1}',
                balance: PropertyTest.randomDouble(min: -50000, max: 50000),
                type: type,
                color: '#00FF00',
                icon: 'account_balance_wallet',
                creditLimit: type == 'bank'
                    ? 0.0
                    : PropertyTest.randomPositiveDouble(min: 0, max: 100000),
              ),
            );
          }

          // Add all wallets to database
          for (var wallet in wallets) {
            await dataService.addWallet(wallet);
          }

          // Run migration
          final result = await migrationService.migrateKmhAccounts();

          // Property: Migration should succeed
          expect(
            result.success,
            isTrue,
            reason:
                'Migration should succeed for mixed wallet set (iteration $iteration)',
          );

          // Property: Should detect and migrate exactly kmhCount accounts
          expect(
            result.accountsMigrated,
            equals(kmhCount),
            reason:
                'Should detect exactly $kmhCount KMH candidates out of ${wallets.length} total wallets (iteration $iteration)',
          );

          // Verify all KMH candidates were migrated
          final allWallets = await dataService.getWallets();
          final migratedKmhAccounts = allWallets
              .where(
                (w) =>
                    w.type == 'bank' &&
                    w.creditLimit > 0 &&
                    w.interestRate != null,
              )
              .toList();

          // Property: Number of migrated KMH accounts should match expected count
          expect(
            migratedKmhAccounts.length,
            equals(kmhCount),
            reason:
                'All KMH candidates should be migrated (iteration $iteration)',
          );

          // Property: All migrated accounts should have required KMH fields
          for (var account in migratedKmhAccounts) {
            expect(
              account.interestRate,
              isNotNull,
              reason:
                  'Migrated account ${account.name} should have interestRate (iteration $iteration)',
            );
            expect(
              account.lastInterestDate,
              isNotNull,
              reason:
                  'Migrated account ${account.name} should have lastInterestDate (iteration $iteration)',
            );
            expect(
              account.accruedInterest,
              isNotNull,
              reason:
                  'Migrated account ${account.name} should have accruedInterest (iteration $iteration)',
            );
          }

          // Clean up for next iteration
          await migrationService.rollbackMigration();
          await dataService.clearAllData();
          final prefs = await SharedPreferences.getInstance();
          await prefs.clear();
        }
      },
    );

    test(
      'Property 36: Migration detection should be consistent across multiple runs (idempotency)',
      () async {
        for (int i = 0; i < 100; i++) {
          // Create a KMH candidate
          final wallet = Wallet(
            id: const Uuid().v4(),
            name: PropertyTest.randomString(minLength: 5, maxLength: 30),
            balance: PropertyTest.randomDouble(min: -50000, max: 50000),
            type: 'bank',
            color:
                '#${PropertyTest.randomInt(min: 0, max: 0xFFFFFF).toRadixString(16).padLeft(6, '0')}',
            icon: 'account_balance',
            creditLimit: PropertyTest.randomPositiveDouble(
              min: 1000,
              max: 100000,
            ),
          );

          // Add wallet to database
          await dataService.addWallet(wallet);

          // Run migration first time
          final result1 = await migrationService.migrateKmhAccounts();

          // Property: First migration should succeed and detect the account
          expect(
            result1.success,
            isTrue,
            reason: 'First migration should succeed (iteration $i)',
          );
          expect(
            result1.accountsMigrated,
            equals(1),
            reason: 'First migration should detect 1 account (iteration $i)',
          );

          // Get migration status
          final status = await migrationService.getMigrationStatus();

          // Property: Migration should be marked as completed
          expect(
            status.isCompleted,
            isTrue,
            reason:
                'Migration should be marked as completed after first run (iteration $i)',
          );

          // Run migration second time (idempotency test)
          final result2 = await migrationService.migrateKmhAccounts();

          // Property: Second migration should succeed but not migrate again
          expect(
            result2.success,
            isTrue,
            reason: 'Second migration should succeed (iteration $i)',
          );
          expect(
            result2.accountsMigrated,
            equals(0),
            reason:
                'Second migration should not migrate accounts again - idempotency (iteration $i)',
          );

          // Verify the wallet is still a KMH account
          final wallets = await dataService.getWallets();
          final kmhWallet = wallets.firstWhere((w) => w.id == wallet.id);

          // Property: Wallet should still be identified as KMH account
          expect(
            kmhWallet.isKmhAccount,
            isTrue,
            reason:
                'Wallet should remain as KMH account after multiple migration runs (iteration $i)',
          );

          // Clean up for next iteration
          await migrationService.rollbackMigration();
          await dataService.clearAllData();
          final prefs = await SharedPreferences.getInstance();
          await prefs.clear();
        }
      },
    );
  });
}
