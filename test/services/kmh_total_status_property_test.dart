import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:money/models/wallet.dart';
import 'package:money/services/data_service.dart';
import 'package:money/services/kmh_interest_calculator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../property_test_utils.dart';
import 'package:uuid/uuid.dart';

/// **Feature: kmh-account-management, Property 32: Toplam KMH Durumu**
/// **Validates: Requirements 8.5**
/// 
/// Property: For any set of KMH accounts, total debt and total interest
/// should equal the sum of all accounts.
void main() {
  group('KMH Total Status Property Tests', () {
    late DataService dataService;
    late KmhInterestCalculator calculator;
    late Directory testDir;

    setUpAll(() async {
      // Create a temporary directory for testing
      testDir = await Directory.systemTemp.createTemp('kmh_total_status_test_');
      
      // Initialize Hive with the test directory
      Hive.init(testDir.path);
    });

    setUp(() async {
      // Clear SharedPreferences before each test
      SharedPreferences.setMockInitialValues({});
      
      // Initialize DataService and Calculator
      dataService = DataService();
      await dataService.init();
      calculator = KmhInterestCalculator();
      
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
      description: 'Property 32: Total debt should equal sum of all account debts',
      generator: () {
        final accountCount = PropertyTest.randomInt(min: 1, max: 10);
        
        final accounts = List.generate(accountCount, (index) {
          final creditLimit = PropertyTest.randomPositiveDouble(min: 1000, max: 100000);
          // Generate various balance scenarios: negative (debt), zero, and positive
          final balance = PropertyTest.randomDouble(min: -creditLimit, max: creditLimit * 0.5);
          
          return {
            'id': const Uuid().v4(),
            'name': 'KMH Bank ${index + 1}',
            'balance': balance,
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
        
        return {'accounts': accounts};
      },
      property: (data) async {
        // Clear wallets before each iteration
        final prefs = await dataService.getPrefs();
        await prefs.setString('wallets', '[]');
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
        final kmhAccounts = retrievedWallets.where((w) => w.isKmhAccount).toList();
        
        // Calculate expected total debt (sum of all used credits)
        double expectedTotalDebt = 0;
        for (var accountData in accountsData) {
          final usedCredit = accountData['balance'] < 0 
            ? (accountData['balance'] as double).abs() 
            : 0.0;
          expectedTotalDebt += usedCredit;
        }
        
        // Calculate actual total debt from retrieved accounts
        double actualTotalDebt = 0;
        for (var account in kmhAccounts) {
          actualTotalDebt += account.usedCredit;
        }
        
        // Property: Total debt should equal sum of all account debts
        expect(actualTotalDebt, closeTo(expectedTotalDebt, 0.01),
          reason: 'Total debt should equal sum of all account debts');
        
        return true;
      },
      iterations: 100,
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 32: Total interest should equal sum of all account interests',
      generator: () {
        final accountCount = PropertyTest.randomInt(min: 1, max: 10);
        
        final accounts = List.generate(accountCount, (index) {
          final creditLimit = PropertyTest.randomPositiveDouble(min: 1000, max: 100000);
          final balance = PropertyTest.randomDouble(min: -creditLimit, max: creditLimit * 0.5);
          
          return {
            'id': const Uuid().v4(),
            'name': 'KMH Bank ${index + 1}',
            'balance': balance,
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
        
        return {'accounts': accounts};
      },
      property: (data) async {
        // Clear wallets before each iteration
        final prefs = await dataService.getPrefs();
        await prefs.setString('wallets', '[]');
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
        final kmhAccounts = retrievedWallets.where((w) => w.isKmhAccount).toList();
        
        // Calculate expected total monthly interest
        double expectedTotalInterest = 0;
        for (var accountData in accountsData) {
          final monthlyInterest = calculator.estimateMonthlyInterest(
            balance: accountData['balance'],
            annualRate: accountData['interestRate'],
          );
          expectedTotalInterest += monthlyInterest;
        }
        
        // Calculate actual total monthly interest from retrieved accounts
        double actualTotalInterest = 0;
        for (var account in kmhAccounts) {
          final monthlyInterest = calculator.estimateMonthlyInterest(
            balance: account.balance,
            annualRate: account.interestRate!,
          );
          actualTotalInterest += monthlyInterest;
        }
        
        // Property: Total interest should equal sum of all account interests
        expect(actualTotalInterest, closeTo(expectedTotalInterest, 0.01),
          reason: 'Total interest should equal sum of all account interests');
        
        return true;
      },
      iterations: 100,
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 32: Total status should be consistent (debt and interest together)',
      generator: () {
        final accountCount = PropertyTest.randomInt(min: 2, max: 8);
        
        final accounts = List.generate(accountCount, (index) {
          final creditLimit = PropertyTest.randomPositiveDouble(min: 1000, max: 100000);
          final balance = PropertyTest.randomDouble(min: -creditLimit, max: creditLimit * 0.5);
          
          return {
            'id': const Uuid().v4(),
            'name': 'KMH Bank ${index + 1}',
            'balance': balance,
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
        
        return {'accounts': accounts};
      },
      property: (data) async {
        // Clear wallets before each iteration
        final prefs = await dataService.getPrefs();
        await prefs.setString('wallets', '[]');
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
        final kmhAccounts = retrievedWallets.where((w) => w.isKmhAccount).toList();
        
        // Calculate expected totals
        double expectedTotalDebt = 0;
        double expectedTotalInterest = 0;
        double expectedTotalCreditLimit = 0;
        double expectedTotalAvailableCredit = 0;
        
        for (var accountData in accountsData) {
          final usedCredit = accountData['balance'] < 0 
            ? (accountData['balance'] as double).abs() 
            : 0.0;
          expectedTotalDebt += usedCredit;
          
          final monthlyInterest = calculator.estimateMonthlyInterest(
            balance: accountData['balance'],
            annualRate: accountData['interestRate'],
          );
          expectedTotalInterest += monthlyInterest;
          
          expectedTotalCreditLimit += accountData['creditLimit'] as double;
          
          final availableCredit = (accountData['creditLimit'] as double) + (accountData['balance'] as double);
          expectedTotalAvailableCredit += availableCredit;
        }
        
        // Calculate actual totals from retrieved accounts
        double actualTotalDebt = 0;
        double actualTotalInterest = 0;
        double actualTotalCreditLimit = 0;
        double actualTotalAvailableCredit = 0;
        
        for (var account in kmhAccounts) {
          actualTotalDebt += account.usedCredit;
          
          final monthlyInterest = calculator.estimateMonthlyInterest(
            balance: account.balance,
            annualRate: account.interestRate!,
          );
          actualTotalInterest += monthlyInterest;
          
          actualTotalCreditLimit += account.creditLimit;
          actualTotalAvailableCredit += account.availableCredit;
        }
        
        // Property: All totals should match
        expect(actualTotalDebt, closeTo(expectedTotalDebt, 0.01),
          reason: 'Total debt should match');
        expect(actualTotalInterest, closeTo(expectedTotalInterest, 0.01),
          reason: 'Total interest should match');
        expect(actualTotalCreditLimit, closeTo(expectedTotalCreditLimit, 0.01),
          reason: 'Total credit limit should match');
        expect(actualTotalAvailableCredit, closeTo(expectedTotalAvailableCredit, 0.01),
          reason: 'Total available credit should match');
        
        return true;
      },
      iterations: 100,
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 32: Total status should handle edge cases (all positive, all negative, mixed)',
      generator: () {
        // Generate three scenarios: all positive, all negative, mixed
        final scenario = PropertyTest.randomInt(min: 0, max: 2);
        
        final accountCount = PropertyTest.randomInt(min: 2, max: 5);
        
        final accounts = List.generate(accountCount, (index) {
          final creditLimit = PropertyTest.randomPositiveDouble(min: 1000, max: 100000);
          
          double balance;
          if (scenario == 0) {
            // All positive balances
            balance = PropertyTest.randomPositiveDouble(min: 1, max: creditLimit * 0.5);
          } else if (scenario == 1) {
            // All negative balances (debts)
            balance = -PropertyTest.randomPositiveDouble(min: 1, max: creditLimit);
          } else {
            // Mixed balances
            balance = PropertyTest.randomDouble(min: -creditLimit, max: creditLimit * 0.5);
          }
          
          return {
            'id': const Uuid().v4(),
            'name': 'KMH Bank ${index + 1}',
            'balance': balance,
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
        
        return {'accounts': accounts, 'scenario': scenario};
      },
      property: (data) async {
        // Clear wallets before each iteration
        final prefs = await dataService.getPrefs();
        await prefs.setString('wallets', '[]');
        await dataService.saveWallets([]);
        
        final accountsData = data['accounts'] as List<Map<String, dynamic>>;
        final scenario = data['scenario'] as int;
        
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
        final kmhAccounts = retrievedWallets.where((w) => w.isKmhAccount).toList();
        
        // Calculate totals
        double totalDebt = 0;
        double totalInterest = 0;
        
        for (var account in kmhAccounts) {
          totalDebt += account.usedCredit;
          
          final monthlyInterest = calculator.estimateMonthlyInterest(
            balance: account.balance,
            annualRate: account.interestRate!,
          );
          totalInterest += monthlyInterest;
        }
        
        // Verify scenario-specific properties
        if (scenario == 0) {
          // All positive: total debt and interest should be 0
          expect(totalDebt, equals(0.0),
            reason: 'All positive balances should result in zero total debt');
          expect(totalInterest, equals(0.0),
            reason: 'All positive balances should result in zero total interest');
        } else if (scenario == 1) {
          // All negative: total debt and interest should be positive
          expect(totalDebt, greaterThan(0.0),
            reason: 'All negative balances should result in positive total debt');
          expect(totalInterest, greaterThan(0.0),
            reason: 'All negative balances should result in positive total interest');
        }
        // For mixed scenario (2), we just verify the sum is correct (already tested above)
        
        // Verify that totals are non-negative
        expect(totalDebt, greaterThanOrEqualTo(0.0),
          reason: 'Total debt should never be negative');
        expect(totalInterest, greaterThanOrEqualTo(0.0),
          reason: 'Total interest should never be negative');
        
        return true;
      },
      iterations: 100,
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 32: Total status should be independent of account order',
      generator: () {
        final accountCount = PropertyTest.randomInt(min: 3, max: 8);
        
        final accounts = List.generate(accountCount, (index) {
          final creditLimit = PropertyTest.randomPositiveDouble(min: 1000, max: 100000);
          final balance = PropertyTest.randomDouble(min: -creditLimit, max: creditLimit * 0.5);
          
          return {
            'id': const Uuid().v4(),
            'name': 'KMH Bank ${index + 1}',
            'balance': balance,
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
        
        return {'accounts': accounts};
      },
      property: (data) async {
        // Clear wallets before each iteration
        final prefs = await dataService.getPrefs();
        await prefs.setString('wallets', '[]');
        await dataService.saveWallets([]);
        
        final accountsData = data['accounts'] as List<Map<String, dynamic>>;
        
        // Create accounts in original order
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
        
        // Calculate totals for first order
        final retrievedWallets1 = await dataService.getWallets();
        final kmhAccounts1 = retrievedWallets1.where((w) => w.isKmhAccount).toList();
        
        double totalDebt1 = 0;
        double totalInterest1 = 0;
        
        for (var account in kmhAccounts1) {
          totalDebt1 += account.usedCredit;
          
          final monthlyInterest = calculator.estimateMonthlyInterest(
            balance: account.balance,
            annualRate: account.interestRate!,
          );
          totalInterest1 += monthlyInterest;
        }
        
        // Clear and recreate in different order
        await prefs.setString('wallets', '[]');
        await dataService.saveWallets([]);
        
        final shuffledAccounts = List<Map<String, dynamic>>.from(accountsData);
        shuffledAccounts.shuffle();
        
        for (var accountData in shuffledAccounts) {
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
        
        // Calculate totals for second order
        final retrievedWallets2 = await dataService.getWallets();
        final kmhAccounts2 = retrievedWallets2.where((w) => w.isKmhAccount).toList();
        
        double totalDebt2 = 0;
        double totalInterest2 = 0;
        
        for (var account in kmhAccounts2) {
          totalDebt2 += account.usedCredit;
          
          final monthlyInterest = calculator.estimateMonthlyInterest(
            balance: account.balance,
            annualRate: account.interestRate!,
          );
          totalInterest2 += monthlyInterest;
        }
        
        // Property: Totals should be the same regardless of order
        expect(totalDebt2, closeTo(totalDebt1, 0.01),
          reason: 'Total debt should be same regardless of account order');
        expect(totalInterest2, closeTo(totalInterest1, 0.01),
          reason: 'Total interest should be same regardless of account order');
        
        return true;
      },
      iterations: 100,
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 32: Total status with single account should equal that account\'s values',
      generator: () {
        final creditLimit = PropertyTest.randomPositiveDouble(min: 1000, max: 100000);
        final balance = PropertyTest.randomDouble(min: -creditLimit, max: creditLimit * 0.5);
        
        return {
          'id': const Uuid().v4(),
          'name': 'Single KMH Account',
          'balance': balance,
          'type': 'bank',
          'color': '#${PropertyTest.randomInt(min: 0, max: 0xFFFFFF).toRadixString(16).padLeft(6, '0')}',
          'icon': 'account_balance',
          'creditLimit': creditLimit,
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
        await dataService.saveWallets([]);
        
        // Create single KMH account
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
        
        // Retrieve wallet
        final retrievedWallets = await dataService.getWallets();
        final kmhAccounts = retrievedWallets.where((w) => w.isKmhAccount).toList();
        
        expect(kmhAccounts.length, equals(1),
          reason: 'Should have exactly one KMH account');
        
        final account = kmhAccounts.first;
        
        // Calculate totals (which should equal the single account's values)
        double totalDebt = 0;
        double totalInterest = 0;
        
        for (var acc in kmhAccounts) {
          totalDebt += acc.usedCredit;
          
          final monthlyInterest = calculator.estimateMonthlyInterest(
            balance: acc.balance,
            annualRate: acc.interestRate!,
          );
          totalInterest += monthlyInterest;
        }
        
        // Property: Total should equal the single account's values
        expect(totalDebt, equals(account.usedCredit),
          reason: 'Total debt should equal single account\'s used credit');
        
        final accountInterest = calculator.estimateMonthlyInterest(
          balance: account.balance,
          annualRate: account.interestRate!,
        );
        expect(totalInterest, closeTo(accountInterest, 0.01),
          reason: 'Total interest should equal single account\'s interest');
        
        return true;
      },
      iterations: 100,
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 32: Total status with zero accounts should be zero',
      generator: () {
        return {};
      },
      property: (data) async {
        // Clear wallets before each iteration
        final prefs = await dataService.getPrefs();
        await prefs.setString('wallets', '[]');
        await dataService.saveWallets([]);
        
        // Don't create any KMH accounts
        
        // Retrieve wallets
        final retrievedWallets = await dataService.getWallets();
        final kmhAccounts = retrievedWallets.where((w) => w.isKmhAccount).toList();
        
        expect(kmhAccounts.length, equals(0),
          reason: 'Should have no KMH accounts');
        
        // Calculate totals (should be zero)
        double totalDebt = 0;
        double totalInterest = 0;
        
        for (var account in kmhAccounts) {
          totalDebt += account.usedCredit;
          
          final monthlyInterest = calculator.estimateMonthlyInterest(
            balance: account.balance,
            annualRate: account.interestRate!,
          );
          totalInterest += monthlyInterest;
        }
        
        // Property: Totals should be zero when no accounts exist
        expect(totalDebt, equals(0.0),
          reason: 'Total debt should be zero with no accounts');
        expect(totalInterest, equals(0.0),
          reason: 'Total interest should be zero with no accounts');
        
        return true;
      },
      iterations: 100,
    );
  });
}
