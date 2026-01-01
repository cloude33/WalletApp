import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:parion/models/wallet.dart';
import 'package:parion/services/data_service.dart';
import 'package:parion/services/kmh_interest_calculator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../property_test_utils.dart';
import 'package:uuid/uuid.dart';

/// **Feature: kmh-account-management, Property 29: Hesap Karşılaştırma Metrikleri**
/// **Validates: Requirements 8.2**
///
/// Property: For any set of KMH accounts, each account's interest rate,
/// utilization rate, and monthly interest cost should be calculated correctly.
void main() {
  group('KMH Account Comparison Metrics Property Tests', () {
    late DataService dataService;
    late KmhInterestCalculator calculator;
    late Directory testDir;

    setUpAll(() async {
      // Create a temporary directory for testing
      testDir = await Directory.systemTemp.createTemp('kmh_comparison_test_');

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
      description:
          'Property 29: Interest rate should be correctly stored and retrieved for each KMH account',
      generator: () {
        final accountCount = PropertyTest.randomInt(min: 1, max: 10);

        final accounts = List.generate(accountCount, (index) {
          return {
            'id': const Uuid().v4(),
            'name':
                'KMH Bank ${index + 1} - ${PropertyTest.randomString(minLength: 5, maxLength: 15)}',
            'balance': PropertyTest.randomDouble(min: -50000, max: 50000),
            'type': 'bank',
            'color':
                '#${PropertyTest.randomInt(min: 0, max: 0xFFFFFF).toRadixString(16).padLeft(6, '0')}',
            'icon': 'account_balance',
            'creditLimit': PropertyTest.randomPositiveDouble(
              min: 1000,
              max: 100000,
            ),
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

        // Property: Each account's interest rate should match the original
        for (var accountData in accountsData) {
          final retrieved = kmhAccounts.firstWhere(
            (w) => w.id == accountData['id'],
          );
          expect(
            retrieved.interestRate,
            equals(accountData['interestRate']),
            reason:
                'Interest rate for account ${accountData['id']} should be preserved',
          );
        }

        return true;
      },
      iterations: 100,
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description:
          'Property 29: Utilization rate should be correctly calculated for each KMH account',
      generator: () {
        final accountCount = PropertyTest.randomInt(min: 1, max: 10);

        final accounts = List.generate(accountCount, (index) {
          final creditLimit = PropertyTest.randomPositiveDouble(
            min: 1000,
            max: 100000,
          );
          // Generate balance that may or may not exceed the limit
          final balance = PropertyTest.randomDouble(
            min: -creditLimit * 1.5,
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

        // Property: Utilization rate should be correctly calculated
        // Formula: (usedCredit / creditLimit) × 100
        for (var accountData in accountsData) {
          final retrieved = kmhAccounts.firstWhere(
            (w) => w.id == accountData['id'],
          );

          final expectedUsedCredit = accountData['balance'] < 0
              ? (accountData['balance'] as double).abs()
              : 0.0;

          final expectedUtilizationRate = accountData['creditLimit'] > 0
              ? (expectedUsedCredit / accountData['creditLimit']) * 100
              : 0.0;

          // Check usedCredit
          expect(retrieved.usedCredit, closeTo(expectedUsedCredit, 0.01));

          // Check utilizationRate
          expect(
            retrieved.utilizationRate,
            closeTo(expectedUtilizationRate, 0.01),
          );
        }

        return true;
      },
      iterations: 100,
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description:
          'Property 29: Monthly interest cost should be correctly calculated for each KMH account',
      generator: () {
        final accountCount = PropertyTest.randomInt(min: 1, max: 10);

        final accounts = List.generate(accountCount, (index) {
          return {
            'id': const Uuid().v4(),
            'name': 'KMH Bank ${index + 1}',
            'balance': PropertyTest.randomDouble(min: -50000, max: 50000),
            'type': 'bank',
            'color':
                '#${PropertyTest.randomInt(min: 0, max: 0xFFFFFF).toRadixString(16).padLeft(6, '0')}',
            'icon': 'account_balance',
            'creditLimit': PropertyTest.randomPositiveDouble(
              min: 1000,
              max: 100000,
            ),
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

        // Property: Monthly interest cost should be correctly calculated
        for (var accountData in accountsData) {
          final retrieved = kmhAccounts.firstWhere(
            (w) => w.id == accountData['id'],
          );

          // Calculate expected monthly interest using the calculator
          final expectedMonthlyInterest = calculator.estimateMonthlyInterest(
            balance: accountData['balance'],
            annualRate: accountData['interestRate'],
          );

          // Calculate actual monthly interest
          final actualMonthlyInterest = calculator.estimateMonthlyInterest(
            balance: retrieved.balance,
            annualRate: retrieved.interestRate!,
          );

          // They should match
          expect(actualMonthlyInterest, closeTo(expectedMonthlyInterest, 0.01));

          // If balance is positive, interest should be 0
          if (accountData['balance'] >= 0) {
            expect(
              actualMonthlyInterest,
              equals(0.0),
              reason:
                  'Positive balance accounts should have 0 monthly interest',
            );
          }

          // If balance is negative, interest should be positive
          if (accountData['balance'] < 0) {
            expect(
              actualMonthlyInterest,
              greaterThan(0.0),
              reason:
                  'Negative balance accounts should have positive monthly interest',
            );
          }
        }

        return true;
      },
      iterations: 100,
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description:
          'Property 29: All three metrics (interest rate, utilization, monthly interest) should be consistent',
      generator: () {
        final accountCount = PropertyTest.randomInt(min: 2, max: 8);

        final accounts = List.generate(accountCount, (index) {
          final creditLimit = PropertyTest.randomPositiveDouble(
            min: 1000,
            max: 100000,
          );
          final balance = PropertyTest.randomDouble(
            min: -creditLimit,
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

        // Property: All metrics should be consistent for each account
        for (var accountData in accountsData) {
          final retrieved = kmhAccounts.firstWhere(
            (w) => w.id == accountData['id'],
          );

          // 1. Interest rate should be preserved
          expect(retrieved.interestRate, equals(accountData['interestRate']));

          // 2. Utilization rate should be correctly calculated
          final expectedUsedCredit = accountData['balance'] < 0
              ? (accountData['balance'] as double).abs()
              : 0.0;
          final expectedUtilizationRate = accountData['creditLimit'] > 0
              ? (expectedUsedCredit / accountData['creditLimit']) * 100
              : 0.0;
          expect(
            retrieved.utilizationRate,
            closeTo(expectedUtilizationRate, 0.01),
          );

          // 3. Monthly interest should be correctly calculated
          final expectedMonthlyInterest = calculator.estimateMonthlyInterest(
            balance: accountData['balance'],
            annualRate: accountData['interestRate'],
          );
          final actualMonthlyInterest = calculator.estimateMonthlyInterest(
            balance: retrieved.balance,
            annualRate: retrieved.interestRate!,
          );
          expect(actualMonthlyInterest, closeTo(expectedMonthlyInterest, 0.01));

          // 4. Consistency check: If utilization is 0, monthly interest should be 0
          if (retrieved.utilizationRate == 0.0) {
            expect(
              actualMonthlyInterest,
              equals(0.0),
              reason: 'Zero utilization should mean zero monthly interest',
            );
          }

          // 5. Consistency check: Higher utilization with same rate should mean higher interest
          // (This is implicitly tested by the formula, but we verify the relationship)
          if (retrieved.balance < 0) {
            final higherDebt = retrieved.balance * 2;
            final higherInterest = calculator.estimateMonthlyInterest(
              balance: higherDebt,
              annualRate: retrieved.interestRate!,
            );
            expect(
              higherInterest,
              greaterThan(actualMonthlyInterest),
              reason: 'Higher debt should result in higher interest',
            );
          }
        }

        return true;
      },
      iterations: 100,
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description:
          'Property 29: Comparison metrics should handle edge cases (zero balance, max limit)',
      generator: () {
        // Generate accounts with edge case values
        final accounts = [
          // Account with zero balance
          {
            'id': const Uuid().v4(),
            'name': 'Zero Balance Account',
            'balance': 0.0,
            'type': 'bank',
            'color': '#FF0000',
            'icon': 'account_balance',
            'creditLimit': PropertyTest.randomPositiveDouble(
              min: 1000,
              max: 100000,
            ),
            'interestRate': PropertyTest.randomPositiveDouble(min: 1, max: 50),
            'lastInterestDate': PropertyTest.randomDateTime(),
            'accruedInterest': 0.0,
            'accountNumber': PropertyTest.randomInt(
              min: 100000,
              max: 999999,
            ).toString(),
          },
          // Account with maximum negative balance (at limit)
          {
            'id': const Uuid().v4(),
            'name': 'Max Limit Account',
            'balance': -10000.0,
            'type': 'bank',
            'color': '#00FF00',
            'icon': 'account_balance',
            'creditLimit': 10000.0,
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
          },
          // Account with positive balance
          {
            'id': const Uuid().v4(),
            'name': 'Positive Balance Account',
            'balance': PropertyTest.randomPositiveDouble(min: 1, max: 50000),
            'type': 'bank',
            'color': '#0000FF',
            'icon': 'account_balance',
            'creditLimit': PropertyTest.randomPositiveDouble(
              min: 1000,
              max: 100000,
            ),
            'interestRate': PropertyTest.randomPositiveDouble(min: 1, max: 50),
            'lastInterestDate': PropertyTest.randomDateTime(),
            'accruedInterest': 0.0,
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

        // Find specific edge case accounts
        final zeroBalanceAccount = kmhAccounts.firstWhere(
          (w) => w.name == 'Zero Balance Account',
        );
        final maxLimitAccount = kmhAccounts.firstWhere(
          (w) => w.name == 'Max Limit Account',
        );
        final positiveBalanceAccount = kmhAccounts.firstWhere(
          (w) => w.name == 'Positive Balance Account',
        );

        // Test zero balance account
        expect(
          zeroBalanceAccount.usedCredit,
          equals(0.0),
          reason: 'Zero balance should have zero used credit',
        );
        expect(
          zeroBalanceAccount.utilizationRate,
          equals(0.0),
          reason: 'Zero balance should have zero utilization rate',
        );
        final zeroInterest = calculator.estimateMonthlyInterest(
          balance: zeroBalanceAccount.balance,
          annualRate: zeroBalanceAccount.interestRate!,
        );
        expect(
          zeroInterest,
          equals(0.0),
          reason: 'Zero balance should have zero monthly interest',
        );

        // Test max limit account (100% utilization)
        expect(
          maxLimitAccount.utilizationRate,
          closeTo(100.0, 0.01),
          reason: 'Account at limit should have 100% utilization',
        );
        expect(
          maxLimitAccount.availableCredit,
          closeTo(0.0, 0.01),
          reason: 'Account at limit should have zero available credit',
        );
        final maxInterest = calculator.estimateMonthlyInterest(
          balance: maxLimitAccount.balance,
          annualRate: maxLimitAccount.interestRate!,
        );
        expect(
          maxInterest,
          greaterThan(0.0),
          reason: 'Account at limit should have positive monthly interest',
        );

        // Test positive balance account
        expect(
          positiveBalanceAccount.usedCredit,
          equals(0.0),
          reason: 'Positive balance should have zero used credit',
        );
        expect(
          positiveBalanceAccount.utilizationRate,
          equals(0.0),
          reason: 'Positive balance should have zero utilization rate',
        );
        final positiveInterest = calculator.estimateMonthlyInterest(
          balance: positiveBalanceAccount.balance,
          annualRate: positiveBalanceAccount.interestRate!,
        );
        expect(
          positiveInterest,
          equals(0.0),
          reason: 'Positive balance should have zero monthly interest',
        );
        expect(
          positiveBalanceAccount.availableCredit,
          equals(
            positiveBalanceAccount.creditLimit + positiveBalanceAccount.balance,
          ),
          reason: 'Available credit should be limit + positive balance',
        );

        return true;
      },
      iterations: 100,
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description:
          'Property 29: Metrics should be independent of account order',
      generator: () {
        final accountCount = PropertyTest.randomInt(min: 3, max: 8);

        final accounts = List.generate(accountCount, (index) {
          return {
            'id': const Uuid().v4(),
            'name': 'KMH Bank ${index + 1}',
            'balance': PropertyTest.randomDouble(min: -50000, max: 50000),
            'type': 'bank',
            'color':
                '#${PropertyTest.randomInt(min: 0, max: 0xFFFFFF).toRadixString(16).padLeft(6, '0')}',
            'icon': 'account_balance',
            'creditLimit': PropertyTest.randomPositiveDouble(
              min: 1000,
              max: 100000,
            ),
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

        // Retrieve and calculate metrics
        final retrievedWallets1 = await dataService.getWallets();
        final kmhAccounts1 = retrievedWallets1
            .where((w) => w.isKmhAccount)
            .toList();

        // Store metrics for first retrieval
        final metrics1 = <String, Map<String, double>>{};
        for (var account in kmhAccounts1) {
          metrics1[account.id] = {
            'interestRate': account.interestRate!,
            'utilizationRate': account.utilizationRate,
            'monthlyInterest': calculator.estimateMonthlyInterest(
              balance: account.balance,
              annualRate: account.interestRate!,
            ),
          };
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

        // Retrieve and calculate metrics again
        final retrievedWallets2 = await dataService.getWallets();
        final kmhAccounts2 = retrievedWallets2
            .where((w) => w.isKmhAccount)
            .toList();

        // Property: Metrics should be the same regardless of order
        for (var account in kmhAccounts2) {
          final metrics2 = {
            'interestRate': account.interestRate!,
            'utilizationRate': account.utilizationRate,
            'monthlyInterest': calculator.estimateMonthlyInterest(
              balance: account.balance,
              annualRate: account.interestRate!,
            ),
          };

          final originalMetrics = metrics1[account.id]!;

          expect(
            metrics2['interestRate'],
            equals(originalMetrics['interestRate']),
            reason: 'Interest rate should be same regardless of order',
          );
          expect(
            metrics2['utilizationRate'],
            closeTo(originalMetrics['utilizationRate']!, 0.01),
            reason: 'Utilization rate should be same regardless of order',
          );
          expect(
            metrics2['monthlyInterest'],
            closeTo(originalMetrics['monthlyInterest']!, 0.01),
            reason: 'Monthly interest should be same regardless of order',
          );
        }

        return true;
      },
      iterations: 100,
    );
  });
}
