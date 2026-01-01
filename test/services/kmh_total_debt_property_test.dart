import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:parion/models/wallet.dart';
import 'package:parion/models/loan.dart';
import 'package:parion/services/data_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../property_test_utils.dart';
import 'package:uuid/uuid.dart';

/// **Feature: kmh-account-management, Property 21: Toplam Borç Hesaplama**
/// **Validates: Requirements 6.1**
/// 
/// Property: For any set of KMH accounts, total KMH debt should equal 
/// the sum of all negative balances.
void main() {
  group('KMH Total Debt Calculation Property Tests', () {
    late DataService dataService;
    late Directory testDir;

    setUpAll(() async {
      // Create a temporary directory for testing
      testDir = await Directory.systemTemp.createTemp('kmh_debt_test_');
      
      // Initialize Hive with the test directory
      Hive.init(testDir.path);
    });

    setUp(() async {
      // Clear SharedPreferences before each test
      SharedPreferences.setMockInitialValues({});
      
      // Initialize DataService
      dataService = DataService();
      await dataService.init();
      
      // Clear any existing wallets and loans
      final prefs = await dataService.getPrefs();
      await prefs.setString('wallets', '[]');
      await prefs.setString('loans', '[]');
    });

    tearDownAll(() async {
      // Clean up
      await Hive.close();
      if (await testDir.exists()) {
        await testDir.delete(recursive: true);
      }
    });

    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 21: Total KMH debt equals sum of all negative balances',
      generator: () {
        // Generate a random number of KMH accounts (1-10)
        final kmhAccountCount = PropertyTest.randomInt(min: 1, max: 10);
        
        // Generate KMH accounts with varying balances (some positive, some negative)
        final kmhAccounts = List.generate(kmhAccountCount, (index) {
          // Mix of positive and negative balances
          final isNegative = PropertyTest.randomBool();
          final balance = isNegative
              ? -PropertyTest.randomPositiveDouble(min: 100, max: 50000)
              : PropertyTest.randomPositiveDouble(min: 100, max: 50000);
          
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
          'kmhAccounts': kmhAccounts,
        };
      },
      property: (data) async {
        // Clear wallets before each iteration
        final prefs = await dataService.getPrefs();
        await prefs.setString('wallets', '[]');
        await prefs.setString('loans', '[]');
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
            lastInterestDate: accountData['lastInterestDate'],
            accruedInterest: accountData['accruedInterest'],
            accountNumber: accountData['accountNumber'],
          );
          await dataService.addWallet(wallet);
        }
        
        // Retrieve all wallets
        final retrievedWallets = await dataService.getWallets();
        
        // Calculate expected KMH debt (sum of negative balances)
        final expectedKmhDebt = kmhAccountsData
            .where((a) => (a['balance'] as double) < 0)
            .fold(0.0, (sum, a) => sum + (a['balance'] as double).abs());
        
        // Calculate actual KMH debt using the same logic as home screen
        final actualKmhDebt = retrievedWallets
            .where((w) => w.isKmhAccount && w.balance < 0)
            .fold(0.0, (sum, w) => sum + w.balance.abs());
        
        // Property 1: Total KMH debt should equal sum of negative balances
        expect(actualKmhDebt, equals(expectedKmhDebt),
          reason: 'Total KMH debt should equal sum of all negative balances');
        
        // Property 2: Positive balance KMH accounts should not contribute to debt
        final positiveBalanceAccounts = retrievedWallets
            .where((w) => w.isKmhAccount && w.balance >= 0);
        
        for (var account in positiveBalanceAccounts) {
          // Verify that positive balances are not included in debt calculation
          final debtContribution = actualKmhDebt;
          final debtWithoutThisAccount = retrievedWallets
              .where((w) => w.isKmhAccount && w.balance < 0 && w.id != account.id)
              .fold(0.0, (sum, w) => sum + w.balance.abs());
          
          // If this account has positive balance, removing it shouldn't change debt
          if (account.balance >= 0) {
            expect(debtContribution, equals(debtWithoutThisAccount),
              reason: 'Positive balance accounts should not contribute to debt');
          }
        }
        
        // Property 3: Each negative balance account should contribute its absolute value
        final negativeBalanceAccounts = retrievedWallets
            .where((w) => w.isKmhAccount && w.balance < 0);
        
        for (var account in negativeBalanceAccounts) {
          final accountDebt = account.balance.abs();
          expect(accountDebt, greaterThan(0),
            reason: 'Negative balance account should have positive debt contribution');
          
          // Verify this account's debt is included in total
          expect(actualKmhDebt, greaterThanOrEqualTo(accountDebt),
            reason: 'Total debt should include this account\'s debt');
        }
        
        // Property 4: Zero balance accounts should not contribute to debt
        final zeroBalanceAccounts = retrievedWallets
            .where((w) => w.isKmhAccount && w.balance == 0);
        
        for (var account in zeroBalanceAccounts) {
          // Zero balance should not contribute to debt
          expect(account.balance.abs(), equals(0),
            reason: 'Zero balance account should have zero debt');
        }
        
        // Property 5: Total debt should be non-negative
        expect(actualKmhDebt, greaterThanOrEqualTo(0),
          reason: 'Total debt should always be non-negative');
        
        return true;
      },
      iterations: 100,
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 21: Total debt calculation with mixed account types',
      generator: () {
        // Generate KMH accounts
        final kmhAccountCount = PropertyTest.randomInt(min: 1, max: 5);
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
            'color': '#${PropertyTest.randomInt(min: 0, max: 0xFFFFFF).toRadixString(16).padLeft(6, '0')}',
            'icon': 'account_balance',
            'creditLimit': PropertyTest.randomPositiveDouble(min: 1000, max: 100000),
            'interestRate': PropertyTest.randomPositiveDouble(min: 1, max: 50),
          };
        });
        
        // Generate credit card accounts
        final creditCardCount = PropertyTest.randomInt(min: 0, max: 5);
        final creditCards = List.generate(creditCardCount, (index) {
          return {
            'id': const Uuid().v4(),
            'name': 'Credit Card ${index + 1}',
            'balance': PropertyTest.randomPositiveDouble(min: 0, max: 20000),
            'type': 'credit_card',
            'color': '#${PropertyTest.randomInt(min: 0, max: 0xFFFFFF).toRadixString(16).padLeft(6, '0')}',
            'icon': 'credit_card',
            'creditLimit': PropertyTest.randomPositiveDouble(min: 5000, max: 50000),
          };
        });
        
        // Generate regular bank accounts (no credit limit)
        final regularBankCount = PropertyTest.randomInt(min: 0, max: 5);
        final regularBanks = List.generate(regularBankCount, (index) {
          return {
            'id': const Uuid().v4(),
            'name': 'Regular Bank ${index + 1}',
            'balance': PropertyTest.randomDouble(min: -10000, max: 50000),
            'type': 'bank',
            'color': '#${PropertyTest.randomInt(min: 0, max: 0xFFFFFF).toRadixString(16).padLeft(6, '0')}',
            'icon': 'account_balance',
            'creditLimit': 0.0, // No credit limit = not KMH
          };
        });
        
        // Generate loans
        final loanCount = PropertyTest.randomInt(min: 0, max: 3);
        final loans = List.generate(loanCount, (index) {
          return {
            'id': const Uuid().v4(),
            'name': 'Loan ${index + 1}',
            'remainingAmount': PropertyTest.randomPositiveDouble(min: 1000, max: 100000),
          };
        });
        
        return {
          'kmhAccounts': kmhAccounts,
          'creditCards': creditCards,
          'regularBanks': regularBanks,
          'loans': loans,
        };
      },
      property: (data) async {
        // Clear data before each iteration
        final prefs = await dataService.getPrefs();
        await prefs.setString('wallets', '[]');
        await prefs.setString('loans', '[]');
        await dataService.saveWallets([]);
        
        final kmhAccountsData = data['kmhAccounts'] as List<Map<String, dynamic>>;
        final creditCardsData = data['creditCards'] as List<Map<String, dynamic>>;
        final regularBanksData = data['regularBanks'] as List<Map<String, dynamic>>;
        final loansData = data['loans'] as List<Map<String, dynamic>>;
        
        // Create all wallets
        for (var accountData in [...kmhAccountsData, ...creditCardsData, ...regularBanksData]) {
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
        
        // Create all loans
        for (var loanData in loansData) {
          final loan = Loan(
            id: loanData['id'],
            name: loanData['name'],
            bankName: 'Test Bank',
            totalAmount: loanData['remainingAmount'],
            remainingAmount: loanData['remainingAmount'],
            totalInstallments: 12,
            remainingInstallments: 12,
            currentInstallment: 1,
            installmentAmount: loanData['remainingAmount'] / 12,
            startDate: DateTime.now(),
            endDate: DateTime.now().add(const Duration(days: 365)),
            walletId: const Uuid().v4(),
            installments: [],
          );
          await dataService.addLoan(loan);
        }
        
        // Retrieve all data
        final retrievedWallets = await dataService.getWallets();
        final retrievedLoans = await dataService.getLoans();
        
        // Calculate expected debts
        final expectedKmhDebt = kmhAccountsData
            .where((a) => (a['balance'] as double) < 0)
            .fold(0.0, (sum, a) => sum + (a['balance'] as double).abs());
        
        final expectedCreditCardDebt = creditCardsData
            .fold(0.0, (sum, a) => sum + (a['balance'] as double).abs());
        
        final expectedLoanDebt = loansData
            .fold(0.0, (sum, a) => sum + (a['remainingAmount'] as double));
        
        final expectedTotalDebt = expectedKmhDebt + expectedCreditCardDebt + expectedLoanDebt;
        
        // Calculate actual debts using home screen logic
        final actualKmhDebt = retrievedWallets
            .where((w) => w.isKmhAccount && w.balance < 0)
            .fold(0.0, (sum, w) => sum + w.balance.abs());
        
        final actualCreditCardDebt = retrievedWallets
            .where((w) => w.type == 'credit_card')
            .fold(0.0, (sum, w) => sum + w.balance.abs());
        
        final actualLoanDebt = retrievedLoans
            .fold(0.0, (sum, loan) => sum + loan.remainingAmount);
        
        final actualTotalDebt = actualKmhDebt + actualCreditCardDebt + actualLoanDebt;
        
        // Property 1: KMH debt should be calculated correctly
        expect(actualKmhDebt, equals(expectedKmhDebt),
          reason: 'KMH debt should equal sum of negative KMH balances');
        
        // Property 2: Total debt should include all debt types
        expect(actualTotalDebt, equals(expectedTotalDebt),
          reason: 'Total debt should equal sum of KMH + credit card + loan debts');
        
        // Property 3: KMH debt should be a component of total debt
        expect(actualTotalDebt, greaterThanOrEqualTo(actualKmhDebt),
          reason: 'Total debt should be at least as large as KMH debt');
        
        // Property 4: Regular bank accounts should not affect KMH debt
        // Verify that only KMH accounts (bank with creditLimit > 0) are counted
        final allBankAccounts = retrievedWallets.where((w) => w.type == 'bank');
        for (var bank in allBankAccounts) {
          if (bank.creditLimit == 0 && bank.balance < 0) {
            // This is a regular bank with negative balance - should NOT be in KMH debt
            final isCountedInKmhDebt = retrievedWallets
                .where((w) => w.isKmhAccount && w.balance < 0)
                .any((w) => w.id == bank.id);
            expect(isCountedInKmhDebt, isFalse,
              reason: 'Regular bank account ${bank.id} should not be counted as KMH debt');
          }
        }
        
        // Property 5: Each debt component should be non-negative
        expect(actualKmhDebt, greaterThanOrEqualTo(0));
        expect(actualCreditCardDebt, greaterThanOrEqualTo(0));
        expect(actualLoanDebt, greaterThanOrEqualTo(0));
        expect(actualTotalDebt, greaterThanOrEqualTo(0));
        
        return true;
      },
      iterations: 100,
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 21: KMH debt with all positive balances should be zero',
      generator: () {
        final kmhAccountCount = PropertyTest.randomInt(min: 1, max: 10);
        
        final kmhAccounts = List.generate(kmhAccountCount, (index) {
          return {
            'id': const Uuid().v4(),
            'name': 'KMH Account ${index + 1}',
            'balance': PropertyTest.randomPositiveDouble(min: 1, max: 50000), // All positive
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
        // Clear data
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
        
        // Retrieve wallets
        final retrievedWallets = await dataService.getWallets();
        
        // Calculate KMH debt
        final kmhDebt = retrievedWallets
            .where((w) => w.isKmhAccount && w.balance < 0)
            .fold(0.0, (sum, w) => sum + w.balance.abs());
        
        // Property: KMH debt should be zero when all balances are positive
        expect(kmhDebt, equals(0.0),
          reason: 'KMH debt should be zero when all accounts have positive balances');
        
        // Verify all accounts are indeed positive
        for (var wallet in retrievedWallets.where((w) => w.isKmhAccount)) {
          expect(wallet.balance, greaterThan(0),
            reason: 'All KMH accounts should have positive balance');
        }
        
        return true;
      },
      iterations: 100,
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 21: KMH debt with all negative balances',
      generator: () {
        final kmhAccountCount = PropertyTest.randomInt(min: 1, max: 10);
        
        final kmhAccounts = List.generate(kmhAccountCount, (index) {
          return {
            'id': const Uuid().v4(),
            'name': 'KMH Account ${index + 1}',
            'balance': -PropertyTest.randomPositiveDouble(min: 1, max: 50000), // All negative
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
        // Clear data
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
        
        // Retrieve wallets
        final retrievedWallets = await dataService.getWallets();
        
        // Calculate expected total debt (sum of all absolute values)
        final expectedDebt = kmhAccountsData
            .fold(0.0, (sum, a) => sum + (a['balance'] as double).abs());
        
        // Calculate actual KMH debt
        final actualDebt = retrievedWallets
            .where((w) => w.isKmhAccount && w.balance < 0)
            .fold(0.0, (sum, w) => sum + w.balance.abs());
        
        // Property: KMH debt should equal sum of all absolute values
        expect(actualDebt, equals(expectedDebt),
          reason: 'KMH debt should equal sum of all negative balances when all are negative');
        
        // Property: Debt should be positive
        expect(actualDebt, greaterThan(0),
          reason: 'KMH debt should be positive when accounts have negative balances');
        
        // Verify all accounts are indeed negative
        for (var wallet in retrievedWallets.where((w) => w.isKmhAccount)) {
          expect(wallet.balance, lessThan(0),
            reason: 'All KMH accounts should have negative balance');
        }
        
        return true;
      },
      iterations: 100,
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 21: Single KMH account debt calculation',
      generator: () {
        final isNegative = PropertyTest.randomBool();
        final balance = isNegative
            ? -PropertyTest.randomPositiveDouble(min: 100, max: 50000)
            : PropertyTest.randomPositiveDouble(min: 100, max: 50000);
        
        return {
          'id': const Uuid().v4(),
          'name': 'Single KMH Account',
          'balance': balance,
          'type': 'bank',
          'color': '#${PropertyTest.randomInt(min: 0, max: 0xFFFFFF).toRadixString(16).padLeft(6, '0')}',
          'icon': 'account_balance',
          'creditLimit': PropertyTest.randomPositiveDouble(min: 1000, max: 100000),
          'interestRate': PropertyTest.randomPositiveDouble(min: 1, max: 50),
        };
      },
      property: (data) async {
        // Clear data
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
        );
        await dataService.addWallet(wallet);
        
        // Retrieve wallets
        final retrievedWallets = await dataService.getWallets();
        
        // Calculate KMH debt
        final kmhDebt = retrievedWallets
            .where((w) => w.isKmhAccount && w.balance < 0)
            .fold(0.0, (sum, w) => sum + w.balance.abs());
        
        // Expected debt
        final expectedDebt = (data['balance'] as double) < 0 
            ? (data['balance'] as double).abs() 
            : 0.0;
        
        // Property: Debt should match expected value
        expect(kmhDebt, equals(expectedDebt),
          reason: 'Single account debt should equal its absolute balance if negative, 0 otherwise');
        
        return true;
      },
      iterations: 100,
    );
  });
}
