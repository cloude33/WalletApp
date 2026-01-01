import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:parion/models/kmh_transaction.dart';
import 'package:parion/models/kmh_transaction_type.dart';
import 'package:parion/repositories/kmh_repository.dart';
import 'package:parion/services/kmh_box_service.dart';
import '../property_test_utils.dart';
import 'package:uuid/uuid.dart';

/// **Feature: kmh-account-management, Property 9: İşlem Veri Bütünlüğü**
/// **Validates: Requirements 2.5**
/// 
/// Property: For any KMH transaction recorded, the transaction type, amount, 
/// date, and balanceAfter information should be saved and when read back 
/// should contain the same values.
void main() {
  group('KMH Repository Transaction Data Integrity Property Tests', () {
    late KmhRepository repository;
    late Directory testDir;

    setUpAll(() async {
      // Create a temporary directory for testing
      testDir = await Directory.systemTemp.createTemp('kmh_test_');
      
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
      // Clear the box before each test
      await KmhBoxService.clearAll();
      repository = KmhRepository();
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
      description: 'Property 9: Transaction data integrity - all fields preserved after save',
      generator: () {
        final types = [
          KmhTransactionType.withdrawal,
          KmhTransactionType.deposit,
          KmhTransactionType.interest,
          KmhTransactionType.fee,
          KmhTransactionType.transfer,
        ];
        
        return {
          'id': const Uuid().v4(),
          'walletId': const Uuid().v4(),
          'type': types[PropertyTest.randomInt(min: 0, max: types.length - 1)],
          'amount': PropertyTest.randomPositiveDouble(min: 0.01, max: 100000),
          'date': PropertyTest.randomDateTime(),
          'description': PropertyTest.randomString(minLength: 5, maxLength: 100),
          'balanceAfter': PropertyTest.randomDouble(min: -100000, max: 100000),
          'interestAmount': PropertyTest.randomBool() 
              ? PropertyTest.randomPositiveDouble(min: 0.01, max: 1000) 
              : null,
          'linkedTransactionId': PropertyTest.randomBool() 
              ? const Uuid().v4() 
              : null,
        };
      },
      property: (data) async {
        // Create a KMH transaction
        final transaction = KmhTransaction(
          id: data['id'],
          walletId: data['walletId'],
          type: data['type'],
          amount: data['amount'],
          date: data['date'],
          description: data['description'],
          balanceAfter: data['balanceAfter'],
          interestAmount: data['interestAmount'],
          linkedTransactionId: data['linkedTransactionId'],
        );

        // Save the transaction
        await repository.addTransaction(transaction);

        // Read it back
        final retrieved = await repository.findById(transaction.id);

        // Property 1: Transaction should be found
        expect(retrieved, isNotNull);

        // Property 2: All required fields should be preserved
        expect(retrieved!.id, equals(transaction.id));
        expect(retrieved.walletId, equals(transaction.walletId));
        expect(retrieved.type, equals(transaction.type));
        expect(retrieved.amount, equals(transaction.amount));
        expect(retrieved.description, equals(transaction.description));
        expect(retrieved.balanceAfter, equals(transaction.balanceAfter));

        // Property 3: Optional fields should be preserved
        expect(retrieved.interestAmount, equals(transaction.interestAmount));
        expect(retrieved.linkedTransactionId, equals(transaction.linkedTransactionId));

        // Property 4: Date should be preserved (within millisecond precision)
        expect(
          retrieved.date.difference(transaction.date).inMilliseconds.abs(),
          lessThan(1000),
        );

        return true;
      },
      iterations: 100,
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 9: Multiple transactions for same wallet should all be retrievable',
      generator: () {
        final walletId = const Uuid().v4();
        final transactionCount = PropertyTest.randomInt(min: 1, max: 10);
        final types = [
          KmhTransactionType.withdrawal,
          KmhTransactionType.deposit,
          KmhTransactionType.interest,
          KmhTransactionType.fee,
          KmhTransactionType.transfer,
        ];
        
        final transactions = List.generate(transactionCount, (index) {
          return {
            'id': const Uuid().v4(),
            'walletId': walletId,
            'type': types[PropertyTest.randomInt(min: 0, max: types.length - 1)],
            'amount': PropertyTest.randomPositiveDouble(min: 0.01, max: 100000),
            'date': PropertyTest.randomDateTime(),
            'description': PropertyTest.randomString(minLength: 5, maxLength: 100),
            'balanceAfter': PropertyTest.randomDouble(min: -100000, max: 100000),
          };
        });
        
        return {
          'walletId': walletId,
          'transactions': transactions,
        };
      },
      property: (data) async {
        final walletId = data['walletId'] as String;
        final transactionsData = data['transactions'] as List<Map<String, dynamic>>;

        // Save all transactions
        for (var txData in transactionsData) {
          final transaction = KmhTransaction(
            id: txData['id'],
            walletId: txData['walletId'],
            type: txData['type'],
            amount: txData['amount'],
            date: txData['date'],
            description: txData['description'],
            balanceAfter: txData['balanceAfter'],
          );
          await repository.addTransaction(transaction);
        }

        // Retrieve all transactions for the wallet
        final retrieved = await repository.getTransactions(walletId);

        // Property 1: All transactions should be retrieved
        expect(retrieved.length, equals(transactionsData.length));

        // Property 2: Each transaction should have correct data
        for (var txData in transactionsData) {
          final found = retrieved.firstWhere((t) => t.id == txData['id']);
          expect(found.walletId, equals(txData['walletId']));
          expect(found.type, equals(txData['type']));
          expect(found.amount, equals(txData['amount']));
          expect(found.description, equals(txData['description']));
          expect(found.balanceAfter, equals(txData['balanceAfter']));
        }

        return true;
      },
      iterations: 100,
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 9: Transaction update should preserve all fields',
      generator: () {
        final types = [
          KmhTransactionType.withdrawal,
          KmhTransactionType.deposit,
          KmhTransactionType.interest,
          KmhTransactionType.fee,
          KmhTransactionType.transfer,
        ];
        
        return {
          'id': const Uuid().v4(),
          'walletId': const Uuid().v4(),
          'type': types[PropertyTest.randomInt(min: 0, max: types.length - 1)],
          'amount': PropertyTest.randomPositiveDouble(min: 0.01, max: 100000),
          'date': PropertyTest.randomDateTime(),
          'description': PropertyTest.randomString(minLength: 5, maxLength: 100),
          'balanceAfter': PropertyTest.randomDouble(min: -100000, max: 100000),
          'newDescription': PropertyTest.randomString(minLength: 5, maxLength: 100),
          'newBalanceAfter': PropertyTest.randomDouble(min: -100000, max: 100000),
        };
      },
      property: (data) async {
        // Create and save initial transaction
        final transaction = KmhTransaction(
          id: data['id'],
          walletId: data['walletId'],
          type: data['type'],
          amount: data['amount'],
          date: data['date'],
          description: data['description'],
          balanceAfter: data['balanceAfter'],
        );
        await repository.addTransaction(transaction);

        // Update the transaction
        final updated = transaction.copyWith(
          description: data['newDescription'],
          balanceAfter: data['newBalanceAfter'],
        );
        await repository.update(updated);

        // Retrieve the updated transaction
        final retrieved = await repository.findById(transaction.id);

        // Property 1: Updated fields should have new values
        expect(retrieved!.description, equals(data['newDescription']));
        expect(retrieved.balanceAfter, equals(data['newBalanceAfter']));

        // Property 2: Other fields should remain unchanged
        expect(retrieved.id, equals(transaction.id));
        expect(retrieved.walletId, equals(transaction.walletId));
        expect(retrieved.type, equals(transaction.type));
        expect(retrieved.amount, equals(transaction.amount));

        return true;
      },
      iterations: 100,
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 9: Interest transactions should preserve interestAmount',
      generator: () {
        return {
          'id': const Uuid().v4(),
          'walletId': const Uuid().v4(),
          'amount': PropertyTest.randomPositiveDouble(min: 0.01, max: 1000),
          'date': PropertyTest.randomDateTime(),
          'description': 'Faiz tahakkuku',
          'balanceAfter': PropertyTest.randomDouble(min: -100000, max: 100000),
          'interestAmount': PropertyTest.randomPositiveDouble(min: 0.01, max: 1000),
        };
      },
      property: (data) async {
        // Create an interest transaction
        final transaction = KmhTransaction(
          id: data['id'],
          walletId: data['walletId'],
          type: KmhTransactionType.interest,
          amount: data['amount'],
          date: data['date'],
          description: data['description'],
          balanceAfter: data['balanceAfter'],
          interestAmount: data['interestAmount'],
        );

        // Save the transaction
        await repository.addTransaction(transaction);

        // Read it back
        final retrieved = await repository.findById(transaction.id);

        // Property 1: Interest amount should be preserved
        expect(retrieved!.interestAmount, equals(transaction.interestAmount));
        expect(retrieved.interestAmount, isNotNull);

        // Property 2: Type should be interest
        expect(retrieved.type, equals(KmhTransactionType.interest));

        return true;
      },
      iterations: 100,
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 9: Linked transactions should preserve linkedTransactionId',
      generator: () {
        final types = [
          KmhTransactionType.withdrawal,
          KmhTransactionType.deposit,
          KmhTransactionType.transfer,
        ];
        
        return {
          'id': const Uuid().v4(),
          'walletId': const Uuid().v4(),
          'type': types[PropertyTest.randomInt(min: 0, max: types.length - 1)],
          'amount': PropertyTest.randomPositiveDouble(min: 0.01, max: 100000),
          'date': PropertyTest.randomDateTime(),
          'description': PropertyTest.randomString(minLength: 5, maxLength: 100),
          'balanceAfter': PropertyTest.randomDouble(min: -100000, max: 100000),
          'linkedTransactionId': const Uuid().v4(),
        };
      },
      property: (data) async {
        // Create a transaction with linked transaction ID
        final transaction = KmhTransaction(
          id: data['id'],
          walletId: data['walletId'],
          type: data['type'],
          amount: data['amount'],
          date: data['date'],
          description: data['description'],
          balanceAfter: data['balanceAfter'],
          linkedTransactionId: data['linkedTransactionId'],
        );

        // Save the transaction
        await repository.addTransaction(transaction);

        // Read it back
        final retrieved = await repository.findById(transaction.id);

        // Property 1: Linked transaction ID should be preserved
        expect(retrieved!.linkedTransactionId, equals(transaction.linkedTransactionId));
        expect(retrieved.linkedTransactionId, isNotNull);

        return true;
      },
      iterations: 100,
    );
  });

  group('KMH Repository Cascade Delete Property Tests', () {
    late KmhRepository repository;
    late Directory testDir;

    setUpAll(() async {
      // Create a temporary directory for testing
      testDir = await Directory.systemTemp.createTemp('kmh_cascade_test_');
      
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
      // Clear the box before each test
      await KmhBoxService.clearAll();
      repository = KmhRepository();
    });

    tearDownAll(() async {
      // Clean up
      await KmhBoxService.close();
      await Hive.close();
      if (await testDir.exists()) {
        await testDir.delete(recursive: true);
      }
    });

    /// **Feature: kmh-account-management, Property 5: Cascade Delete**
    /// **Validates: Requirements 1.5**
    /// 
    /// Property: For any KMH account deleted, all transactions belonging to 
    /// that account should also be deleted.
    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 5: Cascade delete - all wallet transactions deleted when wallet is deleted',
      generator: () {
        final walletId = const Uuid().v4();
        final transactionCount = PropertyTest.randomInt(min: 1, max: 20);
        final types = [
          KmhTransactionType.withdrawal,
          KmhTransactionType.deposit,
          KmhTransactionType.interest,
          KmhTransactionType.fee,
          KmhTransactionType.transfer,
        ];
        
        final transactions = List.generate(transactionCount, (index) {
          return {
            'id': const Uuid().v4(),
            'walletId': walletId,
            'type': types[PropertyTest.randomInt(min: 0, max: types.length - 1)],
            'amount': PropertyTest.randomPositiveDouble(min: 0.01, max: 100000),
            'date': PropertyTest.randomDateTime(),
            'description': PropertyTest.randomString(minLength: 5, maxLength: 100),
            'balanceAfter': PropertyTest.randomDouble(min: -100000, max: 100000),
          };
        });
        
        return {
          'walletId': walletId,
          'transactions': transactions,
        };
      },
      property: (data) async {
        final walletId = data['walletId'] as String;
        final transactionsData = data['transactions'] as List<Map<String, dynamic>>;

        // Save all transactions for the wallet
        for (var txData in transactionsData) {
          final transaction = KmhTransaction(
            id: txData['id'],
            walletId: txData['walletId'],
            type: txData['type'],
            amount: txData['amount'],
            date: txData['date'],
            description: txData['description'],
            balanceAfter: txData['balanceAfter'],
          );
          await repository.addTransaction(transaction);
        }

        // Verify all transactions were saved
        final beforeDelete = await repository.getTransactions(walletId);
        expect(beforeDelete.length, equals(transactionsData.length));

        // Delete all transactions for the wallet (cascade delete)
        await repository.deleteTransactionsByWallet(walletId);

        // Property 1: All transactions for the wallet should be deleted
        final afterDelete = await repository.getTransactions(walletId);
        expect(afterDelete.length, equals(0));

        // Property 2: Each individual transaction should not be findable
        for (var txData in transactionsData) {
          final found = await repository.findById(txData['id']);
          expect(found, isNull);
        }

        // Property 3: Transaction count for wallet should be zero
        final count = await repository.countByWalletId(walletId);
        expect(count, equals(0));

        return true;
      },
      iterations: 100,
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 5: Cascade delete - only target wallet transactions deleted, others preserved',
      generator: () {
        final targetWalletId = const Uuid().v4();
        final otherWalletId = const Uuid().v4();
        final targetTransactionCount = PropertyTest.randomInt(min: 1, max: 10);
        final otherTransactionCount = PropertyTest.randomInt(min: 1, max: 10);
        final types = [
          KmhTransactionType.withdrawal,
          KmhTransactionType.deposit,
          KmhTransactionType.interest,
          KmhTransactionType.fee,
          KmhTransactionType.transfer,
        ];
        
        final targetTransactions = List.generate(targetTransactionCount, (index) {
          return {
            'id': const Uuid().v4(),
            'walletId': targetWalletId,
            'type': types[PropertyTest.randomInt(min: 0, max: types.length - 1)],
            'amount': PropertyTest.randomPositiveDouble(min: 0.01, max: 100000),
            'date': PropertyTest.randomDateTime(),
            'description': PropertyTest.randomString(minLength: 5, maxLength: 100),
            'balanceAfter': PropertyTest.randomDouble(min: -100000, max: 100000),
          };
        });

        final otherTransactions = List.generate(otherTransactionCount, (index) {
          return {
            'id': const Uuid().v4(),
            'walletId': otherWalletId,
            'type': types[PropertyTest.randomInt(min: 0, max: types.length - 1)],
            'amount': PropertyTest.randomPositiveDouble(min: 0.01, max: 100000),
            'date': PropertyTest.randomDateTime(),
            'description': PropertyTest.randomString(minLength: 5, maxLength: 100),
            'balanceAfter': PropertyTest.randomDouble(min: -100000, max: 100000),
          };
        });
        
        return {
          'targetWalletId': targetWalletId,
          'otherWalletId': otherWalletId,
          'targetTransactions': targetTransactions,
          'otherTransactions': otherTransactions,
        };
      },
      property: (data) async {
        final targetWalletId = data['targetWalletId'] as String;
        final otherWalletId = data['otherWalletId'] as String;
        final targetTransactionsData = data['targetTransactions'] as List<Map<String, dynamic>>;
        final otherTransactionsData = data['otherTransactions'] as List<Map<String, dynamic>>;

        // Save all transactions for both wallets
        for (var txData in targetTransactionsData) {
          final transaction = KmhTransaction(
            id: txData['id'],
            walletId: txData['walletId'],
            type: txData['type'],
            amount: txData['amount'],
            date: txData['date'],
            description: txData['description'],
            balanceAfter: txData['balanceAfter'],
          );
          await repository.addTransaction(transaction);
        }

        for (var txData in otherTransactionsData) {
          final transaction = KmhTransaction(
            id: txData['id'],
            walletId: txData['walletId'],
            type: txData['type'],
            amount: txData['amount'],
            date: txData['date'],
            description: txData['description'],
            balanceAfter: txData['balanceAfter'],
          );
          await repository.addTransaction(transaction);
        }

        // Verify all transactions were saved
        final targetBefore = await repository.getTransactions(targetWalletId);
        final otherBefore = await repository.getTransactions(otherWalletId);
        expect(targetBefore.length, equals(targetTransactionsData.length));
        expect(otherBefore.length, equals(otherTransactionsData.length));

        // Delete transactions for target wallet only
        await repository.deleteTransactionsByWallet(targetWalletId);

        // Property 1: Target wallet transactions should be deleted
        final targetAfter = await repository.getTransactions(targetWalletId);
        expect(targetAfter.length, equals(0));

        // Property 2: Other wallet transactions should be preserved
        final otherAfter = await repository.getTransactions(otherWalletId);
        expect(otherAfter.length, equals(otherTransactionsData.length));

        // Property 3: Each other wallet transaction should still be findable
        for (var txData in otherTransactionsData) {
          final found = await repository.findById(txData['id']);
          expect(found, isNotNull);
          expect(found!.walletId, equals(otherWalletId));
        }

        // Property 4: Target wallet transaction count should be zero
        final targetCount = await repository.countByWalletId(targetWalletId);
        expect(targetCount, equals(0));

        // Property 5: Other wallet transaction count should be unchanged
        final otherCount = await repository.countByWalletId(otherWalletId);
        expect(otherCount, equals(otherTransactionsData.length));

        return true;
      },
      iterations: 100,
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 5: Cascade delete - deleting empty wallet has no side effects',
      generator: () {
        return {
          'walletId': const Uuid().v4(),
        };
      },
      property: (data) async {
        final walletId = data['walletId'] as String;

        // Verify wallet has no transactions
        final beforeDelete = await repository.getTransactions(walletId);
        expect(beforeDelete.length, equals(0));

        // Delete transactions for wallet (should be a no-op)
        await repository.deleteTransactionsByWallet(walletId);

        // Property 1: Still no transactions for the wallet
        final afterDelete = await repository.getTransactions(walletId);
        expect(afterDelete.length, equals(0));

        // Property 2: Transaction count should still be zero
        final count = await repository.countByWalletId(walletId);
        expect(count, equals(0));

        return true;
      },
      iterations: 100,
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 5: Cascade delete - idempotency (deleting twice has same effect as once)',
      generator: () {
        final walletId = const Uuid().v4();
        final transactionCount = PropertyTest.randomInt(min: 1, max: 15);
        final types = [
          KmhTransactionType.withdrawal,
          KmhTransactionType.deposit,
          KmhTransactionType.interest,
          KmhTransactionType.fee,
          KmhTransactionType.transfer,
        ];
        
        final transactions = List.generate(transactionCount, (index) {
          return {
            'id': const Uuid().v4(),
            'walletId': walletId,
            'type': types[PropertyTest.randomInt(min: 0, max: types.length - 1)],
            'amount': PropertyTest.randomPositiveDouble(min: 0.01, max: 100000),
            'date': PropertyTest.randomDateTime(),
            'description': PropertyTest.randomString(minLength: 5, maxLength: 100),
            'balanceAfter': PropertyTest.randomDouble(min: -100000, max: 100000),
          };
        });
        
        return {
          'walletId': walletId,
          'transactions': transactions,
        };
      },
      property: (data) async {
        final walletId = data['walletId'] as String;
        final transactionsData = data['transactions'] as List<Map<String, dynamic>>;

        // Save all transactions for the wallet
        for (var txData in transactionsData) {
          final transaction = KmhTransaction(
            id: txData['id'],
            walletId: txData['walletId'],
            type: txData['type'],
            amount: txData['amount'],
            date: txData['date'],
            description: txData['description'],
            balanceAfter: txData['balanceAfter'],
          );
          await repository.addTransaction(transaction);
        }

        // Delete transactions for the wallet (first time)
        await repository.deleteTransactionsByWallet(walletId);

        // Verify deletion
        final afterFirstDelete = await repository.getTransactions(walletId);
        expect(afterFirstDelete.length, equals(0));

        // Delete transactions for the wallet again (second time - idempotency test)
        await repository.deleteTransactionsByWallet(walletId);

        // Property 1: Still no transactions (idempotent)
        final afterSecondDelete = await repository.getTransactions(walletId);
        expect(afterSecondDelete.length, equals(0));

        // Property 2: Transaction count should still be zero
        final count = await repository.countByWalletId(walletId);
        expect(count, equals(0));

        return true;
      },
      iterations: 100,
    );
  });
}
