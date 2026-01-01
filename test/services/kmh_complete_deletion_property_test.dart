import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:parion/models/wallet.dart';
import 'package:parion/models/kmh_transaction.dart';
import 'package:parion/models/kmh_transaction_type.dart';
import 'package:parion/services/data_service.dart';
import 'package:parion/services/kmh_box_service.dart';
import 'package:parion/repositories/kmh_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../property_test_utils.dart';
import 'package:uuid/uuid.dart';

/// **Feature: kmh-account-management, Property 35: Tam Veri Silme**
/// **Validates: Requirements 9.5**
/// 
/// Property: For any data deletion operation, all KMH accounts and transactions 
/// must be completely deleted.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('KMH Complete Deletion Property Tests', () {
    late DataService dataService;
    late KmhRepository kmhRepository;
    late Directory tempDir;

    setUpAll(() async {
      // Create a temporary directory for testing
      tempDir = await Directory.systemTemp.createTemp('kmh_deletion_test_');
      
      // Initialize Hive with the test directory
      Hive.init(tempDir.path);
      
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
      
      // Initialize services
      SharedPreferences.setMockInitialValues({});
      dataService = DataService();
      await dataService.init();
      kmhRepository = KmhRepository();
    });

    tearDownAll(() async {
      // Clean up
      await KmhBoxService.close();
      await Hive.close();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 35: Complete data deletion removes all KMH accounts',
      generator: () {
        // Generate random KMH accounts
        final numAccounts = PropertyTest.randomInt(min: 1, max: 5);
        final accounts = List.generate(numAccounts, (index) {
          return {
            'id': const Uuid().v4(),
            'name': 'Bank ${PropertyTest.randomString(minLength: 5, maxLength: 15)}',
            'balance': PropertyTest.randomDouble(min: -50000, max: 50000),
            'type': 'bank',
            'color': '#${PropertyTest.randomInt(min: 0, max: 0xFFFFFF).toRadixString(16).padLeft(6, '0')}',
            'icon': 'account_balance',
            'creditLimit': PropertyTest.randomPositiveDouble(min: 1000, max: 100000),
            'interestRate': PropertyTest.randomPositiveDouble(min: 1, max: 50),
            'lastInterestDate': PropertyTest.randomDateTime(),
            'accruedInterest': PropertyTest.randomPositiveDouble(min: 0, max: 10000),
            'accountNumber': PropertyTest.randomInt(min: 100000, max: 999999).toString() + 
                             PropertyTest.randomInt(min: 1000, max: 9999).toString(),
          };
        });

        return {'accounts': accounts};
      },
      property: (data) async {
        // Create KMH accounts
        final accounts = (data['accounts'] as List).map((accountData) {
          return Wallet(
            id: accountData['id'],
            name: accountData['name'],
            balance: accountData['balance'],
            type: accountData['type'],
            color: accountData['color'],
            icon: accountData['icon'],
            creditLimit: accountData['creditLimit'],
            interestRate: accountData['interestRate'],
            lastInterestDate: accountData['lastInterestDate'],
            accruedInterest: accountData['accruedInterest'],
            accountNumber: accountData['accountNumber'],
          );
        }).toList();

        // Save accounts
        await dataService.saveWallets(accounts);

        // Verify accounts are saved
        final savedWallets = await dataService.getWallets();
        final savedKmhAccounts = savedWallets.where((w) => w.isKmhAccount).toList();
        expect(savedKmhAccounts.length, equals(accounts.length));

        // Clear all data
        // Validates: Requirements 9.5
        await dataService.clearAllData();
        await dataService.init();

        // Verify all KMH accounts are deleted
        final walletsAfterDeletion = await dataService.getWallets();
        final kmhAccountsAfterDeletion = walletsAfterDeletion.where((w) => w.isKmhAccount).toList();
        
        // Property: All KMH accounts must be completely deleted
        expect(kmhAccountsAfterDeletion.isEmpty, isTrue,
            reason: 'All KMH accounts should be deleted after clearAllData');

        return true;
      },
      iterations: 100,
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 35: Complete data deletion removes all KMH transactions',
      generator: () {
        // Generate a KMH account
        final walletId = const Uuid().v4();
        
        // Generate random transactions for this account
        final numTransactions = PropertyTest.randomInt(min: 1, max: 10);
        final transactions = List.generate(numTransactions, (index) {
          final types = [
            KmhTransactionType.withdrawal,
            KmhTransactionType.deposit,
            KmhTransactionType.interest,
            KmhTransactionType.fee,
          ];
          
          return {
            'id': const Uuid().v4(),
            'walletId': walletId,
            'type': types[PropertyTest.randomInt(min: 0, max: types.length - 1)],
            'amount': PropertyTest.randomPositiveDouble(min: 1, max: 10000),
            'date': PropertyTest.randomDateTime(),
            'description': PropertyTest.randomString(minLength: 5, maxLength: 30),
            'balanceAfter': PropertyTest.randomDouble(min: -50000, max: 50000),
            'interestAmount': PropertyTest.randomBool() 
                ? PropertyTest.randomPositiveDouble(min: 1, max: 1000) 
                : null,
            'linkedTransactionId': PropertyTest.randomBool() 
                ? const Uuid().v4() 
                : null,
          };
        });

        return {
          'walletId': walletId,
          'transactions': transactions,
        };
      },
      property: (data) async {
        final walletId = data['walletId'] as String;
        
        // Create transactions
        final transactions = (data['transactions'] as List).map((txData) {
          return KmhTransaction(
            id: txData['id'],
            walletId: txData['walletId'],
            type: txData['type'],
            amount: txData['amount'],
            date: txData['date'],
            description: txData['description'],
            balanceAfter: txData['balanceAfter'],
            interestAmount: txData['interestAmount'],
            linkedTransactionId: txData['linkedTransactionId'],
          );
        }).toList();

        // Save transactions
        for (final transaction in transactions) {
          await kmhRepository.addTransaction(transaction);
        }

        // Verify transactions are saved
        final savedTransactions = await kmhRepository.getTransactions(walletId);
        expect(savedTransactions.length, equals(transactions.length));

        // Clear all data
        // Validates: Requirements 9.5
        await dataService.clearAllData();
        await dataService.init();
        kmhRepository = KmhRepository(); // Reinitialize after clear

        // Verify all KMH transactions are deleted
        final transactionsAfterDeletion = await kmhRepository.findAll();
        
        // Property: All KMH transactions must be completely deleted
        expect(transactionsAfterDeletion.isEmpty, isTrue,
            reason: 'All KMH transactions should be deleted after clearAllData');

        return true;
      },
      iterations: 100,
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 35: Complete data deletion removes all KMH data (accounts + transactions)',
      generator: () {
        // Generate KMH accounts
        final numAccounts = PropertyTest.randomInt(min: 1, max: 3);
        final accounts = List.generate(numAccounts, (index) {
          return {
            'id': const Uuid().v4(),
            'name': 'Bank ${PropertyTest.randomString(minLength: 5, maxLength: 15)}',
            'balance': PropertyTest.randomDouble(min: -50000, max: 50000),
            'type': 'bank',
            'color': '#${PropertyTest.randomInt(min: 0, max: 0xFFFFFF).toRadixString(16).padLeft(6, '0')}',
            'icon': 'account_balance',
            'creditLimit': PropertyTest.randomPositiveDouble(min: 1000, max: 100000),
            'interestRate': PropertyTest.randomPositiveDouble(min: 1, max: 50),
            'lastInterestDate': PropertyTest.randomDateTime(),
            'accruedInterest': PropertyTest.randomPositiveDouble(min: 0, max: 10000),
            'accountNumber': PropertyTest.randomInt(min: 100000, max: 999999).toString() + 
                             PropertyTest.randomInt(min: 1000, max: 9999).toString(),
          };
        });

        // Generate transactions for each account
        final allTransactions = <Map<String, dynamic>>[];
        for (final account in accounts) {
          final numTransactions = PropertyTest.randomInt(min: 1, max: 5);
          final types = [
            KmhTransactionType.withdrawal,
            KmhTransactionType.deposit,
            KmhTransactionType.interest,
          ];
          
          for (int i = 0; i < numTransactions; i++) {
            allTransactions.add({
              'id': const Uuid().v4(),
              'walletId': account['id'],
              'type': types[PropertyTest.randomInt(min: 0, max: types.length - 1)],
              'amount': PropertyTest.randomPositiveDouble(min: 1, max: 10000),
              'date': PropertyTest.randomDateTime(),
              'description': PropertyTest.randomString(minLength: 5, maxLength: 30),
              'balanceAfter': PropertyTest.randomDouble(min: -50000, max: 50000),
              'interestAmount': null,
              'linkedTransactionId': null,
            });
          }
        }

        return {
          'accounts': accounts,
          'transactions': allTransactions,
        };
      },
      property: (data) async {
        // Create KMH accounts
        final accounts = (data['accounts'] as List).map((accountData) {
          return Wallet(
            id: accountData['id'],
            name: accountData['name'],
            balance: accountData['balance'],
            type: accountData['type'],
            color: accountData['color'],
            icon: accountData['icon'],
            creditLimit: accountData['creditLimit'],
            interestRate: accountData['interestRate'],
            lastInterestDate: accountData['lastInterestDate'],
            accruedInterest: accountData['accruedInterest'],
            accountNumber: accountData['accountNumber'],
          );
        }).toList();

        // Create transactions
        final transactions = (data['transactions'] as List).map((txData) {
          return KmhTransaction(
            id: txData['id'],
            walletId: txData['walletId'],
            type: txData['type'],
            amount: txData['amount'],
            date: txData['date'],
            description: txData['description'],
            balanceAfter: txData['balanceAfter'],
            interestAmount: txData['interestAmount'],
            linkedTransactionId: txData['linkedTransactionId'],
          );
        }).toList();

        // Save all data
        await dataService.saveWallets(accounts);
        for (final transaction in transactions) {
          await kmhRepository.addTransaction(transaction);
        }

        // Verify data is saved
        final savedWallets = await dataService.getWallets();
        final savedKmhAccounts = savedWallets.where((w) => w.isKmhAccount).toList();
        final savedTransactions = await kmhRepository.findAll();
        expect(savedKmhAccounts.length, equals(accounts.length));
        expect(savedTransactions.length, equals(transactions.length));

        // Clear all data
        // Validates: Requirements 9.5
        await dataService.clearAllData();
        await dataService.init();
        kmhRepository = KmhRepository(); // Reinitialize

        // Verify all KMH data is deleted
        final walletsAfterDeletion = await dataService.getWallets();
        final kmhAccountsAfterDeletion = walletsAfterDeletion.where((w) => w.isKmhAccount).toList();
        final transactionsAfterDeletion = await kmhRepository.findAll();
        
        // Property 1: All KMH accounts must be completely deleted
        expect(kmhAccountsAfterDeletion.isEmpty, isTrue,
            reason: 'All KMH accounts should be deleted after clearAllData');
        
        // Property 2: All KMH transactions must be completely deleted
        expect(transactionsAfterDeletion.isEmpty, isTrue,
            reason: 'All KMH transactions should be deleted after clearAllData');

        // Property 3: Each account's transactions are deleted
        for (final account in accounts) {
          final accountTransactions = await kmhRepository.getTransactions(account.id);
          expect(accountTransactions.isEmpty, isTrue,
              reason: 'All transactions for account ${account.id} should be deleted');
        }

        return true;
      },
      iterations: 100,
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 35: Complete data deletion is idempotent',
      generator: () {
        // Generate a simple KMH account
        return {
          'id': const Uuid().v4(),
          'name': 'Bank ${PropertyTest.randomString(minLength: 5, maxLength: 15)}',
          'balance': PropertyTest.randomDouble(min: -50000, max: 50000),
          'type': 'bank',
          'color': '#${PropertyTest.randomInt(min: 0, max: 0xFFFFFF).toRadixString(16).padLeft(6, '0')}',
          'icon': 'account_balance',
          'creditLimit': PropertyTest.randomPositiveDouble(min: 1000, max: 100000),
          'interestRate': PropertyTest.randomPositiveDouble(min: 1, max: 50),
          'lastInterestDate': PropertyTest.randomDateTime(),
          'accruedInterest': PropertyTest.randomPositiveDouble(min: 0, max: 10000),
          'accountNumber': PropertyTest.randomInt(min: 100000, max: 999999).toString() + 
                           PropertyTest.randomInt(min: 1000, max: 9999).toString(),
        };
      },
      property: (data) async {
        // Create KMH account
        final account = Wallet(
          id: data['id'],
          name: data['name'],
          balance: data['balance'],
          type: data['type'],
          color: data['color'],
          icon: data['icon'],
          creditLimit: data['creditLimit'],
          interestRate: data['interestRate'],
          lastInterestDate: data['lastInterestDate'],
          accruedInterest: data['accruedInterest'],
          accountNumber: data['accountNumber'],
        );

        // Save account
        await dataService.saveWallets([account]);

        // Clear all data first time
        await dataService.clearAllData();
        await dataService.init();

        // Verify data is deleted
        final walletsAfterFirstDeletion = await dataService.getWallets();
        final kmhAccountsAfterFirstDeletion = walletsAfterFirstDeletion.where((w) => w.isKmhAccount).toList();
        expect(kmhAccountsAfterFirstDeletion.isEmpty, isTrue);

        // Clear all data second time (idempotency test)
        await dataService.clearAllData();
        await dataService.init();

        // Verify data is still deleted (no errors)
        final walletsAfterSecondDeletion = await dataService.getWallets();
        final kmhAccountsAfterSecondDeletion = walletsAfterSecondDeletion.where((w) => w.isKmhAccount).toList();
        
        // Property: Deletion is idempotent - calling it multiple times has the same effect
        expect(kmhAccountsAfterSecondDeletion.isEmpty, isTrue,
            reason: 'Deletion should be idempotent - multiple calls should not cause errors');

        return true;
      },
      iterations: 100,
    );
  });
}
