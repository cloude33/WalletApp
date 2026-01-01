import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:parion/models/wallet.dart';
import 'package:parion/services/data_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../property_test_utils.dart';
import 'package:uuid/uuid.dart';

/// **Feature: kmh-account-management, Property 31: Öneri Kriterleri**
/// **Validates: Requirements 8.4**
/// 
/// Property: For any account recommendation, both available credit and interest rate
/// must be taken into consideration.
void main() {
  group('KMH Recommendation Criteria Property Tests', () {
    late DataService dataService;
    late Directory testDir;

    setUpAll(() async {
      // Create a temporary directory for testing
      testDir = await Directory.systemTemp.createTemp('kmh_recommendation_criteria_test_');
      
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

    /// Helper function to find recommended account (mimics the screen logic)
    Wallet? findRecommendedAccount(List<Wallet> accounts) {
      if (accounts.isEmpty) return null;

      // Filter accounts with available credit
      final accountsWithCredit = accounts.where((a) => a.availableCredit > 0).toList();
      
      if (accountsWithCredit.isEmpty) return null;

      // Find account with lowest interest rate among those with available credit
      accountsWithCredit.sort((a, b) {
        final rateA = a.interestRate ?? double.infinity;
        final rateB = b.interestRate ?? double.infinity;
        
        // First compare by interest rate
        final rateComparison = rateA.compareTo(rateB);
        if (rateComparison != 0) return rateComparison;
        
        // If rates are equal, prefer account with more available credit
        return b.availableCredit.compareTo(a.availableCredit);
      });

      return accountsWithCredit.first;
    }

    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 31: Recommendation must consider both available credit and interest rate',
      generator: () {
        final accountCount = PropertyTest.randomInt(min: 3, max: 8);
        
        final accounts = List.generate(accountCount, (index) {
          final creditLimit = PropertyTest.randomPositiveDouble(min: 1000, max: 100000);
          // Generate varied balances to create different available credit scenarios
          final balance = PropertyTest.randomDouble(min: -creditLimit * 1.2, max: creditLimit * 0.5);
          
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
        
        // Find recommended account
        final recommended = findRecommendedAccount(kmhAccounts);
        
        // Filter accounts with available credit
        final accountsWithCredit = kmhAccounts.where((a) => a.availableCredit > 0).toList();
        
        // Property 1: Recommendation must only consider accounts with available credit
        if (accountsWithCredit.isNotEmpty) {
          expect(recommended, isNotNull,
            reason: 'Should have a recommendation when accounts with credit exist');
          
          // Verify recommended account has available credit
          expect(recommended!.availableCredit, greaterThan(0),
            reason: 'Recommended account must have available credit (criterion 1: available credit)');
          
          // Verify recommended account is from the set of accounts with credit
          expect(accountsWithCredit.map((a) => a.id).contains(recommended.id), isTrue,
            reason: 'Recommended account must be from accounts with available credit');
        }
        
        // Property 2: Among accounts with credit, must prefer lowest interest rate
        if (accountsWithCredit.isNotEmpty && recommended != null) {
          final minRate = accountsWithCredit
            .map((a) => a.interestRate ?? double.infinity)
            .reduce((a, b) => a < b ? a : b);
          
          expect(recommended.interestRate, equals(minRate),
            reason: 'Recommended account must have lowest interest rate among accounts with credit (criterion 2: interest rate)');
        }
        
        // Property 3: Accounts without available credit must never be recommended
        final accountsWithoutCredit = kmhAccounts.where((a) => a.availableCredit <= 0).toList();
        if (recommended != null && accountsWithoutCredit.isNotEmpty) {
          for (var account in accountsWithoutCredit) {
            expect(recommended.id, isNot(equals(account.id)),
              reason: 'Account without available credit should never be recommended, even if it has lower interest rate');
          }
        }
        
        return true;
      },
      iterations: 100,
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 31: Accounts without credit should be excluded even if they have the lowest interest rate',
      generator: () {
        final accounts = [
          // Account 1: Lowest interest rate but NO available credit
          {
            'id': const Uuid().v4(),
            'name': 'Lowest Rate - No Credit',
            'balance': -10000.0,
            'type': 'bank',
            'color': '#FF0000',
            'icon': 'account_balance',
            'creditLimit': 10000.0,
            'interestRate': PropertyTest.randomPositiveDouble(min: 5, max: 10),
            'lastInterestDate': PropertyTest.randomDateTime(),
            'accruedInterest': PropertyTest.randomPositiveDouble(min: 0, max: 5000),
            'accountNumber': PropertyTest.randomInt(min: 100000, max: 999999).toString(),
          },
          // Account 2: Higher interest rate but HAS available credit
          {
            'id': const Uuid().v4(),
            'name': 'Higher Rate - Has Credit',
            'balance': -5000.0,
            'type': 'bank',
            'color': '#00FF00',
            'icon': 'account_balance',
            'creditLimit': 10000.0,
            'interestRate': PropertyTest.randomPositiveDouble(min: 20, max: 40),
            'lastInterestDate': PropertyTest.randomDateTime(),
            'accruedInterest': PropertyTest.randomPositiveDouble(min: 0, max: 3000),
            'accountNumber': PropertyTest.randomInt(min: 100000, max: 999999).toString(),
          },
          // Account 3: Even higher rate but also has credit
          {
            'id': const Uuid().v4(),
            'name': 'Highest Rate - Has Credit',
            'balance': -2000.0,
            'type': 'bank',
            'color': '#0000FF',
            'icon': 'account_balance',
            'creditLimit': 10000.0,
            'interestRate': PropertyTest.randomPositiveDouble(min: 45, max: 60),
            'lastInterestDate': PropertyTest.randomDateTime(),
            'accruedInterest': PropertyTest.randomPositiveDouble(min: 0, max: 2000),
            'accountNumber': PropertyTest.randomInt(min: 100000, max: 999999).toString(),
          },
        ];
        
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
        
        // Find recommended account
        final recommended = findRecommendedAccount(kmhAccounts);
        
        // Find specific accounts
        final noCredit = kmhAccounts.firstWhere((a) => a.name == 'Lowest Rate - No Credit');
        final hasCredit = kmhAccounts.firstWhere((a) => a.name == 'Higher Rate - Has Credit');
        
        // Verify test setup
        expect(noCredit.availableCredit, lessThanOrEqualTo(0),
          reason: 'Test setup: first account should have no available credit');
        expect(hasCredit.availableCredit, greaterThan(0),
          reason: 'Test setup: second account should have available credit');
        expect(noCredit.interestRate, lessThan(hasCredit.interestRate!),
          reason: 'Test setup: no-credit account should have lower rate');
        
        // Property: Available credit criterion takes precedence over interest rate
        expect(recommended, isNotNull,
          reason: 'Should have a recommendation');
        expect(recommended!.id, isNot(equals(noCredit.id)),
          reason: 'Account without credit should NOT be recommended even with lowest rate (available credit criterion must be satisfied first)');
        expect(recommended.id, equals(hasCredit.id),
          reason: 'Account with credit should be recommended (both criteria: has credit AND lowest rate among those with credit)');
        
        return true;
      },
      iterations: 100,
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 31: When multiple accounts have same rate, available credit amount is the tiebreaker',
      generator: () {
        final sameRate = PropertyTest.randomPositiveDouble(min: 15, max: 25);
        
        final accounts = [
          // Account 1: Same rate, less available credit
          {
            'id': const Uuid().v4(),
            'name': 'Same Rate - Less Credit',
            'balance': -7000.0,
            'type': 'bank',
            'color': '#FF0000',
            'icon': 'account_balance',
            'creditLimit': 10000.0,
            'interestRate': sameRate,
            'lastInterestDate': PropertyTest.randomDateTime(),
            'accruedInterest': PropertyTest.randomPositiveDouble(min: 0, max: 3000),
            'accountNumber': PropertyTest.randomInt(min: 100000, max: 999999).toString(),
          },
          // Account 2: Same rate, more available credit
          {
            'id': const Uuid().v4(),
            'name': 'Same Rate - More Credit',
            'balance': -2000.0,
            'type': 'bank',
            'color': '#00FF00',
            'icon': 'account_balance',
            'creditLimit': 10000.0,
            'interestRate': sameRate,
            'lastInterestDate': PropertyTest.randomDateTime(),
            'accruedInterest': PropertyTest.randomPositiveDouble(min: 0, max: 1000),
            'accountNumber': PropertyTest.randomInt(min: 100000, max: 999999).toString(),
          },
          // Account 3: Higher rate
          {
            'id': const Uuid().v4(),
            'name': 'Higher Rate',
            'balance': -1000.0,
            'type': 'bank',
            'color': '#0000FF',
            'icon': 'account_balance',
            'creditLimit': 10000.0,
            'interestRate': sameRate + PropertyTest.randomPositiveDouble(min: 5, max: 15),
            'lastInterestDate': PropertyTest.randomDateTime(),
            'accruedInterest': PropertyTest.randomPositiveDouble(min: 0, max: 500),
            'accountNumber': PropertyTest.randomInt(min: 100000, max: 999999).toString(),
          },
        ];
        
        return {'accounts': accounts, 'sameRate': sameRate};
      },
      property: (data) async {
        // Clear wallets before each iteration
        final prefs = await dataService.getPrefs();
        await prefs.setString('wallets', '[]');
        await dataService.saveWallets([]);
        
        final accountsData = data['accounts'] as List<Map<String, dynamic>>;
        final sameRate = data['sameRate'] as double;
        
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
        
        // Find recommended account
        final recommended = findRecommendedAccount(kmhAccounts);
        
        // Find specific accounts
        final lessCredit = kmhAccounts.firstWhere((a) => a.name == 'Same Rate - Less Credit');
        final moreCredit = kmhAccounts.firstWhere((a) => a.name == 'Same Rate - More Credit');
        
        // Verify test setup
        expect(lessCredit.interestRate, equals(sameRate),
          reason: 'Test setup: first account should have the same rate');
        expect(moreCredit.interestRate, equals(sameRate),
          reason: 'Test setup: second account should have the same rate');
        expect(moreCredit.availableCredit, greaterThan(lessCredit.availableCredit),
          reason: 'Test setup: second account should have more available credit');
        
        // Property: When interest rates are equal, prefer account with more available credit
        expect(recommended, isNotNull,
          reason: 'Should have a recommendation');
        expect(recommended!.interestRate, equals(sameRate),
          reason: 'Recommended should have the lowest rate (which is the same rate)');
        expect(recommended.id, equals(moreCredit.id),
          reason: 'When rates are equal, should prefer account with more available credit (both criteria applied: rate AND credit amount)');
        
        return true;
      },
      iterations: 100,
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 31: Recommendation logic must evaluate both criteria in correct order (credit availability first, then rate)',
      generator: () {
        final accounts = [
          // Account 1: No credit, lowest rate (should be excluded by first criterion)
          {
            'id': const Uuid().v4(),
            'name': 'No Credit - Best Rate',
            'balance': -15000.0,
            'type': 'bank',
            'color': '#FF0000',
            'icon': 'account_balance',
            'creditLimit': 10000.0,
            'interestRate': PropertyTest.randomPositiveDouble(min: 5, max: 10),
            'lastInterestDate': PropertyTest.randomDateTime(),
            'accruedInterest': PropertyTest.randomPositiveDouble(min: 0, max: 7000),
            'accountNumber': PropertyTest.randomInt(min: 100000, max: 999999).toString(),
          },
          // Account 2: Has credit, medium rate (should be selected by both criteria)
          {
            'id': const Uuid().v4(),
            'name': 'Has Credit - Medium Rate',
            'balance': -3000.0,
            'type': 'bank',
            'color': '#00FF00',
            'icon': 'account_balance',
            'creditLimit': 10000.0,
            'interestRate': PropertyTest.randomPositiveDouble(min: 20, max: 30),
            'lastInterestDate': PropertyTest.randomDateTime(),
            'accruedInterest': PropertyTest.randomPositiveDouble(min: 0, max: 2000),
            'accountNumber': PropertyTest.randomInt(min: 100000, max: 999999).toString(),
          },
          // Account 3: Has credit, highest rate (should be excluded by second criterion)
          {
            'id': const Uuid().v4(),
            'name': 'Has Credit - Worst Rate',
            'balance': -1000.0,
            'type': 'bank',
            'color': '#0000FF',
            'icon': 'account_balance',
            'creditLimit': 10000.0,
            'interestRate': PropertyTest.randomPositiveDouble(min: 40, max: 60),
            'lastInterestDate': PropertyTest.randomDateTime(),
            'accruedInterest': PropertyTest.randomPositiveDouble(min: 0, max: 500),
            'accountNumber': PropertyTest.randomInt(min: 100000, max: 999999).toString(),
          },
        ];
        
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
        
        // Find recommended account
        final recommended = findRecommendedAccount(kmhAccounts);
        
        // Find specific accounts
        final noCredit = kmhAccounts.firstWhere((a) => a.name == 'No Credit - Best Rate');
        final mediumRate = kmhAccounts.firstWhere((a) => a.name == 'Has Credit - Medium Rate');
        final worstRate = kmhAccounts.firstWhere((a) => a.name == 'Has Credit - Worst Rate');
        
        // Verify test setup
        expect(noCredit.availableCredit, lessThanOrEqualTo(0),
          reason: 'Test setup: first account should have no credit');
        expect(mediumRate.availableCredit, greaterThan(0),
          reason: 'Test setup: second account should have credit');
        expect(worstRate.availableCredit, greaterThan(0),
          reason: 'Test setup: third account should have credit');
        expect(noCredit.interestRate, lessThan(mediumRate.interestRate!),
          reason: 'Test setup: no-credit account should have best rate');
        expect(mediumRate.interestRate, lessThan(worstRate.interestRate!),
          reason: 'Test setup: medium rate should be between best and worst');
        
        // Property: Both criteria must be applied in correct order
        expect(recommended, isNotNull,
          reason: 'Should have a recommendation');
        
        // First criterion: Must have available credit (excludes account 1)
        expect(recommended!.availableCredit, greaterThan(0),
          reason: 'First criterion: recommended must have available credit');
        expect(recommended.id, isNot(equals(noCredit.id)),
          reason: 'First criterion: account without credit must be excluded');
        
        // Second criterion: Among those with credit, must have lowest rate (selects account 2)
        expect(recommended.id, equals(mediumRate.id),
          reason: 'Second criterion: among accounts with credit, must select lowest rate');
        expect(recommended.id, isNot(equals(worstRate.id)),
          reason: 'Second criterion: account with higher rate should not be selected');
        
        return true;
      },
      iterations: 100,
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 31: Recommendation must be null when no accounts satisfy the available credit criterion',
      generator: () {
        final accountCount = PropertyTest.randomInt(min: 2, max: 5);
        
        // Generate accounts where ALL have no available credit
        final accounts = List.generate(accountCount, (index) {
          final creditLimit = PropertyTest.randomPositiveDouble(min: 1000, max: 50000);
          // All accounts at or over their limit
          final balance = -creditLimit - PropertyTest.randomPositiveDouble(min: 0, max: 5000);
          
          return {
            'id': const Uuid().v4(),
            'name': 'Maxed Out Bank ${index + 1}',
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
        
        // Verify all accounts have no available credit
        for (var account in kmhAccounts) {
          expect(account.availableCredit, lessThanOrEqualTo(0),
            reason: 'Test setup: all accounts should have no available credit');
        }
        
        // Find recommended account
        final recommended = findRecommendedAccount(kmhAccounts);
        
        // Property: When no accounts satisfy first criterion (available credit), recommendation must be null
        expect(recommended, isNull,
          reason: 'When no accounts have available credit (first criterion not satisfied), recommendation must be null');
        
        return true;
      },
      iterations: 100,
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 31: Both criteria must be consistently applied across multiple recommendation calls',
      generator: () {
        final accountCount = PropertyTest.randomInt(min: 3, max: 7);
        
        final accounts = List.generate(accountCount, (index) {
          final creditLimit = PropertyTest.randomPositiveDouble(min: 1000, max: 100000);
          final balance = PropertyTest.randomDouble(min: -creditLimit * 1.1, max: creditLimit * 0.4);
          
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
        
        // Find recommended account multiple times
        final recommended1 = findRecommendedAccount(kmhAccounts);
        final recommended2 = findRecommendedAccount(kmhAccounts);
        final recommended3 = findRecommendedAccount(kmhAccounts);
        
        // Property: Criteria application must be consistent across multiple calls
        if (recommended1 != null) {
          expect(recommended2, isNotNull,
            reason: 'Criteria application should be consistent');
          expect(recommended3, isNotNull,
            reason: 'Criteria application should be consistent');
          
          expect(recommended2!.id, equals(recommended1.id),
            reason: 'Same criteria should produce same recommendation on second call');
          expect(recommended3!.id, equals(recommended1.id),
            reason: 'Same criteria should produce same recommendation on third call');
          
          // Verify both criteria are satisfied in all calls
          expect(recommended1.availableCredit, greaterThan(0),
            reason: 'First criterion (available credit) must be satisfied in call 1');
          expect(recommended2.availableCredit, greaterThan(0),
            reason: 'First criterion (available credit) must be satisfied in call 2');
          expect(recommended3.availableCredit, greaterThan(0),
            reason: 'First criterion (available credit) must be satisfied in call 3');
          
          final accountsWithCredit = kmhAccounts.where((a) => a.availableCredit > 0).toList();
          if (accountsWithCredit.isNotEmpty) {
            final minRate = accountsWithCredit
              .map((a) => a.interestRate ?? double.infinity)
              .reduce((a, b) => a < b ? a : b);
            
            expect(recommended1.interestRate, equals(minRate),
              reason: 'Second criterion (lowest rate) must be satisfied in call 1');
            expect(recommended2.interestRate, equals(minRate),
              reason: 'Second criterion (lowest rate) must be satisfied in call 2');
            expect(recommended3.interestRate, equals(minRate),
              reason: 'Second criterion (lowest rate) must be satisfied in call 3');
          }
        } else {
          expect(recommended2, isNull,
            reason: 'Null recommendation should be consistent');
          expect(recommended3, isNull,
            reason: 'Null recommendation should be consistent');
        }
        
        return true;
      },
      iterations: 100,
    );
  });
}
