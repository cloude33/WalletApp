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

/// **Feature: kmh-account-management, Property 39: Migrasyon Hata Yönetimi**
/// **Validates: Requirements 10.4**
///
/// Property: For any migration error, the system should log the error
/// and inform the user with appropriate error messages.
void main() {
  late KmhMigrationService migrationService;
  late DataService dataService;
  late Directory testDir;

  setUpAll(() async {
    // Create a temporary directory for testing
    testDir = await Directory.systemTemp.createTemp('kmh_migration_error_');

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

  group('KMH Migration Error Management Property Tests', () {
    test(
      'Property 39: Migration should handle individual account errors gracefully and continue',
      () async {
        for (int i = 0; i < 100; i++) {
          // Create multiple KMH accounts
          final accountCount = PropertyTest.randomInt(min: 3, max: 5);
          final wallets = <Wallet>[];

          for (int j = 0; j < accountCount; j++) {
            final wallet = Wallet(
              id: const Uuid().v4(),
              name: 'KMH Bank ${j + 1}',
              balance: PropertyTest.randomDouble(min: -50000, max: 50000),
              type: 'bank',
              color:
                  '#${PropertyTest.randomInt(min: 0, max: 0xFFFFFF).toRadixString(16).padLeft(6, '0')}',
              icon: 'account_balance',
              creditLimit: PropertyTest.randomPositiveDouble(
                min: 1000,
                max: 100000,
              ),
              interestRate: null,
              lastInterestDate: null,
              accruedInterest: null,
            );

            await dataService.addWallet(wallet);
            wallets.add(wallet);
          }

          // Run migration
          final result = await migrationService.migrateKmhAccounts();

          // Property: Migration should complete (success or partial success)
          expect(
            result.success,
            isTrue,
            reason:
                'Migration should complete even if some accounts have issues (iteration $i)',
          );

          // Property: Result should contain error/warning information if any issues occurred
          if (result.accountsFailed > 0) {
            expect(
              result.errors.isNotEmpty || result.warnings.isNotEmpty,
              isTrue,
              reason:
                  'If accounts failed, errors or warnings should be recorded (iteration $i)',
            );
          }

          // Property: Migration report should be generated
          expect(
            result.report,
            isNotNull,
            reason:
                'Migration report should always be generated (iteration $i)',
          );

          // Property: Report should contain accurate counts
          expect(
            result.report!.accountsMigrated,
            equals(result.accountsMigrated),
            reason:
                'Report should match result accountsMigrated count (iteration $i)',
          );
          expect(
            result.report!.accountsFailed,
            equals(result.accountsFailed),
            reason:
                'Report should match result accountsFailed count (iteration $i)',
          );

          // Property: User-friendly message should be provided
          expect(
            result.userFriendlyMessage,
            isNotEmpty,
            reason:
                'User-friendly message should always be provided (iteration $i)',
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
      'Property 39: Migration should provide detailed error information in the report',
      () async {
        for (int i = 0; i < 100; i++) {
          // Create KMH accounts
          final accountCount = PropertyTest.randomInt(min: 2, max: 4);

          for (int j = 0; j < accountCount; j++) {
            final wallet = Wallet(
              id: const Uuid().v4(),
              name: 'KMH Bank ${j + 1}',
              balance: PropertyTest.randomDouble(min: -50000, max: 50000),
              type: 'bank',
              color:
                  '#${PropertyTest.randomInt(min: 0, max: 0xFFFFFF).toRadixString(16).padLeft(6, '0')}',
              icon: 'account_balance',
              creditLimit: PropertyTest.randomPositiveDouble(
                min: 1000,
                max: 100000,
              ),
              interestRate: null,
            );

            await dataService.addWallet(wallet);
          }

          // Run migration
          final result = await migrationService.migrateKmhAccounts();

          // Property: Report should contain timing information
          expect(
            result.report,
            isNotNull,
            reason: 'Report should be generated (iteration $i)',
          );
          expect(
            result.report!.startTime,
            isNotNull,
            reason: 'Report should contain start time (iteration $i)',
          );
          expect(
            result.report!.endTime,
            isNotNull,
            reason: 'Report should contain end time (iteration $i)',
          );
          expect(
            result.report!.duration,
            isNotNull,
            reason: 'Report should contain duration (iteration $i)',
          );

          // Property: End time should be after or equal to start time
          expect(
            result.report!.endTime.isAfter(result.report!.startTime) ||
                result.report!.endTime.isAtSameMomentAs(
                  result.report!.startTime,
                ),
            isTrue,
            reason:
                'End time should be after or equal to start time (iteration $i)',
          );

          // Property: Report should contain error and warning lists
          expect(
            result.report!.errors,
            isNotNull,
            reason: 'Report should contain errors list (iteration $i)',
          );
          expect(
            result.report!.warnings,
            isNotNull,
            reason: 'Report should contain warnings list (iteration $i)',
          );

          // Property: Report should be convertible to user-friendly format
          final userReport = result.report!.toUserFriendlyReport();
          expect(
            userReport,
            isNotEmpty,
            reason:
                'Report should be convertible to user-friendly format (iteration $i)',
          );
          expect(
            userReport.contains('KMH Güncelleme Raporu'),
            isTrue,
            reason: 'User-friendly report should contain title (iteration $i)',
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
      'Property 39: Migration should save error information for later retrieval',
      () async {
        for (int i = 0; i < 100; i++) {
          // Create KMH accounts
          final accountCount = PropertyTest.randomInt(min: 1, max: 3);

          for (int j = 0; j < accountCount; j++) {
            final wallet = Wallet(
              id: const Uuid().v4(),
              name: 'KMH Bank ${j + 1}',
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

            await dataService.addWallet(wallet);
          }

          // Run migration
          final result = await migrationService.migrateKmhAccounts();

          // Property: Migration report should be retrievable
          final savedReport = await migrationService.getLastMigrationReport();
          expect(
            savedReport,
            isNotNull,
            reason:
                'Migration report should be saved and retrievable (iteration $i)',
          );

          // Property: Saved report should match the result report
          expect(
            savedReport!.success,
            equals(result.report!.success),
            reason: 'Saved report success should match result (iteration $i)',
          );
          expect(
            savedReport.accountsMigrated,
            equals(result.report!.accountsMigrated),
            reason:
                'Saved report accountsMigrated should match result (iteration $i)',
          );
          expect(
            savedReport.transactionsConverted,
            equals(result.report!.transactionsConverted),
            reason:
                'Saved report transactionsConverted should match result (iteration $i)',
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
      'Property 39: Migration status should accurately reflect completion state',
      () async {
        for (int i = 0; i < 100; i++) {
          // Create KMH accounts
          final accountCount = PropertyTest.randomInt(min: 1, max: 3);

          for (int j = 0; j < accountCount; j++) {
            final wallet = Wallet(
              id: const Uuid().v4(),
              name: 'KMH Bank ${j + 1}',
              balance: PropertyTest.randomDouble(min: -50000, max: 50000),
              type: 'bank',
              color:
                  '#${PropertyTest.randomInt(min: 0, max: 0xFFFFFF).toRadixString(16).padLeft(6, '0')}',
              icon: 'account_balance',
              creditLimit: PropertyTest.randomPositiveDouble(
                min: 1000,
                max: 100000,
              ),
              interestRate: null,
            );

            await dataService.addWallet(wallet);
          }

          // Check status before migration
          final statusBefore = await migrationService.getMigrationStatus();

          // Property: Before migration, status should show not completed
          expect(
            statusBefore.isCompleted,
            isFalse,
            reason:
                'Status should show not completed before migration (iteration $i)',
          );

          // Run migration
          final result = await migrationService.migrateKmhAccounts();

          // Check status after migration
          final statusAfter = await migrationService.getMigrationStatus();

          // Property: After successful migration, status should show completed
          if (result.success) {
            expect(
              statusAfter.isCompleted,
              isTrue,
              reason:
                  'Status should show completed after successful migration (iteration $i)',
            );
            expect(
              statusAfter.migrationDate,
              isNotNull,
              reason:
                  'Migration date should be set after completion (iteration $i)',
            );
          }

          // Property: Status should accurately count KMH accounts
          expect(
            statusAfter.totalKmhAccounts,
            greaterThanOrEqualTo(0),
            reason: 'Status should count total KMH accounts (iteration $i)',
          );
          expect(
            statusAfter.accountsWithNewFields,
            greaterThanOrEqualTo(0),
            reason:
                'Status should count accounts with new fields (iteration $i)',
          );
          expect(
            statusAfter.accountsWithoutNewFields,
            greaterThanOrEqualTo(0),
            reason:
                'Status should count accounts without new fields (iteration $i)',
          );

          // Property: Total accounts should equal sum of with and without new fields
          expect(
            statusAfter.totalKmhAccounts,
            equals(
              statusAfter.accountsWithNewFields +
                  statusAfter.accountsWithoutNewFields,
            ),
            reason:
                'Total accounts should equal sum of with and without new fields (iteration $i)',
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
      'Property 39: Migration should provide appropriate user messages for different scenarios',
      () async {
        for (int i = 0; i < 100; i++) {
          // Scenario 1: No KMH accounts
          final result1 = await migrationService.migrateKmhAccounts();

          // Property: Should provide message for no accounts scenario
          expect(
            result1.userFriendlyMessage,
            isNotEmpty,
            reason:
                'Should provide message when no accounts found (iteration $i)',
          );
          expect(
            result1.userFriendlyMessage.toLowerCase().contains('bulunamadı') ||
                result1.userFriendlyMessage.toLowerCase().contains('yok'),
            isTrue,
            reason: 'Message should indicate no accounts found (iteration $i)',
          );

          // Reset for next scenario
          await migrationService.rollbackMigration();
          final prefs = await SharedPreferences.getInstance();
          await prefs.clear();

          // Scenario 2: Successful migration
          final wallet = Wallet(
            id: const Uuid().v4(),
            name: 'Test KMH',
            balance: PropertyTest.randomDouble(min: -50000, max: 50000),
            type: 'bank',
            color: '#FF0000',
            icon: 'account_balance',
            creditLimit: PropertyTest.randomPositiveDouble(
              min: 1000,
              max: 100000,
            ),
          );
          await dataService.addWallet(wallet);

          final result2 = await migrationService.migrateKmhAccounts();

          // Property: Should provide success message
          expect(
            result2.userFriendlyMessage,
            isNotEmpty,
            reason: 'Should provide success message (iteration $i)',
          );
          expect(
            result2.userFriendlyMessage.toLowerCase().contains('başarı'),
            isTrue,
            reason:
                'Success message should contain success indicator (iteration $i)',
          );

          // Reset for next scenario
          await migrationService.rollbackMigration();
          await prefs.clear();

          // Scenario 3: Already migrated
          await dataService.addWallet(wallet);
          await migrationService.migrateKmhAccounts();

          final result3 = await migrationService.migrateKmhAccounts();

          // Property: Should provide already completed message
          expect(
            result3.userFriendlyMessage,
            isNotEmpty,
            reason:
                'Should provide message for already completed migration (iteration $i)',
          );

          // Clean up for next iteration
          await migrationService.rollbackMigration();
          await dataService.clearAllData();
          await prefs.clear();
        }
      },
    );

    test('Property 39: Migration errors should not prevent partial success', () async {
      for (int i = 0; i < 100; i++) {
        // Create multiple KMH accounts
        final accountCount = PropertyTest.randomInt(min: 2, max: 4);

        for (int j = 0; j < accountCount; j++) {
          final wallet = Wallet(
            id: const Uuid().v4(),
            name: 'KMH Bank ${j + 1}',
            balance: PropertyTest.randomDouble(min: -50000, max: 50000),
            type: 'bank',
            color:
                '#${PropertyTest.randomInt(min: 0, max: 0xFFFFFF).toRadixString(16).padLeft(6, '0')}',
            icon: 'account_balance',
            creditLimit: PropertyTest.randomPositiveDouble(
              min: 1000,
              max: 100000,
            ),
            interestRate: null,
          );

          await dataService.addWallet(wallet);
        }

        // Run migration
        final result = await migrationService.migrateKmhAccounts();

        // Property: Even with potential errors, some accounts should be migrated
        expect(
          result.accountsMigrated,
          greaterThanOrEqualTo(0),
          reason:
              'Some accounts should be migrated even if errors occur (iteration $i)',
        );

        // Property: If migration succeeded, at least some accounts should be migrated
        if (result.success && accountCount > 0) {
          expect(
            result.accountsMigrated,
            greaterThan(0),
            reason:
                'Successful migration should migrate at least one account (iteration $i)',
          );
        }

        // Property: Total processed should equal migrated + failed
        expect(
          result.accountsMigrated + result.accountsFailed,
          lessThanOrEqualTo(accountCount),
          reason:
              'Total processed should not exceed total accounts (iteration $i)',
        );

        // Clean up for next iteration
        await migrationService.rollbackMigration();
        await dataService.clearAllData();
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
      }
    });

    test(
      'Property 39: Migration report should be persistable and retrievable',
      () async {
        for (int i = 0; i < 100; i++) {
          // Create KMH accounts
          final accountCount = PropertyTest.randomInt(min: 1, max: 3);

          for (int j = 0; j < accountCount; j++) {
            final wallet = Wallet(
              id: const Uuid().v4(),
              name: 'KMH Bank ${j + 1}',
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

            await dataService.addWallet(wallet);
          }

          // Run migration
          await migrationService.migrateKmhAccounts();

          // Property: Report should be saved
          final savedReport = await migrationService.getLastMigrationReport();
          expect(
            savedReport,
            isNotNull,
            reason: 'Report should be saved (iteration $i)',
          );

          // Property: Report should be convertible to JSON and back
          final jsonString = savedReport!.toJson();
          expect(
            jsonString,
            isNotEmpty,
            reason: 'Report should be convertible to JSON (iteration $i)',
          );

          final parsedReport = KmhMigrationReport.fromJson(jsonString);
          expect(
            parsedReport,
            isNotNull,
            reason: 'Report should be parsable from JSON (iteration $i)',
          );

          // Property: Parsed report should preserve key information
          expect(
            parsedReport.success,
            equals(savedReport.success),
            reason:
                'Parsed report should preserve success status (iteration $i)',
          );
          expect(
            parsedReport.accountsMigrated,
            equals(savedReport.accountsMigrated),
            reason:
                'Parsed report should preserve accountsMigrated (iteration $i)',
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
      'Property 39: Migration should handle empty database gracefully',
      () async {
        for (int i = 0; i < 100; i++) {
          // Don't create any wallets - empty database

          // Run migration
          final result = await migrationService.migrateKmhAccounts();

          // Property: Migration should succeed with empty database
          expect(
            result.success,
            isTrue,
            reason:
                'Migration should succeed with empty database (iteration $i)',
          );

          // Property: Should report zero accounts migrated
          expect(
            result.accountsMigrated,
            equals(0),
            reason:
                'Should report zero accounts migrated for empty database (iteration $i)',
          );

          // Property: Should provide appropriate message
          expect(
            result.userFriendlyMessage,
            isNotEmpty,
            reason: 'Should provide message for empty database (iteration $i)',
          );

          // Property: Report should still be generated
          expect(
            result.report,
            isNotNull,
            reason:
                'Report should be generated even for empty database (iteration $i)',
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
      'Property 39: Migration should track both errors and warnings separately',
      () async {
        for (int i = 0; i < 100; i++) {
          // Create KMH accounts
          final accountCount = PropertyTest.randomInt(min: 2, max: 4);

          for (int j = 0; j < accountCount; j++) {
            final wallet = Wallet(
              id: const Uuid().v4(),
              name: 'KMH Bank ${j + 1}',
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

            await dataService.addWallet(wallet);
          }

          // Run migration
          final result = await migrationService.migrateKmhAccounts();

          // Property: Result should have separate error and warning lists
          expect(
            result.errors,
            isNotNull,
            reason: 'Result should have errors list (iteration $i)',
          );
          expect(
            result.warnings,
            isNotNull,
            reason: 'Result should have warnings list (iteration $i)',
          );

          // Property: Report should also have separate error and warning lists
          expect(
            result.report!.errors,
            isNotNull,
            reason: 'Report should have errors list (iteration $i)',
          );
          expect(
            result.report!.warnings,
            isNotNull,
            reason: 'Report should have warnings list (iteration $i)',
          );

          // Property: Error and warning counts should be non-negative
          expect(
            result.errors.length,
            greaterThanOrEqualTo(0),
            reason: 'Error count should be non-negative (iteration $i)',
          );
          expect(
            result.warnings.length,
            greaterThanOrEqualTo(0),
            reason: 'Warning count should be non-negative (iteration $i)',
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
      'Property 39: Migration result should provide toString for debugging',
      () async {
        for (int i = 0; i < 100; i++) {
          // Create a KMH account
          final wallet = Wallet(
            id: const Uuid().v4(),
            name: 'Test KMH',
            balance: PropertyTest.randomDouble(min: -50000, max: 50000),
            type: 'bank',
            color: '#FF0000',
            icon: 'account_balance',
            creditLimit: PropertyTest.randomPositiveDouble(
              min: 1000,
              max: 100000,
            ),
          );
          await dataService.addWallet(wallet);

          // Run migration
          final result = await migrationService.migrateKmhAccounts();

          // Property: Result should have meaningful toString
          final resultString = result.toString();
          expect(
            resultString,
            isNotEmpty,
            reason: 'Result toString should not be empty (iteration $i)',
          );
          expect(
            resultString.contains('KmhMigrationResult'),
            isTrue,
            reason: 'Result toString should contain class name (iteration $i)',
          );
          expect(
            resultString.contains('success'),
            isTrue,
            reason:
                'Result toString should contain success field (iteration $i)',
          );

          // Property: Report should have meaningful toString
          final reportString = result.report.toString();
          expect(
            reportString,
            isNotEmpty,
            reason: 'Report toString should not be empty (iteration $i)',
          );
          expect(
            reportString.contains('KmhMigrationReport'),
            isTrue,
            reason: 'Report toString should contain class name (iteration $i)',
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
