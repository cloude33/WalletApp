import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:money/models/wallet.dart';
import 'package:money/services/data_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../property_test_utils.dart';
import 'package:uuid/uuid.dart';

/// **Feature: kmh-account-management, Property 30: En Düşük Faiz Önerisi**
/// **Validates: Requirements 8.3**
///
/// Property: For any set of KMH accounts, the recommended account should be
/// the one with the lowest interest rate among accounts with available credit.
void main() {
  group('KMH Lowest Interest Recommendation Property Tests', () {
    late DataService dataService;
    late Directory testDir;

    setUpAll(() async {
      // Create a temporary directory for testing
      testDir = await Directory.systemTemp.createTemp(
        'kmh_lowest_interest_test_',
      );

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
      final accountsWithCredit = accounts
          .where((a) => a.availableCredit > 0)
          .toList();

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
      description:
          'Property 30: Recommended account should have the lowest interest rate among accounts with available credit',
      generator: () {
        final accountCount = PropertyTest.randomInt(min: 2, max: 10);

        final accounts = List.generate(accountCount, (index) {
          final creditLimit = PropertyTest.randomPositiveDouble(
            min: 1000,
            max: 100000,
          );
          // Generate some accounts with available credit and some without
          final balance = PropertyTest.randomDouble(
            min: -creditLimit * 1.2,
            max: creditLimit * 0.5,
          );

          return {
            'id': const Uuid().v4(),
            'name': 'KMH Bank ${index + 1}',
            'balance': balance,
            'type': 'bank',
            'color':
                '#${PropertyTest.randomInt(min: 0, max: 0xFFFFFF).toRadixString(16).padLeft(6, '0')}',
            'icon': 'account_balance',
            'creditLimit': creditLimit,
            'interestRate': PropertyTest.randomPositiveDouble(min: 1, max: 50),
            'lastInterestDate': PropertyTest.randomDateTime(),
            'accruedInterest': PropertyTest.randomPositiveDouble(
              min: 0,
              max: 10000,
            ),
            'accountNumber': PropertyTest.randomInt(
              min: 100000,
              max: 999999,
            ).toString(),
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
        final kmhAccounts = retrievedWallets
            .where((w) => w.isKmhAccount)
            .toList();

        // Find recommended account
        final recommended = findRecommendedAccount(kmhAccounts);

        // Filter accounts with available credit
        final accountsWithCredit = kmhAccounts
            .where((a) => a.availableCredit > 0)
            .toList();

        // Property: If there are accounts with available credit, recommended should be the one with lowest rate
        if (accountsWithCredit.isNotEmpty) {
          expect(
            recommended,
            isNotNull,
            reason:
                'Should have a recommendation when accounts with credit exist',
          );

          // Find the minimum interest rate among accounts with credit
          final minRate = accountsWithCredit
              .map((a) => a.interestRate ?? double.infinity)
              .reduce((a, b) => a < b ? a : b);

          // Recommended account should have the minimum rate
          expect(
            recommended!.interestRate,
            equals(minRate),
            reason:
                'Recommended account should have the lowest interest rate ($minRate%)',
          );

          // Verify no other account with credit has a lower rate
          for (var account in accountsWithCredit) {
            expect(
              account.interestRate,
              greaterThanOrEqualTo(recommended.interestRate!),
              reason:
                  'No account with credit should have lower rate than recommended',
            );
          }

          // Verify recommended account has available credit
          expect(
            recommended.availableCredit,
            greaterThan(0),
            reason: 'Recommended account must have available credit',
          );
        } else {
          // If no accounts have available credit, recommendation should be null
          expect(
            recommended,
            isNull,
            reason:
                'Should have no recommendation when no accounts have available credit',
          );
        }

        return true;
      },
      iterations: 100,
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description:
          'Property 30: When multiple accounts have the same lowest rate, prefer the one with more available credit',
      generator: () {
        // Generate accounts where some have the same interest rate
        final lowestRate = PropertyTest.randomPositiveDouble(min: 10, max: 20);
        final higherRate =
            lowestRate + PropertyTest.randomPositiveDouble(min: 5, max: 15);

        final accounts = [
          // Account 1: Lowest rate, less available credit
          {
            'id': const Uuid().v4(),
            'name': 'Low Rate - Less Credit',
            'balance': -5000.0,
            'type': 'bank',
            'color': '#FF0000',
            'icon': 'account_balance',
            'creditLimit': 10000.0,
            'interestRate': lowestRate,
            'lastInterestDate': PropertyTest.randomDateTime(),
            'accruedInterest': PropertyTest.randomPositiveDouble(
              min: 0,
              max: 1000,
            ),
            'accountNumber': PropertyTest.randomInt(
              min: 100000,
              max: 999999,
            ).toString(),
          },
          // Account 2: Same lowest rate, more available credit
          {
            'id': const Uuid().v4(),
            'name': 'Low Rate - More Credit',
            'balance': -2000.0,
            'type': 'bank',
            'color': '#00FF00',
            'icon': 'account_balance',
            'creditLimit': 10000.0,
            'interestRate': lowestRate,
            'lastInterestDate': PropertyTest.randomDateTime(),
            'accruedInterest': PropertyTest.randomPositiveDouble(
              min: 0,
              max: 1000,
            ),
            'accountNumber': PropertyTest.randomInt(
              min: 100000,
              max: 999999,
            ).toString(),
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
            'interestRate': higherRate,
            'lastInterestDate': PropertyTest.randomDateTime(),
            'accruedInterest': PropertyTest.randomPositiveDouble(
              min: 0,
              max: 1000,
            ),
            'accountNumber': PropertyTest.randomInt(
              min: 100000,
              max: 999999,
            ).toString(),
          },
        ];

        return {'accounts': accounts, 'lowestRate': lowestRate};
      },
      property: (data) async {
        // Clear wallets before each iteration
        final prefs = await dataService.getPrefs();
        await prefs.setString('wallets', '[]');
        await dataService.saveWallets([]);

        final accountsData = data['accounts'] as List<Map<String, dynamic>>;
        final lowestRate = data['lowestRate'] as double;

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
        final kmhAccounts = retrievedWallets
            .where((w) => w.isKmhAccount)
            .toList();

        // Find recommended account
        final recommended = findRecommendedAccount(kmhAccounts);

        expect(recommended, isNotNull, reason: 'Should have a recommendation');

        // Property: Recommended should have the lowest rate
        expect(
          recommended!.interestRate,
          equals(lowestRate),
          reason: 'Recommended should have the lowest rate',
        );

        // Property: Among accounts with same lowest rate, should prefer more available credit
        final accountsWithLowestRate = kmhAccounts
            .where((a) => a.interestRate == lowestRate && a.availableCredit > 0)
            .toList();

        if (accountsWithLowestRate.length > 1) {
          // Find max available credit among accounts with lowest rate
          final maxCredit = accountsWithLowestRate
              .map((a) => a.availableCredit)
              .reduce((a, b) => a > b ? a : b);

          expect(
            recommended.availableCredit,
            equals(maxCredit),
            reason:
                'Among accounts with same rate, should prefer more available credit',
          );
        }

        return true;
      },
      iterations: 100,
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description:
          'Property 30: Accounts without available credit should never be recommended',
      generator: () {
        final accounts = [
          // Account 1: Lowest rate but no available credit
          {
            'id': const Uuid().v4(),
            'name': 'Lowest Rate - No Credit',
            'balance': -10000.0,
            'type': 'bank',
            'color': '#FF0000',
            'icon': 'account_balance',
            'creditLimit': 10000.0,
            'interestRate': PropertyTest.randomPositiveDouble(min: 5, max: 15),
            'lastInterestDate': PropertyTest.randomDateTime(),
            'accruedInterest': PropertyTest.randomPositiveDouble(
              min: 0,
              max: 5000,
            ),
            'accountNumber': PropertyTest.randomInt(
              min: 100000,
              max: 999999,
            ).toString(),
          },
          // Account 2: Higher rate but has available credit
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
            'accruedInterest': PropertyTest.randomPositiveDouble(
              min: 0,
              max: 3000,
            ),
            'accountNumber': PropertyTest.randomInt(
              min: 100000,
              max: 999999,
            ).toString(),
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
        final kmhAccounts = retrievedWallets
            .where((w) => w.isKmhAccount)
            .toList();

        // Find recommended account
        final recommended = findRecommendedAccount(kmhAccounts);

        // Find the account with no credit
        final noCredit = kmhAccounts.firstWhere(
          (a) => a.name == 'Lowest Rate - No Credit',
        );
        final hasCredit = kmhAccounts.firstWhere(
          (a) => a.name == 'Higher Rate - Has Credit',
        );

        // Verify the no-credit account has no available credit
        expect(
          noCredit.availableCredit,
          lessThanOrEqualTo(0),
          reason: 'Test setup: first account should have no available credit',
        );

        // Verify the has-credit account has available credit
        expect(
          hasCredit.availableCredit,
          greaterThan(0),
          reason: 'Test setup: second account should have available credit',
        );

        // Property: Recommended should NOT be the account without credit
        expect(recommended, isNotNull, reason: 'Should have a recommendation');
        expect(
          recommended!.id,
          isNot(equals(noCredit.id)),
          reason:
              'Account without available credit should never be recommended',
        );

        // Property: Recommended should be the account with credit
        expect(
          recommended.id,
          equals(hasCredit.id),
          reason: 'Should recommend the account with available credit',
        );

        return true;
      },
      iterations: 100,
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description:
          'Property 30: When all accounts have no available credit, recommendation should be null',
      generator: () {
        final accountCount = PropertyTest.randomInt(min: 2, max: 5);

        final accounts = List.generate(accountCount, (index) {
          final creditLimit = PropertyTest.randomPositiveDouble(
            min: 1000,
            max: 50000,
          );
          // All accounts at or over their limit
          final balance =
              -creditLimit -
              PropertyTest.randomPositiveDouble(min: 0, max: 5000);

          return {
            'id': const Uuid().v4(),
            'name': 'Maxed Out Bank ${index + 1}',
            'balance': balance,
            'type': 'bank',
            'color':
                '#${PropertyTest.randomInt(min: 0, max: 0xFFFFFF).toRadixString(16).padLeft(6, '0')}',
            'icon': 'account_balance',
            'creditLimit': creditLimit,
            'interestRate': PropertyTest.randomPositiveDouble(min: 1, max: 50),
            'lastInterestDate': PropertyTest.randomDateTime(),
            'accruedInterest': PropertyTest.randomPositiveDouble(
              min: 0,
              max: 10000,
            ),
            'accountNumber': PropertyTest.randomInt(
              min: 100000,
              max: 999999,
            ).toString(),
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
        final kmhAccounts = retrievedWallets
            .where((w) => w.isKmhAccount)
            .toList();

        // Verify all accounts have no available credit
        for (var account in kmhAccounts) {
          expect(
            account.availableCredit,
            lessThanOrEqualTo(0),
            reason: 'Test setup: all accounts should have no available credit',
          );
        }

        // Find recommended account
        final recommended = findRecommendedAccount(kmhAccounts);

        // Property: When no accounts have available credit, recommendation should be null
        expect(
          recommended,
          isNull,
          reason:
              'Should have no recommendation when all accounts are maxed out',
        );

        return true;
      },
      iterations: 100,
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description:
          'Property 30: Recommendation should be stable across multiple calls with same data',
      generator: () {
        final accountCount = PropertyTest.randomInt(min: 3, max: 8);

        final accounts = List.generate(accountCount, (index) {
          final creditLimit = PropertyTest.randomPositiveDouble(
            min: 1000,
            max: 100000,
          );
          final balance = PropertyTest.randomDouble(
            min: -creditLimit * 0.8,
            max: creditLimit * 0.3,
          );

          return {
            'id': const Uuid().v4(),
            'name': 'KMH Bank ${index + 1}',
            'balance': balance,
            'type': 'bank',
            'color':
                '#${PropertyTest.randomInt(min: 0, max: 0xFFFFFF).toRadixString(16).padLeft(6, '0')}',
            'icon': 'account_balance',
            'creditLimit': creditLimit,
            'interestRate': PropertyTest.randomPositiveDouble(min: 1, max: 50),
            'lastInterestDate': PropertyTest.randomDateTime(),
            'accruedInterest': PropertyTest.randomPositiveDouble(
              min: 0,
              max: 10000,
            ),
            'accountNumber': PropertyTest.randomInt(
              min: 100000,
              max: 999999,
            ).toString(),
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
        final kmhAccounts = retrievedWallets
            .where((w) => w.isKmhAccount)
            .toList();

        // Find recommended account multiple times
        final recommended1 = findRecommendedAccount(kmhAccounts);
        final recommended2 = findRecommendedAccount(kmhAccounts);
        final recommended3 = findRecommendedAccount(kmhAccounts);

        // Property: Recommendation should be stable (same result each time)
        if (recommended1 != null) {
          expect(
            recommended2,
            isNotNull,
            reason: 'Recommendation should be consistent',
          );
          expect(
            recommended3,
            isNotNull,
            reason: 'Recommendation should be consistent',
          );

          expect(
            recommended2!.id,
            equals(recommended1.id),
            reason: 'Same recommendation should be returned on second call',
          );
          expect(
            recommended3!.id,
            equals(recommended1.id),
            reason: 'Same recommendation should be returned on third call',
          );
        } else {
          expect(
            recommended2,
            isNull,
            reason: 'Null recommendation should be consistent',
          );
          expect(
            recommended3,
            isNull,
            reason: 'Null recommendation should be consistent',
          );
        }

        return true;
      },
      iterations: 100,
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description:
          'Property 30: Recommendation logic should handle edge case interest rates (0%, very high %)',
      generator: () {
        final accounts = [
          // Account with 0% interest rate (edge case)
          {
            'id': const Uuid().v4(),
            'name': 'Zero Interest Account',
            'balance': PropertyTest.randomDouble(min: -5000, max: 5000),
            'type': 'bank',
            'color': '#FF0000',
            'icon': 'account_balance',
            'creditLimit': PropertyTest.randomPositiveDouble(
              min: 10000,
              max: 50000,
            ),
            'interestRate': 0.0,
            'lastInterestDate': PropertyTest.randomDateTime(),
            'accruedInterest': 0.0,
            'accountNumber': PropertyTest.randomInt(
              min: 100000,
              max: 999999,
            ).toString(),
          },
          // Account with very high interest rate
          {
            'id': const Uuid().v4(),
            'name': 'High Interest Account',
            'balance': PropertyTest.randomDouble(min: -5000, max: 5000),
            'type': 'bank',
            'color': '#00FF00',
            'icon': 'account_balance',
            'creditLimit': PropertyTest.randomPositiveDouble(
              min: 10000,
              max: 50000,
            ),
            'interestRate': PropertyTest.randomPositiveDouble(
              min: 80,
              max: 100,
            ),
            'lastInterestDate': PropertyTest.randomDateTime(),
            'accruedInterest': PropertyTest.randomPositiveDouble(
              min: 0,
              max: 10000,
            ),
            'accountNumber': PropertyTest.randomInt(
              min: 100000,
              max: 999999,
            ).toString(),
          },
          // Account with normal interest rate
          {
            'id': const Uuid().v4(),
            'name': 'Normal Interest Account',
            'balance': PropertyTest.randomDouble(min: -5000, max: 5000),
            'type': 'bank',
            'color': '#0000FF',
            'icon': 'account_balance',
            'creditLimit': PropertyTest.randomPositiveDouble(
              min: 10000,
              max: 50000,
            ),
            'interestRate': PropertyTest.randomPositiveDouble(min: 15, max: 30),
            'lastInterestDate': PropertyTest.randomDateTime(),
            'accruedInterest': PropertyTest.randomPositiveDouble(
              min: 0,
              max: 5000,
            ),
            'accountNumber': PropertyTest.randomInt(
              min: 100000,
              max: 999999,
            ).toString(),
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
        final kmhAccounts = retrievedWallets
            .where((w) => w.isKmhAccount)
            .toList();

        // Find recommended account
        final recommended = findRecommendedAccount(kmhAccounts);

        // Find accounts with available credit
        final accountsWithCredit = kmhAccounts
            .where((a) => a.availableCredit > 0)
            .toList();

        if (accountsWithCredit.isNotEmpty) {
          expect(
            recommended,
            isNotNull,
            reason:
                'Should have a recommendation when accounts with credit exist',
          );

          // Find the zero interest account
          final zeroInterestAccount = kmhAccounts.firstWhere(
            (a) => a.name == 'Zero Interest Account',
          );

          // Property: If zero interest account has available credit, it should be recommended
          if (zeroInterestAccount.availableCredit > 0) {
            expect(
              recommended!.id,
              equals(zeroInterestAccount.id),
              reason:
                  'Zero interest account should be recommended when it has available credit',
            );
            expect(
              recommended.interestRate,
              equals(0.0),
              reason: 'Recommended account should have 0% interest rate',
            );
          }

          // Property: Recommended account should have the minimum rate
          final minRate = accountsWithCredit
              .map((a) => a.interestRate ?? double.infinity)
              .reduce((a, b) => a < b ? a : b);

          expect(
            recommended!.interestRate,
            equals(minRate),
            reason: 'Recommended account should have the minimum interest rate',
          );
        }

        return true;
      },
      iterations: 100,
    );
  });
}
