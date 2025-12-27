import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:money/models/wallet.dart';
import 'package:money/models/transaction.dart';
import 'package:money/models/kmh_transaction.dart';
import 'package:money/models/kmh_transaction_type.dart';
import 'package:money/services/kmh_migration_service.dart';
import 'package:money/services/data_service.dart';
import 'package:money/services/kmh_box_service.dart';
import 'package:money/repositories/kmh_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../property_test_utils.dart';
import 'package:uuid/uuid.dart';

/// **Feature: kmh-account-management, Property 38: İşlem Migrasyonu**
/// **Validates: Requirements 10.3**
/// 
/// Property: For any existing transaction, if the related wallet is KMH,
/// the transaction should be converted to KmhTransaction.
void main() {
  late KmhMigrationService migrationService;
  late DataService dataService;
  late KmhRepository kmhRepository;
  late Directory testDir;

  setUpAll(() async {
    // Create a temporary directory for testing
    testDir = await Directory.systemTemp.createTemp('kmh_transaction_migration_');
    
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

  group('KMH Transaction Migration Property Tests', () {
    test('Property 38: Transactions for KMH accounts should be converted to KmhTransaction', () async {
      for (int i = 0; i < 100; i++) {
        // Create a KMH account (bank + creditLimit > 0)
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

        // Create a random number of transactions for this wallet
        final transactionCount = PropertyTest.randomInt(min: 1, max: 10);
        final transactionIds = <String>[];
        
        for (int j = 0; j < transactionCount; j++) {
          final transactionTypes = ['income', 'expense', 'transfer'];
          final transactionType = transactionTypes[PropertyTest.randomInt(min: 0, max: transactionTypes.length - 1)];
          
          final transaction = Transaction(
            id: const Uuid().v4(),
            type: transactionType,
            amount: PropertyTest.randomPositiveDouble(min: 10, max: 10000),
            description: PropertyTest.randomString(minLength: 5, maxLength: 50),
            category: PropertyTest.randomString(minLength: 3, maxLength: 20),
            walletId: wallet.id,
            date: DateTime.now().subtract(Duration(days: PropertyTest.randomInt(min: 0, max: 365))),
            isIncome: transactionType == 'income',
          );
          
          await dataService.addTransaction(transaction);
          transactionIds.add(transaction.id);
        }

        // Run migration
        final result = await migrationService.migrateKmhAccounts();

        // Property: Migration should succeed
        expect(result.success, isTrue,
            reason: 'Migration should succeed (iteration $i)');

        // Property: Should convert all transactions
        expect(result.transactionsConverted, equals(transactionCount),
            reason: 'Should convert all $transactionCount transactions (iteration $i)');

        // Verify KmhTransactions were created
        final kmhTransactions = await kmhRepository.getTransactions(wallet.id);
        
        // Property: Number of KmhTransactions should match original transaction count
        expect(kmhTransactions.length, equals(transactionCount),
            reason: 'Should create $transactionCount KmhTransactions (iteration $i)');

        // Property: Each KmhTransaction should have a linkedTransactionId
        for (var kmhTransaction in kmhTransactions) {
          expect(kmhTransaction.linkedTransactionId, isNotNull,
              reason: 'KmhTransaction should have linkedTransactionId (iteration $i)');
          expect(transactionIds.contains(kmhTransaction.linkedTransactionId), isTrue,
              reason: 'linkedTransactionId should reference an original transaction (iteration $i)');
        }

        // Property: Each KmhTransaction should have the correct walletId
        for (var kmhTransaction in kmhTransactions) {
          expect(kmhTransaction.walletId, equals(wallet.id),
              reason: 'KmhTransaction should have correct walletId (iteration $i)');
        }

        // Clean up for next iteration
        await migrationService.rollbackMigration();
        await dataService.clearAllData();
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
      }
    });

    test('Property 38: Transaction type mapping should be correct (expense -> withdrawal, income -> deposit)', () async {
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

        // Create an expense transaction
        final expenseTransaction = Transaction(
          id: const Uuid().v4(),
          type: 'expense',
          amount: PropertyTest.randomPositiveDouble(min: 100, max: 5000),
          description: 'Expense transaction',
          category: 'Shopping',
          walletId: wallet.id,
          date: DateTime.now(),
          isIncome: false,
        );
        
        await dataService.addTransaction(expenseTransaction);

        // Create an income transaction
        final incomeTransaction = Transaction(
          id: const Uuid().v4(),
          type: 'income',
          amount: PropertyTest.randomPositiveDouble(min: 100, max: 5000),
          description: 'Income transaction',
          category: 'Salary',
          walletId: wallet.id,
          date: DateTime.now(),
          isIncome: true,
        );
        
        await dataService.addTransaction(incomeTransaction);

        // Run migration
        final result = await migrationService.migrateKmhAccounts();

        // Property: Migration should succeed
        expect(result.success, isTrue,
            reason: 'Migration should succeed (iteration $i)');

        // Get KmhTransactions
        final kmhTransactions = await kmhRepository.getTransactions(wallet.id);
        
        // Property: Should have 2 KmhTransactions
        expect(kmhTransactions.length, equals(2),
            reason: 'Should create 2 KmhTransactions (iteration $i)');

        // Find the converted transactions
        final convertedExpense = kmhTransactions.firstWhere(
          (t) => t.linkedTransactionId == expenseTransaction.id,
        );
        final convertedIncome = kmhTransactions.firstWhere(
          (t) => t.linkedTransactionId == incomeTransaction.id,
        );

        // Property: Expense should be converted to withdrawal
        expect(convertedExpense.type, equals(KmhTransactionType.withdrawal),
            reason: 'Expense transaction should be converted to withdrawal (iteration $i)');

        // Property: Income should be converted to deposit
        expect(convertedIncome.type, equals(KmhTransactionType.deposit),
            reason: 'Income transaction should be converted to deposit (iteration $i)');

        // Clean up for next iteration
        await migrationService.rollbackMigration();
        await dataService.clearAllData();
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
      }
    });

    test('Property 38: Transaction amounts should be preserved (as absolute values)', () async {
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

        // Create transactions with various amounts (positive and negative)
        final amount1 = PropertyTest.randomPositiveDouble(min: 100, max: 5000);
        final amount2 = PropertyTest.randomPositiveDouble(min: 100, max: 5000);
        
        final transaction1 = Transaction(
          id: const Uuid().v4(),
          type: 'expense',
          amount: amount1,
          description: 'Transaction 1',
          category: 'Category',
          walletId: wallet.id,
          date: DateTime.now(),
          isIncome: false,
        );
        
        final transaction2 = Transaction(
          id: const Uuid().v4(),
          type: 'income',
          amount: amount2,
          description: 'Transaction 2',
          category: 'Category',
          walletId: wallet.id,
          date: DateTime.now(),
          isIncome: true,
        );
        
        await dataService.addTransaction(transaction1);
        await dataService.addTransaction(transaction2);

        // Run migration
        final result = await migrationService.migrateKmhAccounts();

        // Property: Migration should succeed
        expect(result.success, isTrue,
            reason: 'Migration should succeed (iteration $i)');

        // Get KmhTransactions
        final kmhTransactions = await kmhRepository.getTransactions(wallet.id);
        
        // Find the converted transactions
        final converted1 = kmhTransactions.firstWhere(
          (t) => t.linkedTransactionId == transaction1.id,
        );
        final converted2 = kmhTransactions.firstWhere(
          (t) => t.linkedTransactionId == transaction2.id,
        );

        // Property: Amounts should be preserved as absolute values
        expect(converted1.amount, equals(amount1.abs()),
            reason: 'Transaction amount should be preserved as absolute value (iteration $i)');
        expect(converted2.amount, equals(amount2.abs()),
            reason: 'Transaction amount should be preserved as absolute value (iteration $i)');

        // Clean up for next iteration
        await migrationService.rollbackMigration();
        await dataService.clearAllData();
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
      }
    });

    test('Property 38: Transaction dates and descriptions should be preserved', () async {
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

        // Create a transaction with specific date and description
        final transactionDate = DateTime.now().subtract(
          Duration(days: PropertyTest.randomInt(min: 1, max: 365)),
        );
        final transactionDescription = PropertyTest.randomString(minLength: 10, maxLength: 100);
        
        final transaction = Transaction(
          id: const Uuid().v4(),
          type: 'expense',
          amount: PropertyTest.randomPositiveDouble(min: 100, max: 5000),
          description: transactionDescription,
          category: 'Category',
          walletId: wallet.id,
          date: transactionDate,
          isIncome: false,
        );
        
        await dataService.addTransaction(transaction);

        // Run migration
        final result = await migrationService.migrateKmhAccounts();

        // Property: Migration should succeed
        expect(result.success, isTrue,
            reason: 'Migration should succeed (iteration $i)');

        // Get KmhTransactions
        final kmhTransactions = await kmhRepository.getTransactions(wallet.id);
        
        // Property: Should have 1 KmhTransaction
        expect(kmhTransactions.length, equals(1),
            reason: 'Should create 1 KmhTransaction (iteration $i)');

        final kmhTransaction = kmhTransactions.first;

        // Property: Date should be preserved
        expect(kmhTransaction.date, equals(transactionDate),
            reason: 'Transaction date should be preserved (iteration $i)');

        // Property: Description should be preserved
        expect(kmhTransaction.description, equals(transactionDescription),
            reason: 'Transaction description should be preserved (iteration $i)');

        // Clean up for next iteration
        await migrationService.rollbackMigration();
        await dataService.clearAllData();
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
      }
    });

    test('Property 38: Transactions for non-KMH accounts should NOT be converted', () async {
      for (int i = 0; i < 100; i++) {
        // Create a non-KMH account (bank with creditLimit = 0)
        final wallet = Wallet(
          id: const Uuid().v4(),
          name: PropertyTest.randomString(minLength: 5, maxLength: 30),
          balance: PropertyTest.randomDouble(min: -50000, max: 50000),
          type: 'bank',
          color: '#${PropertyTest.randomInt(min: 0, max: 0xFFFFFF).toRadixString(16).padLeft(6, '0')}',
          icon: 'account_balance',
          creditLimit: 0.0,
        );

        await dataService.addWallet(wallet);

        // Create transactions for this non-KMH wallet
        final transactionCount = PropertyTest.randomInt(min: 1, max: 5);
        
        for (int j = 0; j < transactionCount; j++) {
          final transaction = Transaction(
            id: const Uuid().v4(),
            type: 'expense',
            amount: PropertyTest.randomPositiveDouble(min: 10, max: 1000),
            description: PropertyTest.randomString(minLength: 5, maxLength: 50),
            category: 'Category',
            walletId: wallet.id,
            date: DateTime.now(),
            isIncome: false,
          );
          
          await dataService.addTransaction(transaction);
        }

        // Run migration
        final result = await migrationService.migrateKmhAccounts();

        // Property: Migration should succeed
        expect(result.success, isTrue,
            reason: 'Migration should succeed (iteration $i)');

        // Property: Should NOT convert any transactions
        expect(result.transactionsConverted, equals(0),
            reason: 'Should not convert transactions for non-KMH accounts (iteration $i)');

        // Verify no KmhTransactions were created
        final kmhTransactions = await kmhRepository.getTransactions(wallet.id);
        
        // Property: Should have 0 KmhTransactions
        expect(kmhTransactions.length, equals(0),
            reason: 'Should not create KmhTransactions for non-KMH accounts (iteration $i)');

        // Clean up for next iteration
        await migrationService.rollbackMigration();
        await dataService.clearAllData();
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
      }
    });

    test('Property 38: Migration should handle multiple KMH accounts with transactions correctly', () async {
      for (int iteration = 0; iteration < 100; iteration++) {
        // Create multiple KMH accounts
        final accountCount = PropertyTest.randomInt(min: 2, max: 5);
        final walletData = <Map<String, dynamic>>[];
        
        for (int i = 0; i < accountCount; i++) {
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
          
          // Create transactions for this wallet
          final transactionCount = PropertyTest.randomInt(min: 1, max: 5);
          final transactionIds = <String>[];
          
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
            transactionIds.add(transaction.id);
          }
          
          walletData.add({
            'wallet': wallet,
            'transactionCount': transactionCount,
            'transactionIds': transactionIds,
          });
        }

        // Run migration
        final result = await migrationService.migrateKmhAccounts();

        // Property: Migration should succeed
        expect(result.success, isTrue,
            reason: 'Migration should succeed (iteration $iteration)');

        // Calculate expected total transactions
        final expectedTotal = walletData.fold<int>(
          0,
          (sum, data) => sum + (data['transactionCount'] as int),
        );

        // Property: Should convert all transactions from all accounts
        expect(result.transactionsConverted, equals(expectedTotal),
            reason: 'Should convert all transactions from all KMH accounts (iteration $iteration)');

        // Verify each wallet's transactions
        for (var data in walletData) {
          final wallet = data['wallet'] as Wallet;
          final expectedCount = data['transactionCount'] as int;
          final originalIds = data['transactionIds'] as List<String>;
          
          final kmhTransactions = await kmhRepository.getTransactions(wallet.id);
          
          // Property: Each wallet should have correct number of KmhTransactions
          expect(kmhTransactions.length, equals(expectedCount),
              reason: 'Wallet ${wallet.name} should have $expectedCount KmhTransactions (iteration $iteration)');
          
          // Property: All KmhTransactions should link to original transactions
          for (var kmhTransaction in kmhTransactions) {
            expect(originalIds.contains(kmhTransaction.linkedTransactionId), isTrue,
                reason: 'KmhTransaction should link to original transaction (iteration $iteration)');
          }
        }

        // Clean up for next iteration
        await migrationService.rollbackMigration();
        await dataService.clearAllData();
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
      }
    });

    test('Property 38: Migration should be idempotent - transactions should not be duplicated on rerun', () async {
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
        final transactionCount = PropertyTest.randomInt(min: 2, max: 5);
        
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

        // Property: First migration should succeed
        expect(result1.success, isTrue,
            reason: 'First migration should succeed (iteration $i)');
        expect(result1.transactionsConverted, equals(transactionCount),
            reason: 'First migration should convert all transactions (iteration $i)');

        // Get KmhTransactions after first migration
        final kmhTransactionsAfterFirst = await kmhRepository.getTransactions(wallet.id);
        final countAfterFirst = kmhTransactionsAfterFirst.length;

        // Property: Should have correct number of KmhTransactions
        expect(countAfterFirst, equals(transactionCount),
            reason: 'Should have $transactionCount KmhTransactions after first migration (iteration $i)');

        // Run migration second time (idempotency test)
        final result2 = await migrationService.migrateKmhAccounts();

        // Property: Second migration should succeed but not convert again
        expect(result2.success, isTrue,
            reason: 'Second migration should succeed (iteration $i)');
        expect(result2.transactionsConverted, equals(0),
            reason: 'Second migration should not convert transactions again (iteration $i)');

        // Get KmhTransactions after second migration
        final kmhTransactionsAfterSecond = await kmhRepository.getTransactions(wallet.id);
        final countAfterSecond = kmhTransactionsAfterSecond.length;

        // Property: Number of KmhTransactions should remain the same (no duplicates)
        expect(countAfterSecond, equals(countAfterFirst),
            reason: 'KmhTransactions should not be duplicated on migration rerun (iteration $i)');

        // Clean up for next iteration
        await migrationService.rollbackMigration();
        await dataService.clearAllData();
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
      }
    });

    test('Property 38: Transfer transactions should be converted to transfer type', () async {
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

        // Create a transfer transaction
        final transferTransaction = Transaction(
          id: const Uuid().v4(),
          type: 'transfer',
          amount: PropertyTest.randomPositiveDouble(min: 100, max: 5000),
          description: 'Transfer transaction',
          category: 'Transfer',
          walletId: wallet.id,
          date: DateTime.now(),
          isIncome: false,
        );
        
        await dataService.addTransaction(transferTransaction);

        // Run migration
        final result = await migrationService.migrateKmhAccounts();

        // Property: Migration should succeed
        expect(result.success, isTrue,
            reason: 'Migration should succeed (iteration $i)');

        // Get KmhTransactions
        final kmhTransactions = await kmhRepository.getTransactions(wallet.id);
        
        // Property: Should have 1 KmhTransaction
        expect(kmhTransactions.length, equals(1),
            reason: 'Should create 1 KmhTransaction (iteration $i)');

        final kmhTransaction = kmhTransactions.first;

        // Property: Transfer should be converted to transfer type
        expect(kmhTransaction.type, equals(KmhTransactionType.transfer),
            reason: 'Transfer transaction should be converted to transfer type (iteration $i)');

        // Clean up for next iteration
        await migrationService.rollbackMigration();
        await dataService.clearAllData();
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
      }
    });
  });
}
