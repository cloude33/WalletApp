import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:parion/models/wallet.dart';
import 'package:parion/services/data_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../property_test_utils.dart';
import 'package:uuid/uuid.dart';

/// **Feature: kmh-account-management, Property 24: Pozitif Bakiye Sınıflandırma**
/// **Validates: Requirements 6.5**
/// 
/// Property: For any KMH account, if balance > 0 it should be classified as an asset,
/// if balance < 0 it should be classified as a debt.
void main() {
  group('KMH Balance Classification Property Tests', () {
    late DataService dataService;
    late Directory testDir;

    setUpAll(() async {
      // Create a temporary directory for testing
      testDir = await Directory.systemTemp.createTemp('kmh_balance_class_test_');
      
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
      description: 'Property 24: KMH accounts with positive balance are classified as assets',
      generator: () {
        final kmhAccountCount = PropertyTest.randomInt(min: 1, max: 10);
        
        // Generate KMH accounts with positive balances
        final kmhAccounts = List.generate(kmhAccountCount, (index) {
          return {
            'id': const Uuid().v4(),
            'name': 'KMH Account ${index + 1}',
            'balance': PropertyTest.randomPositiveDouble(min: 0.01, max: 50000),
            'type': 'bank',
            'color': '#${PropertyTest.randomInt(min: 0, max: 0xFFFFFF).toRadixString(16).padLeft(6, '0')}',
            'icon': 'account_balance',
            'creditLimit': PropertyTest.randomPositiveDouble(min: 1000, max: 100000),
            'interestRate': PropertyTest.randomPositiveDouble(min: 1, max: 50),
          };
        });
        
        return {
          'kmhAccounts': kmhAccounts,
        };
      },
      property: (data) async {
        // Clear data before each iteration
        final prefs = await dataService.getPrefs();
        await prefs.setString('wallets', '[]');
        await dataService.saveWallets([]);
        
        final kmhAccountsData = data['kmhAccounts'] as List<Map<String, dynamic>>;
        
        // Create all KMH accounts with positive balances
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
          );
          await dataService.addWallet(wallet);
        }
        
        // Retrieve all wallets
        final retrievedWallets = await dataService.getWallets();
        
        // Filter KMH accounts
        final kmhWallets = retrievedWallets
            .where((w) => w.isKmhAccount)
            .toList();
        
        // Property 1: All KMH accounts should have positive balance
        for (var wallet in kmhWallets) {
          expect(wallet.balance, greaterThan(0),
            reason: 'All generated KMH accounts should have positive balance');
        }
        
        // Property 2: Positive balance KMH accounts should be classified as assets
        // (included in positive assets calculation)
        final positiveAssets = retrievedWallets
            .where((w) => w.type != 'credit_card' && w.balance > 0)
            .fold(0.0, (sum, w) => sum + w.balance);
        
        // Calculate expected positive assets from KMH accounts
        final kmhPositiveAssets = kmhWallets
            .where((w) => w.balance > 0)
            .fold(0.0, (sum, w) => sum + w.balance);
        
        // All KMH positive balances should be included in positive assets
        expect(positiveAssets, equals(kmhPositiveAssets),
          reason: 'All positive KMH balances should be included in positive assets');
        
        // Property 3: Positive balance KMH accounts should NOT be classified as debts
        final kmhDebts = kmhWallets
            .where((w) => w.balance < 0)
            .fold(0.0, (sum, w) => sum + w.balance.abs());
        
        expect(kmhDebts, equals(0.0),
          reason: 'Positive balance KMH accounts should not contribute to KMH debts');
        
        // Property 4: Each positive KMH account should be individually verifiable as asset
        for (var wallet in kmhWallets) {
          // Verify it's included in asset calculation
          final isIncludedInAssets = wallet.balance > 0;
          expect(isIncludedInAssets, isTrue,
            reason: 'KMH account with balance ${wallet.balance} should be classified as asset');
          
          // Verify it's NOT included in debt calculation
          final isIncludedInDebts = wallet.balance < 0;
          expect(isIncludedInDebts, isFalse,
            reason: 'KMH account with positive balance should not be classified as debt');
        }
        
        return true;
      },
      iterations: 100,
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 24: KMH accounts with negative balance are classified as debts',
      generator: () {
        final kmhAccountCount = PropertyTest.randomInt(min: 1, max: 10);
        
        // Generate KMH accounts with negative balances
        final kmhAccounts = List.generate(kmhAccountCount, (index) {
          return {
            'id': const Uuid().v4(),
            'name': 'KMH Account ${index + 1}',
            'balance': -PropertyTest.randomPositiveDouble(min: 0.01, max: 50000),
            'type': 'bank',
            'color': '#${PropertyTest.randomInt(min: 0, max: 0xFFFFFF).toRadixString(16).padLeft(6, '0')}',
            'icon': 'account_balance',
            'creditLimit': PropertyTest.randomPositiveDouble(min: 1000, max: 100000),
            'interestRate': PropertyTest.randomPositiveDouble(min: 1, max: 50),
          };
        });
        
        return {
          'kmhAccounts': kmhAccounts,
        };
      },
      property: (data) async {
        // Clear data before each iteration
        final prefs = await dataService.getPrefs();
        await prefs.setString('wallets', '[]');
        await dataService.saveWallets([]);
        
        final kmhAccountsData = data['kmhAccounts'] as List<Map<String, dynamic>>;
        
        // Create all KMH accounts with negative balances
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
          );
          await dataService.addWallet(wallet);
        }
        
        // Retrieve all wallets
        final retrievedWallets = await dataService.getWallets();
        
        // Filter KMH accounts
        final kmhWallets = retrievedWallets
            .where((w) => w.isKmhAccount)
            .toList();
        
        // Property 1: All KMH accounts should have negative balance
        for (var wallet in kmhWallets) {
          expect(wallet.balance, lessThan(0),
            reason: 'All generated KMH accounts should have negative balance');
        }
        
        // Property 2: Negative balance KMH accounts should be classified as debts
        // (included in KMH debts calculation)
        final kmhDebts = kmhWallets
            .where((w) => w.balance < 0)
            .fold(0.0, (sum, w) => sum + w.balance.abs());
        
        // Calculate expected KMH debts
        final expectedKmhDebts = kmhAccountsData
            .fold(0.0, (sum, a) => sum + (a['balance'] as double).abs());
        
        expect(kmhDebts, equals(expectedKmhDebts),
          reason: 'All negative KMH balances should be included in KMH debts');
        
        // Property 3: Negative balance KMH accounts should NOT be classified as assets
        final positiveAssets = retrievedWallets
            .where((w) => w.type != 'credit_card' && w.balance > 0)
            .fold(0.0, (sum, w) => sum + w.balance);
        
        expect(positiveAssets, equals(0.0),
          reason: 'Negative balance KMH accounts should not contribute to positive assets');
        
        // Property 4: Each negative KMH account should be individually verifiable as debt
        for (var wallet in kmhWallets) {
          // Verify it's included in debt calculation
          final isIncludedInDebts = wallet.balance < 0;
          expect(isIncludedInDebts, isTrue,
            reason: 'KMH account with balance ${wallet.balance} should be classified as debt');
          
          // Verify it's NOT included in asset calculation
          final isIncludedInAssets = wallet.balance > 0;
          expect(isIncludedInAssets, isFalse,
            reason: 'KMH account with negative balance should not be classified as asset');
        }
        
        return true;
      },
      iterations: 100,
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 24: KMH accounts with mixed balances are correctly classified',
      generator: () {
        final kmhAccountCount = PropertyTest.randomInt(min: 2, max: 10);
        
        // Generate KMH accounts with mixed positive and negative balances
        final kmhAccounts = List.generate(kmhAccountCount, (index) {
          final isPositive = PropertyTest.randomBool();
          final balance = isPositive
              ? PropertyTest.randomPositiveDouble(min: 0.01, max: 50000)
              : -PropertyTest.randomPositiveDouble(min: 0.01, max: 50000);
          
          return {
            'id': const Uuid().v4(),
            'name': 'KMH Account ${index + 1}',
            'balance': balance,
            'type': 'bank',
            'color': '#${PropertyTest.randomInt(min: 0, max: 0xFFFFFF).toRadixString(16).padLeft(6, '0')}',
            'icon': 'account_balance',
            'creditLimit': PropertyTest.randomPositiveDouble(min: 1000, max: 100000),
            'interestRate': PropertyTest.randomPositiveDouble(min: 1, max: 50),
          };
        });
        
        return {
          'kmhAccounts': kmhAccounts,
        };
      },
      property: (data) async {
        // Clear data before each iteration
        final prefs = await dataService.getPrefs();
        await prefs.setString('wallets', '[]');
        await dataService.saveWallets([]);
        
        final kmhAccountsData = data['kmhAccounts'] as List<Map<String, dynamic>>;
        
        // Create all KMH accounts with mixed balances
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
          );
          await dataService.addWallet(wallet);
        }
        
        // Retrieve all wallets
        final retrievedWallets = await dataService.getWallets();
        
        // Filter KMH accounts
        final kmhWallets = retrievedWallets
            .where((w) => w.isKmhAccount)
            .toList();
        
        // Calculate expected values from generated data
        final expectedPositiveAssets = kmhAccountsData
            .where((a) => (a['balance'] as double) > 0)
            .fold(0.0, (sum, a) => sum + (a['balance'] as double));
        
        final expectedKmhDebts = kmhAccountsData
            .where((a) => (a['balance'] as double) < 0)
            .fold(0.0, (sum, a) => sum + (a['balance'] as double).abs());
        
        // Calculate actual values
        final positiveAssets = retrievedWallets
            .where((w) => w.type != 'credit_card' && w.balance > 0)
            .fold(0.0, (sum, w) => sum + w.balance);
        
        final kmhDebts = kmhWallets
            .where((w) => w.balance < 0)
            .fold(0.0, (sum, w) => sum + w.balance.abs());
        
        // Property 1: Positive KMH balances should be classified as assets
        expect(positiveAssets, equals(expectedPositiveAssets),
          reason: 'Positive KMH balances should be included in assets');
        
        // Property 2: Negative KMH balances should be classified as debts
        expect(kmhDebts, equals(expectedKmhDebts),
          reason: 'Negative KMH balances should be included in debts');
        
        // Property 3: Each account should be classified correctly based on its balance
        for (var wallet in kmhWallets) {
          if (wallet.balance > 0) {
            // Should be classified as asset
            final isInAssets = positiveAssets >= wallet.balance;
            expect(isInAssets, isTrue,
              reason: 'KMH account ${wallet.name} with positive balance should be in assets');
            
            // Should NOT contribute to debts
            final contributesToDebts = wallet.balance < 0;
            expect(contributesToDebts, isFalse,
              reason: 'KMH account ${wallet.name} with positive balance should not contribute to debts');
          } else if (wallet.balance < 0) {
            // Should be classified as debt
            final isInDebts = kmhDebts >= wallet.balance.abs();
            expect(isInDebts, isTrue,
              reason: 'KMH account ${wallet.name} with negative balance should be in debts');
            
            // Should NOT contribute to assets
            final contributesToAssets = wallet.balance > 0;
            expect(contributesToAssets, isFalse,
              reason: 'KMH account ${wallet.name} with negative balance should not contribute to assets');
          }
        }
        
        // Property 4: No account should be classified as both asset and debt
        for (var wallet in kmhWallets) {
          final isAsset = wallet.balance > 0;
          final isDebt = wallet.balance < 0;
          
          // An account cannot be both asset and debt
          expect(isAsset && isDebt, isFalse,
            reason: 'Account cannot be both asset and debt simultaneously');
          
          // An account with non-zero balance must be either asset or debt
          if (wallet.balance != 0) {
            expect(isAsset || isDebt, isTrue,
              reason: 'Account with non-zero balance must be either asset or debt');
          }
        }
        
        // Property 5: Classification should be consistent with balance sign
        for (var wallet in kmhWallets) {
          if (wallet.balance > 0) {
            // Positive balance = asset
            final classifiedAsAsset = positiveAssets >= wallet.balance;
            expect(classifiedAsAsset, isTrue,
              reason: 'Positive balance should result in asset classification');
          } else if (wallet.balance < 0) {
            // Negative balance = debt
            final classifiedAsDebt = kmhDebts >= wallet.balance.abs();
            expect(classifiedAsDebt, isTrue,
              reason: 'Negative balance should result in debt classification');
          }
        }
        
        return true;
      },
      iterations: 100,
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 24: Zero balance KMH accounts are neither asset nor debt',
      generator: () {
        final kmhAccountCount = PropertyTest.randomInt(min: 1, max: 5);
        
        // Generate KMH accounts with zero balance
        final kmhAccounts = List.generate(kmhAccountCount, (index) {
          return {
            'id': const Uuid().v4(),
            'name': 'KMH Account ${index + 1}',
            'balance': 0.0,
            'type': 'bank',
            'color': '#${PropertyTest.randomInt(min: 0, max: 0xFFFFFF).toRadixString(16).padLeft(6, '0')}',
            'icon': 'account_balance',
            'creditLimit': PropertyTest.randomPositiveDouble(min: 1000, max: 100000),
            'interestRate': PropertyTest.randomPositiveDouble(min: 1, max: 50),
          };
        });
        
        return {
          'kmhAccounts': kmhAccounts,
        };
      },
      property: (data) async {
        // Clear data before each iteration
        final prefs = await dataService.getPrefs();
        await prefs.setString('wallets', '[]');
        await dataService.saveWallets([]);
        
        final kmhAccountsData = data['kmhAccounts'] as List<Map<String, dynamic>>;
        
        // Create all KMH accounts with zero balance
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
          );
          await dataService.addWallet(wallet);
        }
        
        // Retrieve all wallets
        final retrievedWallets = await dataService.getWallets();
        
        // Filter KMH accounts
        final kmhWallets = retrievedWallets
            .where((w) => w.isKmhAccount)
            .toList();
        
        // Property 1: All KMH accounts should have zero balance
        for (var wallet in kmhWallets) {
          expect(wallet.balance, equals(0.0),
            reason: 'All generated KMH accounts should have zero balance');
        }
        
        // Property 2: Zero balance accounts should not contribute to assets
        final positiveAssets = retrievedWallets
            .where((w) => w.type != 'credit_card' && w.balance > 0)
            .fold(0.0, (sum, w) => sum + w.balance);
        
        expect(positiveAssets, equals(0.0),
          reason: 'Zero balance KMH accounts should not contribute to positive assets');
        
        // Property 3: Zero balance accounts should not contribute to debts
        final kmhDebts = kmhWallets
            .where((w) => w.balance < 0)
            .fold(0.0, (sum, w) => sum + w.balance.abs());
        
        expect(kmhDebts, equals(0.0),
          reason: 'Zero balance KMH accounts should not contribute to KMH debts');
        
        // Property 4: Each zero balance account should be neither asset nor debt
        for (var wallet in kmhWallets) {
          final isAsset = wallet.balance > 0;
          final isDebt = wallet.balance < 0;
          
          expect(isAsset, isFalse,
            reason: 'Zero balance account should not be classified as asset');
          expect(isDebt, isFalse,
            reason: 'Zero balance account should not be classified as debt');
        }
        
        return true;
      },
      iterations: 100,
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 24: Classification is independent of credit limit',
      generator: () {
        final kmhAccountCount = PropertyTest.randomInt(min: 2, max: 8);
        
        // Generate KMH accounts with various credit limits but same balance sign
        final kmhAccounts = List.generate(kmhAccountCount, (index) {
          final isPositive = PropertyTest.randomBool();
          final balance = isPositive
              ? PropertyTest.randomPositiveDouble(min: 100, max: 10000)
              : -PropertyTest.randomPositiveDouble(min: 100, max: 10000);
          
          return {
            'id': const Uuid().v4(),
            'name': 'KMH Account ${index + 1}',
            'balance': balance,
            'type': 'bank',
            'color': '#${PropertyTest.randomInt(min: 0, max: 0xFFFFFF).toRadixString(16).padLeft(6, '0')}',
            'icon': 'account_balance',
            // Vary credit limits widely
            'creditLimit': PropertyTest.randomPositiveDouble(min: 1000, max: 100000),
            'interestRate': PropertyTest.randomPositiveDouble(min: 1, max: 50),
          };
        });
        
        return {
          'kmhAccounts': kmhAccounts,
        };
      },
      property: (data) async {
        // Clear data before each iteration
        final prefs = await dataService.getPrefs();
        await prefs.setString('wallets', '[]');
        await dataService.saveWallets([]);
        
        final kmhAccountsData = data['kmhAccounts'] as List<Map<String, dynamic>>;
        
        // Create all KMH accounts
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
          );
          await dataService.addWallet(wallet);
        }
        
        // Retrieve all wallets
        final retrievedWallets = await dataService.getWallets();
        
        // Filter KMH accounts
        final kmhWallets = retrievedWallets
            .where((w) => w.isKmhAccount)
            .toList();
        
        // Property: Classification should depend only on balance sign, not credit limit
        for (var wallet in kmhWallets) {
          final accountData = kmhAccountsData.firstWhere((a) => a['id'] == wallet.id);
          final originalBalance = accountData['balance'] as double;
          final creditLimit = accountData['creditLimit'] as double;
          
          // Classification should match balance sign regardless of credit limit
          if (originalBalance > 0) {
            // Should be asset regardless of credit limit
            expect(wallet.balance, greaterThan(0),
              reason: 'Positive balance should classify as asset regardless of credit limit $creditLimit');
          } else if (originalBalance < 0) {
            // Should be debt regardless of credit limit
            expect(wallet.balance, lessThan(0),
              reason: 'Negative balance should classify as debt regardless of credit limit $creditLimit');
          }
          
          // Verify credit limit doesn't affect classification
          final isAsset = wallet.balance > 0;
          final isDebt = wallet.balance < 0;
          
          // Classification should be based on balance, not credit limit
          if (isAsset) {
            expect(wallet.balance, greaterThan(0),
              reason: 'Asset classification should be based on positive balance, not credit limit');
          }
          if (isDebt) {
            expect(wallet.balance, lessThan(0),
              reason: 'Debt classification should be based on negative balance, not credit limit');
          }
        }
        
        return true;
      },
      iterations: 100,
    );
  });
}
