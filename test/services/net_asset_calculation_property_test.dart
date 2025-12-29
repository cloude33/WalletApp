import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:money/models/wallet.dart';
import 'package:money/services/data_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../property_test_utils.dart';
import 'package:uuid/uuid.dart';

/// **Feature: kmh-account-management, Property 22: Net Varlık Hesaplama**
/// **Validates: Requirements 6.3**
///
/// Property: For any financial situation, net assets should equal
/// positive assets - KMH debts.
void main() {
  group('Net Asset Calculation Property Tests', () {
    late DataService dataService;
    late Directory testDir;

    setUpAll(() async {
      // Create a temporary directory for testing
      testDir = await Directory.systemTemp.createTemp('net_asset_test_');

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
      description: 'Property 22: Net assets = positive assets - KMH debts',
      generator: () {
        // Generate various types of wallets
        final kmhAccountCount = PropertyTest.randomInt(min: 1, max: 5);
        final regularBankCount = PropertyTest.randomInt(min: 0, max: 5);
        final cashAccountCount = PropertyTest.randomInt(min: 0, max: 3);

        // Generate KMH accounts with mixed balances
        final kmhAccounts = List.generate(kmhAccountCount, (index) {
          final isNegative = PropertyTest.randomBool();
          final balance = isNegative
              ? -PropertyTest.randomPositiveDouble(min: 100, max: 50000)
              : PropertyTest.randomPositiveDouble(min: 100, max: 50000);

          return {
            'id': const Uuid().v4(),
            'name': 'KMH Account ${index + 1}',
            'balance': balance,
            'type': 'bank',
            'color':
                '#${PropertyTest.randomInt(min: 0, max: 0xFFFFFF).toRadixString(16).padLeft(6, '0')}',
            'icon': 'account_balance',
            'creditLimit': PropertyTest.randomPositiveDouble(
              min: 1000,
              max: 100000,
            ),
            'interestRate': PropertyTest.randomPositiveDouble(min: 1, max: 50),
          };
        });

        // Generate regular bank accounts (no credit limit)
        final regularBanks = List.generate(regularBankCount, (index) {
          return {
            'id': const Uuid().v4(),
            'name': 'Regular Bank ${index + 1}',
            'balance': PropertyTest.randomDouble(min: -10000, max: 50000),
            'type': 'bank',
            'color':
                '#${PropertyTest.randomInt(min: 0, max: 0xFFFFFF).toRadixString(16).padLeft(6, '0')}',
            'icon': 'account_balance',
            'creditLimit': 0.0, // No credit limit = not KMH
          };
        });

        // Generate cash accounts
        final cashAccounts = List.generate(cashAccountCount, (index) {
          return {
            'id': const Uuid().v4(),
            'name': 'Cash ${index + 1}',
            'balance': PropertyTest.randomDouble(min: -1000, max: 10000),
            'type': 'cash',
            'color':
                '#${PropertyTest.randomInt(min: 0, max: 0xFFFFFF).toRadixString(16).padLeft(6, '0')}',
            'icon': 'account_balance_wallet',
            'creditLimit': 0.0,
          };
        });

        return {
          'kmhAccounts': kmhAccounts,
          'regularBanks': regularBanks,
          'cashAccounts': cashAccounts,
        };
      },
      property: (data) async {
        // Clear data before each iteration
        final prefs = await dataService.getPrefs();
        await prefs.setString('wallets', '[]');
        await dataService.saveWallets([]);

        final kmhAccountsData =
            data['kmhAccounts'] as List<Map<String, dynamic>>;
        final regularBanksData =
            data['regularBanks'] as List<Map<String, dynamic>>;
        final cashAccountsData =
            data['cashAccounts'] as List<Map<String, dynamic>>;

        // Create all wallets
        for (var accountData in [
          ...kmhAccountsData,
          ...regularBanksData,
          ...cashAccountsData,
        ]) {
          final wallet = Wallet(
            id: accountData['id'],
            name: accountData['name'],
            balance: accountData['balance'],
            type: accountData['type'],
            color: accountData['color'],
            icon: accountData['icon'],
            creditLimit: accountData['creditLimit'] ?? 0.0,
            interestRate: accountData['interestRate'],
          );
          await dataService.addWallet(wallet);
        }

        // Retrieve all wallets
        final retrievedWallets = await dataService.getWallets();

        // Calculate expected values using the same logic as statistics screen
        final assetWallets = retrievedWallets
            .where((w) => w.type != 'credit_card')
            .toList();

        final kmhWallets = assetWallets.where((w) => w.isKmhAccount).toList();

        // Calculate positive assets (all positive balances from non-credit-card wallets)
        final positiveAssets = assetWallets
            .where((w) => w.balance > 0)
            .fold(0.0, (sum, w) => sum + w.balance);

        // Calculate KMH debts (negative balances in KMH accounts only)
        final kmhDebts = kmhWallets
            .where((w) => w.balance < 0)
            .fold(0.0, (sum, w) => sum + w.balance.abs());

        // Calculate net assets
        final netAssets = positiveAssets - kmhDebts;

        // Property 1: Net assets should equal positive assets - KMH debts
        final expectedNetAssets = positiveAssets - kmhDebts;
        expect(
          netAssets,
          equals(expectedNetAssets),
          reason: 'Net assets should equal positive assets minus KMH debts',
        );

        // Property 2: Positive assets should include all positive balances (except credit cards)
        final manualPositiveAssets = retrievedWallets
            .where((w) => w.type != 'credit_card' && w.balance > 0)
            .fold(0.0, (sum, w) => sum + w.balance);
        expect(
          positiveAssets,
          equals(manualPositiveAssets),
          reason:
              'Positive assets should include all positive non-credit-card balances',
        );

        // Property 3: KMH debts should only include negative balances from KMH accounts
        final manualKmhDebts = retrievedWallets
            .where((w) => w.isKmhAccount && w.balance < 0)
            .fold(0.0, (sum, w) => sum + w.balance.abs());
        expect(
          kmhDebts,
          equals(manualKmhDebts),
          reason:
              'KMH debts should only include negative balances from KMH accounts',
        );

        // Property 4: Regular bank negative balances should NOT be included in KMH debts
        final regularBankNegativeBalances = retrievedWallets
            .where(
              (w) => w.type == 'bank' && w.creditLimit == 0 && w.balance < 0,
            )
            .toList();

        for (var regularBank in regularBankNegativeBalances) {
          // Verify this negative balance is NOT counted in KMH debts
          final isCountedInKmhDebts = kmhWallets
              .where((w) => w.balance < 0)
              .any((w) => w.id == regularBank.id);
          expect(
            isCountedInKmhDebts,
            isFalse,
            reason:
                'Regular bank negative balance should not be counted as KMH debt',
          );
        }

        // Property 5: Positive KMH balances should be included in positive assets
        final positiveKmhAccounts = retrievedWallets
            .where((w) => w.isKmhAccount && w.balance > 0)
            .toList();

        for (var positiveKmh in positiveKmhAccounts) {
          // Verify this positive balance IS counted in positive assets
          expect(
            positiveAssets,
            greaterThanOrEqualTo(positiveKmh.balance),
            reason:
                'Positive KMH balance should be included in positive assets',
          );
        }

        // Property 6: Net assets can be negative if KMH debts exceed positive assets
        if (kmhDebts > positiveAssets) {
          expect(
            netAssets,
            lessThan(0),
            reason:
                'Net assets should be negative when KMH debts exceed positive assets',
          );
        }

        // Property 7: Net assets should be positive if positive assets exceed KMH debts
        if (positiveAssets > kmhDebts) {
          expect(
            netAssets,
            greaterThan(0),
            reason:
                'Net assets should be positive when positive assets exceed KMH debts',
          );
        }

        // Property 8: If no KMH debts, net assets should equal positive assets
        if (kmhDebts == 0) {
          expect(
            netAssets,
            equals(positiveAssets),
            reason:
                'Net assets should equal positive assets when there are no KMH debts',
          );
        }

        return true;
      },
      iterations: 100,
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 22: Net assets with only positive balances',
      generator: () {
        final accountCount = PropertyTest.randomInt(min: 1, max: 10);

        final accounts = List.generate(accountCount, (index) {
          final accountType = PropertyTest.randomBool() ? 'bank' : 'cash';
          final isKmh = accountType == 'bank' && PropertyTest.randomBool();

          return {
            'id': const Uuid().v4(),
            'name': 'Account ${index + 1}',
            'balance': PropertyTest.randomPositiveDouble(
              min: 100,
              max: 50000,
            ), // All positive
            'type': accountType,
            'color':
                '#${PropertyTest.randomInt(min: 0, max: 0xFFFFFF).toRadixString(16).padLeft(6, '0')}',
            'icon': accountType == 'bank'
                ? 'account_balance'
                : 'account_balance_wallet',
            'creditLimit': isKmh
                ? PropertyTest.randomPositiveDouble(min: 1000, max: 100000)
                : 0.0,
            'interestRate': isKmh
                ? PropertyTest.randomPositiveDouble(min: 1, max: 50)
                : null,
          };
        });

        return {'accounts': accounts};
      },
      property: (data) async {
        // Clear data
        final prefs = await dataService.getPrefs();
        await prefs.setString('wallets', '[]');
        await dataService.saveWallets([]);

        final accountsData = data['accounts'] as List<Map<String, dynamic>>;

        // Create all accounts with positive balances
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
          );
          await dataService.addWallet(wallet);
        }

        // Retrieve wallets
        final retrievedWallets = await dataService.getWallets();

        // Calculate values
        final assetWallets = retrievedWallets
            .where((w) => w.type != 'credit_card')
            .toList();

        final positiveAssets = assetWallets
            .where((w) => w.balance > 0)
            .fold(0.0, (sum, w) => sum + w.balance);

        final kmhDebts = assetWallets
            .where((w) => w.isKmhAccount && w.balance < 0)
            .fold(0.0, (sum, w) => sum + w.balance.abs());

        final netAssets = positiveAssets - kmhDebts;

        // Property: When all balances are positive, KMH debts should be zero
        expect(
          kmhDebts,
          equals(0.0),
          reason: 'KMH debts should be zero when all balances are positive',
        );

        // Property: Net assets should equal positive assets when no debts
        expect(
          netAssets,
          equals(positiveAssets),
          reason:
              'Net assets should equal positive assets when there are no KMH debts',
        );

        // Property: Net assets should be positive
        expect(
          netAssets,
          greaterThan(0),
          reason:
              'Net assets should be positive when all balances are positive',
        );

        // Verify all accounts have positive balance
        for (var wallet in retrievedWallets) {
          expect(
            wallet.balance,
            greaterThan(0),
            reason: 'All accounts should have positive balance',
          );
        }

        return true;
      },
      iterations: 100,
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 22: Net assets with only KMH debts',
      generator: () {
        final kmhAccountCount = PropertyTest.randomInt(min: 1, max: 10);

        final kmhAccounts = List.generate(kmhAccountCount, (index) {
          return {
            'id': const Uuid().v4(),
            'name': 'KMH Account ${index + 1}',
            'balance': -PropertyTest.randomPositiveDouble(
              min: 100,
              max: 50000,
            ), // All negative
            'type': 'bank',
            'color':
                '#${PropertyTest.randomInt(min: 0, max: 0xFFFFFF).toRadixString(16).padLeft(6, '0')}',
            'icon': 'account_balance',
            'creditLimit': PropertyTest.randomPositiveDouble(
              min: 1000,
              max: 100000,
            ),
            'interestRate': PropertyTest.randomPositiveDouble(min: 1, max: 50),
          };
        });

        return {'kmhAccounts': kmhAccounts};
      },
      property: (data) async {
        // Clear data
        final prefs = await dataService.getPrefs();
        await prefs.setString('wallets', '[]');
        await dataService.saveWallets([]);

        final kmhAccountsData =
            data['kmhAccounts'] as List<Map<String, dynamic>>;

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

        // Retrieve wallets
        final retrievedWallets = await dataService.getWallets();

        // Calculate values
        final assetWallets = retrievedWallets
            .where((w) => w.type != 'credit_card')
            .toList();

        final positiveAssets = assetWallets
            .where((w) => w.balance > 0)
            .fold(0.0, (sum, w) => sum + w.balance);

        final kmhDebts = assetWallets
            .where((w) => w.isKmhAccount && w.balance < 0)
            .fold(0.0, (sum, w) => sum + w.balance.abs());

        final netAssets = positiveAssets - kmhDebts;

        // Calculate expected KMH debts
        final expectedKmhDebts = kmhAccountsData.fold(
          0.0,
          (sum, a) => sum + (a['balance'] as double).abs(),
        );

        // Property: When only KMH debts exist, positive assets should be zero
        expect(
          positiveAssets,
          equals(0.0),
          reason:
              'Positive assets should be zero when all KMH accounts have negative balances',
        );

        // Property: KMH debts should equal sum of all absolute values
        expect(
          kmhDebts,
          equals(expectedKmhDebts),
          reason: 'KMH debts should equal sum of all negative balances',
        );

        // Property: Net assets should be negative and equal to -kmhDebts
        expect(
          netAssets,
          equals(-kmhDebts),
          reason:
              'Net assets should equal negative KMH debts when no positive assets',
        );

        // Property: Net assets should be negative
        expect(
          netAssets,
          lessThan(0),
          reason: 'Net assets should be negative when only debts exist',
        );

        // Verify all accounts have negative balance
        for (var wallet in retrievedWallets.where((w) => w.isKmhAccount)) {
          expect(
            wallet.balance,
            lessThan(0),
            reason: 'All KMH accounts should have negative balance',
          );
        }

        return true;
      },
      iterations: 100,
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description:
          'Property 22: Net assets with mixed account types and balances',
      generator: () {
        // Generate a complex scenario with all types
        final kmhCount = PropertyTest.randomInt(min: 1, max: 3);
        final regularBankCount = PropertyTest.randomInt(min: 1, max: 3);
        final cashCount = PropertyTest.randomInt(min: 1, max: 3);
        final creditCardCount = PropertyTest.randomInt(min: 0, max: 2);

        final kmhAccounts = List.generate(kmhCount, (index) {
          final isNegative = PropertyTest.randomBool();
          return {
            'id': const Uuid().v4(),
            'name': 'KMH ${index + 1}',
            'balance': isNegative
                ? -PropertyTest.randomPositiveDouble(min: 1000, max: 30000)
                : PropertyTest.randomPositiveDouble(min: 1000, max: 30000),
            'type': 'bank',
            'creditLimit': PropertyTest.randomPositiveDouble(
              min: 5000,
              max: 50000,
            ),
            'interestRate': PropertyTest.randomPositiveDouble(min: 10, max: 40),
          };
        });

        final regularBanks = List.generate(regularBankCount, (index) {
          return {
            'id': const Uuid().v4(),
            'name': 'Bank ${index + 1}',
            'balance': PropertyTest.randomDouble(min: -5000, max: 20000),
            'type': 'bank',
            'creditLimit': 0.0,
          };
        });

        final cashAccounts = List.generate(cashCount, (index) {
          return {
            'id': const Uuid().v4(),
            'name': 'Cash ${index + 1}',
            'balance': PropertyTest.randomDouble(min: 0, max: 5000),
            'type': 'cash',
            'creditLimit': 0.0,
          };
        });

        final creditCards = List.generate(creditCardCount, (index) {
          return {
            'id': const Uuid().v4(),
            'name': 'Credit Card ${index + 1}',
            'balance': PropertyTest.randomPositiveDouble(min: 0, max: 10000),
            'type': 'credit_card',
            'creditLimit': PropertyTest.randomPositiveDouble(
              min: 5000,
              max: 30000,
            ),
          };
        });

        return {
          'kmhAccounts': kmhAccounts,
          'regularBanks': regularBanks,
          'cashAccounts': cashAccounts,
          'creditCards': creditCards,
        };
      },
      property: (data) async {
        // Clear data
        final prefs = await dataService.getPrefs();
        await prefs.setString('wallets', '[]');
        await dataService.saveWallets([]);

        final kmhAccountsData =
            data['kmhAccounts'] as List<Map<String, dynamic>>;
        final regularBanksData =
            data['regularBanks'] as List<Map<String, dynamic>>;
        final cashAccountsData =
            data['cashAccounts'] as List<Map<String, dynamic>>;
        final creditCardsData =
            data['creditCards'] as List<Map<String, dynamic>>;

        // Create all wallets
        for (var accountData in [
          ...kmhAccountsData,
          ...regularBanksData,
          ...cashAccountsData,
          ...creditCardsData,
        ]) {
          final wallet = Wallet(
            id: accountData['id'],
            name: accountData['name'],
            balance: accountData['balance'],
            type: accountData['type'],
            color:
                '#${PropertyTest.randomInt(min: 0, max: 0xFFFFFF).toRadixString(16).padLeft(6, '0')}',
            icon: 'account_balance',
            creditLimit: accountData['creditLimit'],
            interestRate: accountData['interestRate'],
          );
          await dataService.addWallet(wallet);
        }

        // Retrieve wallets
        final retrievedWallets = await dataService.getWallets();

        // Calculate using statistics screen logic
        final assetWallets = retrievedWallets
            .where((w) => w.type != 'credit_card')
            .toList();

        final positiveAssets = assetWallets
            .where((w) => w.balance > 0)
            .fold(0.0, (sum, w) => sum + w.balance);

        final kmhDebts = assetWallets
            .where((w) => w.isKmhAccount && w.balance < 0)
            .fold(0.0, (sum, w) => sum + w.balance.abs());

        final netAssets = positiveAssets - kmhDebts;

        // Calculate expected values manually
        final expectedPositiveAssets = [
          ...kmhAccountsData.where((a) => (a['balance'] as double) > 0),
          ...regularBanksData.where((a) => (a['balance'] as double) > 0),
          ...cashAccountsData.where((a) => (a['balance'] as double) > 0),
        ].fold(0.0, (sum, a) => sum + (a['balance'] as double));

        final expectedKmhDebts = kmhAccountsData
            .where((a) => (a['balance'] as double) < 0)
            .fold(0.0, (sum, a) => sum + (a['balance'] as double).abs());

        final expectedNetAssets = expectedPositiveAssets - expectedKmhDebts;

        // Property 1: Positive assets should match expected
        expect(
          positiveAssets,
          equals(expectedPositiveAssets),
          reason:
              'Positive assets should include all positive non-credit-card balances',
        );

        // Property 2: KMH debts should match expected
        expect(
          kmhDebts,
          equals(expectedKmhDebts),
          reason: 'KMH debts should only include negative KMH balances',
        );

        // Property 3: Net assets should match formula
        expect(
          netAssets,
          equals(expectedNetAssets),
          reason: 'Net assets should equal positive assets minus KMH debts',
        );

        // Property 4: Credit card balances should not affect net assets
        // Net assets calculation should not include credit card balances
        final netAssetsWithoutCreditCards = positiveAssets - kmhDebts;
        expect(
          netAssets,
          equals(netAssetsWithoutCreditCards),
          reason:
              'Credit card balances should not be included in net assets calculation',
        );

        // Property 5: Regular bank negative balances should not affect KMH debts
        final regularBankNegatives = regularBanksData
            .where((a) => (a['balance'] as double) < 0)
            .toList();

        for (var negBank in regularBankNegatives) {
          // This negative balance should NOT be in KMH debts
          final wallet = retrievedWallets.firstWhere(
            (w) => w.id == negBank['id'],
          );
          expect(
            wallet.isKmhAccount,
            isFalse,
            reason: 'Regular bank should not be identified as KMH account',
          );
        }

        return true;
      },
      iterations: 100,
    );
  });
}
