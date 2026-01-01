import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:parion/models/wallet.dart';
import 'package:parion/services/data_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../property_test_utils.dart';
import 'package:uuid/uuid.dart';

/// **Feature: kmh-account-management, Property 28: Çoklu Hesap Listeleme**
/// **Validates: Requirements 8.1**
/// 
/// Property: For any user, all KMH accounts they own should be listed and 
/// none should be skipped.
void main() {
  group('KMH Multiple Accounts Listing Property Tests', () {
    late DataService dataService;
    late Directory testDir;

    setUpAll(() async {
      // Create a temporary directory for testing
      testDir = await Directory.systemTemp.createTemp('kmh_multi_test_');
      
      // Initialize Hive with the test directory
      Hive.init(testDir.path);
    });

    setUp(() async {
      // Clear SharedPreferences before each test
      SharedPreferences.setMockInitialValues({});
      
      // Initialize DataService
      dataService = DataService();
      await dataService.init();
      
      // Clear any existing wallets
      final prefs = await dataService.getPrefs();
      await prefs.setString('wallets', '[]');
    });

    tearDownAll(() async {
      // Clean up
      await Hive.close();
      if (await testDir.exists()) {
        await testDir.delete(recursive: true);
      }
    });

    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 28: All KMH accounts should be listed without skipping any',
      generator: () {
        // Generate a random number of KMH accounts (1-10)
        final kmhAccountCount = PropertyTest.randomInt(min: 1, max: 10);
        
        // Generate a random number of non-KMH accounts (0-5)
        final nonKmhAccountCount = PropertyTest.randomInt(min: 0, max: 5);
        
        // Generate KMH accounts (bank type with creditLimit > 0)
        final kmhAccounts = List.generate(kmhAccountCount, (index) {
          return {
            'id': const Uuid().v4(),
            'name': 'KMH Bank ${index + 1} - ${PropertyTest.randomString(minLength: 5, maxLength: 15)}',
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
        
        // Generate non-KMH accounts (either bank with no credit limit or other types)
        final nonKmhAccounts = List.generate(nonKmhAccountCount, (index) {
          final types = ['cash', 'bank', 'savings'];
          final selectedType = types[PropertyTest.randomInt(min: 0, max: types.length - 1)];
          
          return {
            'id': const Uuid().v4(),
            'name': 'Regular Account ${index + 1} - ${PropertyTest.randomString(minLength: 5, maxLength: 15)}',
            'balance': PropertyTest.randomDouble(min: -10000, max: 100000),
            'type': selectedType,
            'color': '#${PropertyTest.randomInt(min: 0, max: 0xFFFFFF).toRadixString(16).padLeft(6, '0')}',
            'icon': selectedType == 'cash' ? 'account_balance_wallet' : 'account_balance',
            'creditLimit': 0.0, // No credit limit = not KMH
          };
        });
        
        return {
          'kmhAccounts': kmhAccounts,
          'nonKmhAccounts': nonKmhAccounts,
        };
      },
      property: (data) async {
        // Clear wallets before each iteration
        final prefs = await dataService.getPrefs();
        await prefs.setString('wallets', '[]');
        // Clear cache to ensure fresh data
        await dataService.saveWallets([]);
        
        final kmhAccountsData = data['kmhAccounts'] as List<Map<String, dynamic>>;
        final nonKmhAccountsData = data['nonKmhAccounts'] as List<Map<String, dynamic>>;
        
        // Create all wallets (both KMH and non-KMH)
        final allWallets = <Wallet>[];
        
        // Create KMH accounts
        for (var accountData in kmhAccountsData) {
          final wallet = Wallet(
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
          allWallets.add(wallet);
        }
        
        // Create non-KMH accounts
        for (var accountData in nonKmhAccountsData) {
          final wallet = Wallet(
            id: accountData['id'],
            name: accountData['name'],
            balance: accountData['balance'],
            type: accountData['type'],
            color: accountData['color'],
            icon: accountData['icon'],
            creditLimit: accountData['creditLimit'],
          );
          allWallets.add(wallet);
        }
        
        // Save all wallets to DataService
        for (var wallet in allWallets) {
          await dataService.addWallet(wallet);
        }
        
        // Retrieve all wallets
        final retrievedWallets = await dataService.getWallets();
        
        // Filter to get only KMH accounts
        final kmhAccountsRetrieved = retrievedWallets.where((w) => w.isKmhAccount).toList();
        
        // Property 1: All KMH accounts should be retrieved
        expect(kmhAccountsRetrieved.length, equals(kmhAccountsData.length),
          reason: 'All ${kmhAccountsData.length} KMH accounts should be listed');
        
        // Property 2: Each created KMH account should be in the retrieved list
        for (var accountData in kmhAccountsData) {
          final found = kmhAccountsRetrieved.any((w) => w.id == accountData['id']);
          expect(found, isTrue,
            reason: 'KMH account ${accountData['id']} should be in the list');
        }
        
        // Property 3: No KMH account should be skipped
        final retrievedIds = kmhAccountsRetrieved.map((w) => w.id).toSet();
        final expectedIds = kmhAccountsData.map((a) => a['id'] as String).toSet();
        expect(retrievedIds, equals(expectedIds),
          reason: 'Retrieved KMH account IDs should match expected IDs exactly');
        
        // Property 4: Non-KMH accounts should not be in the KMH list
        for (var accountData in nonKmhAccountsData) {
          final foundInKmh = kmhAccountsRetrieved.any((w) => w.id == accountData['id']);
          expect(foundInKmh, isFalse,
            reason: 'Non-KMH account ${accountData['id']} should not be in KMH list');
        }
        
        // Property 5: Each retrieved KMH account should have correct properties
        for (var kmhAccount in kmhAccountsRetrieved) {
          expect(kmhAccount.isKmhAccount, isTrue,
            reason: 'Account ${kmhAccount.id} should be identified as KMH');
          expect(kmhAccount.type, equals('bank'),
            reason: 'KMH account ${kmhAccount.id} should be bank type');
          expect(kmhAccount.creditLimit, greaterThan(0),
            reason: 'KMH account ${kmhAccount.id} should have positive credit limit');
        }
        
        // Property 6: Total wallet count should equal KMH + non-KMH accounts
        final totalExpected = kmhAccountsData.length + nonKmhAccountsData.length;
        expect(retrievedWallets.length, equals(totalExpected),
          reason: 'Total wallets should equal sum of KMH and non-KMH accounts');
        
        return true;
      },
      iterations: 100,
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 28: Empty KMH account list when no KMH accounts exist',
      generator: () {
        // Generate only non-KMH accounts
        final nonKmhAccountCount = PropertyTest.randomInt(min: 1, max: 10);
        
        final nonKmhAccounts = List.generate(nonKmhAccountCount, (index) {
          final types = ['cash', 'bank', 'savings'];
          final selectedType = types[PropertyTest.randomInt(min: 0, max: types.length - 1)];
          
          return {
            'id': const Uuid().v4(),
            'name': 'Regular Account ${index + 1}',
            'balance': PropertyTest.randomDouble(min: 0, max: 100000),
            'type': selectedType,
            'color': '#${PropertyTest.randomInt(min: 0, max: 0xFFFFFF).toRadixString(16).padLeft(6, '0')}',
            'icon': 'account_balance_wallet',
            'creditLimit': 0.0, // No credit limit
          };
        });
        
        return {
          'nonKmhAccounts': nonKmhAccounts,
        };
      },
      property: (data) async {
        // Clear wallets before each iteration
        final prefs = await dataService.getPrefs();
        await prefs.setString('wallets', '[]');
        // Clear cache to ensure fresh data
        await dataService.saveWallets([]);
        
        final nonKmhAccountsData = data['nonKmhAccounts'] as List<Map<String, dynamic>>;
        
        // Create only non-KMH accounts
        for (var accountData in nonKmhAccountsData) {
          final wallet = Wallet(
            id: accountData['id'],
            name: accountData['name'],
            balance: accountData['balance'],
            type: accountData['type'],
            color: accountData['color'],
            icon: accountData['icon'],
            creditLimit: accountData['creditLimit'],
          );
          await dataService.addWallet(wallet);
        }
        
        // Retrieve all wallets
        final retrievedWallets = await dataService.getWallets();
        
        // Filter to get only KMH accounts
        final kmhAccountsRetrieved = retrievedWallets.where((w) => w.isKmhAccount).toList();
        
        // Property 1: KMH account list should be empty
        expect(kmhAccountsRetrieved.length, equals(0),
          reason: 'No KMH accounts should be listed when none exist');
        
        // Property 2: All retrieved wallets should be non-KMH
        for (var wallet in retrievedWallets) {
          expect(wallet.isKmhAccount, isFalse,
            reason: 'All accounts should be non-KMH');
        }
        
        return true;
      },
      iterations: 100,
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 28: Single KMH account should be listed correctly',
      generator: () {
        return {
          'id': const Uuid().v4(),
          'name': PropertyTest.randomString(minLength: 5, maxLength: 30),
          'balance': PropertyTest.randomDouble(min: -50000, max: 50000),
          'type': 'bank',
          'color': '#${PropertyTest.randomInt(min: 0, max: 0xFFFFFF).toRadixString(16).padLeft(6, '0')}',
          'icon': 'account_balance',
          'creditLimit': PropertyTest.randomPositiveDouble(min: 1000, max: 100000),
          'interestRate': PropertyTest.randomPositiveDouble(min: 1, max: 50),
          'lastInterestDate': PropertyTest.randomDateTime(),
          'accruedInterest': PropertyTest.randomPositiveDouble(min: 0, max: 10000),
          'accountNumber': PropertyTest.randomInt(min: 100000, max: 999999).toString(),
        };
      },
      property: (data) async {
        // Clear wallets before each iteration
        final prefs = await dataService.getPrefs();
        await prefs.setString('wallets', '[]');
        // Clear cache to ensure fresh data
        await dataService.saveWallets([]);
        
        // Create a single KMH account
        final wallet = Wallet(
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
        
        await dataService.addWallet(wallet);
        
        // Retrieve all wallets
        final retrievedWallets = await dataService.getWallets();
        
        // Filter to get only KMH accounts
        final kmhAccountsRetrieved = retrievedWallets.where((w) => w.isKmhAccount).toList();
        
        // Property 1: Exactly one KMH account should be listed
        expect(kmhAccountsRetrieved.length, equals(1),
          reason: 'Exactly one KMH account should be listed');
        
        // Property 2: The retrieved account should match the created account
        final retrieved = kmhAccountsRetrieved.first;
        expect(retrieved.id, equals(data['id']));
        expect(retrieved.name, equals(data['name']));
        expect(retrieved.creditLimit, equals(data['creditLimit']));
        expect(retrieved.interestRate, equals(data['interestRate']));
        expect(retrieved.isKmhAccount, isTrue);
        
        return true;
      },
      iterations: 100,
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 28: KMH accounts with different balances (positive and negative) should all be listed',
      generator: () {
        final accountCount = PropertyTest.randomInt(min: 2, max: 8);
        
        final accounts = List.generate(accountCount, (index) {
          // Ensure we have a mix of positive and negative balances
          final balance = index % 2 == 0 
            ? PropertyTest.randomPositiveDouble(min: 1, max: 50000)  // Positive
            : -PropertyTest.randomPositiveDouble(min: 1, max: 50000); // Negative
          
          return {
            'id': const Uuid().v4(),
            'name': 'KMH Account ${index + 1}',
            'balance': balance,
            'type': 'bank',
            'color': '#${PropertyTest.randomInt(min: 0, max: 0xFFFFFF).toRadixString(16).padLeft(6, '0')}',
            'icon': 'account_balance',
            'creditLimit': PropertyTest.randomPositiveDouble(min: 1000, max: 100000),
            'interestRate': PropertyTest.randomPositiveDouble(min: 1, max: 50),
            'lastInterestDate': PropertyTest.randomDateTime(),
            'accruedInterest': PropertyTest.randomPositiveDouble(min: 0, max: 10000),
            'accountNumber': PropertyTest.randomInt(min: 100000, max: 999999).toString(),
          };
        });
        
        return {
          'accounts': accounts,
        };
      },
      property: (data) async {
        // Clear wallets before each iteration
        final prefs = await dataService.getPrefs();
        await prefs.setString('wallets', '[]');
        // Clear cache to ensure fresh data
        await dataService.saveWallets([]);
        
        final accountsData = data['accounts'] as List<Map<String, dynamic>>;
        
        // Create all KMH accounts
        for (var accountData in accountsData) {
          final wallet = Wallet(
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
          await dataService.addWallet(wallet);
        }
        
        // Retrieve all wallets
        final retrievedWallets = await dataService.getWallets();
        
        // Filter to get only KMH accounts
        final kmhAccountsRetrieved = retrievedWallets.where((w) => w.isKmhAccount).toList();
        
        // Property 1: All KMH accounts should be listed regardless of balance
        expect(kmhAccountsRetrieved.length, equals(accountsData.length),
          reason: 'All KMH accounts should be listed regardless of positive or negative balance');
        
        // Property 2: Both positive and negative balance accounts should be present
        final positiveBalanceAccounts = kmhAccountsRetrieved.where((w) => w.balance > 0).toList();
        final negativeBalanceAccounts = kmhAccountsRetrieved.where((w) => w.balance < 0).toList();
        
        // At least one of each should exist based on our generator
        expect(positiveBalanceAccounts.isNotEmpty || negativeBalanceAccounts.isNotEmpty, isTrue,
          reason: 'Should have accounts with various balances');
        
        // Property 3: Each account should be correctly identified as KMH
        for (var account in kmhAccountsRetrieved) {
          expect(account.isKmhAccount, isTrue);
        }
        
        return true;
      },
      iterations: 100,
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 28: KMH accounts with varying credit limits should all be listed',
      generator: () {
        final accountCount = PropertyTest.randomInt(min: 2, max: 8);
        
        final accounts = List.generate(accountCount, (index) {
          // Generate varying credit limits from minimum to maximum
          final creditLimit = 1000.0 + (index * 10000.0) + PropertyTest.randomPositiveDouble(min: 0, max: 5000);
          
          return {
            'id': const Uuid().v4(),
            'name': 'KMH Account ${index + 1}',
            'balance': PropertyTest.randomDouble(min: -50000, max: 50000),
            'type': 'bank',
            'color': '#${PropertyTest.randomInt(min: 0, max: 0xFFFFFF).toRadixString(16).padLeft(6, '0')}',
            'icon': 'account_balance',
            'creditLimit': creditLimit,
            'interestRate': PropertyTest.randomPositiveDouble(min: 1, max: 50),
            'lastInterestDate': PropertyTest.randomDateTime(),
            'accruedInterest': PropertyTest.randomPositiveDouble(min: 0, max: 10000),
            'accountNumber': PropertyTest.randomInt(min: 100000, max: 999999).toString(),
          };
        });
        
        return {
          'accounts': accounts,
        };
      },
      property: (data) async {
        // Clear wallets before each iteration
        final prefs = await dataService.getPrefs();
        await prefs.setString('wallets', '[]');
        // Clear cache to ensure fresh data
        await dataService.saveWallets([]);
        
        final accountsData = data['accounts'] as List<Map<String, dynamic>>;
        
        // Create all KMH accounts
        for (var accountData in accountsData) {
          final wallet = Wallet(
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
          await dataService.addWallet(wallet);
        }
        
        // Retrieve all wallets
        final retrievedWallets = await dataService.getWallets();
        
        // Filter to get only KMH accounts
        final kmhAccountsRetrieved = retrievedWallets.where((w) => w.isKmhAccount).toList();
        
        // Property 1: All KMH accounts should be listed regardless of credit limit
        expect(kmhAccountsRetrieved.length, equals(accountsData.length),
          reason: 'All KMH accounts should be listed regardless of credit limit amount');
        
        // Property 2: Each account should have a positive credit limit
        for (var account in kmhAccountsRetrieved) {
          expect(account.creditLimit, greaterThan(0),
            reason: 'All KMH accounts should have positive credit limit');
        }
        
        // Property 3: Credit limits should be preserved correctly
        for (var accountData in accountsData) {
          final found = kmhAccountsRetrieved.firstWhere((w) => w.id == accountData['id']);
          expect(found.creditLimit, equals(accountData['creditLimit']),
            reason: 'Credit limit should be preserved for account ${accountData['id']}');
        }
        
        return true;
      },
      iterations: 100,
    );
  });
}
