import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:parion/models/wallet.dart';
import 'package:parion/models/loan.dart';
import 'package:parion/services/data_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../property_test_utils.dart';
import 'package:uuid/uuid.dart';

/// **Feature: kmh-account-management, Property 23: Toplam Borç Dahil Etme**
/// **Validates: Requirements 6.4**
/// 
/// Property: For any debt calculation, total debt should equal 
/// credit card debts + KMH debts + loan debts.
/// 
/// Note: In the home screen, credit card debts are calculated from wallets
/// with type='credit_card', not from the CreditCard model.
void main() {
  group('KMH Total Debt Inclusion Property Tests', () {
    late DataService dataService;
    late Directory testDir;

    setUpAll(() async {
      // Create a temporary directory for testing
      testDir = await Directory.systemTemp.createTemp('kmh_inclusion_test_');
      
      // Initialize Hive with the test directory
      Hive.init(testDir.path);
    });

    setUp(() async {
      // Clear SharedPreferences before each test
      SharedPreferences.setMockInitialValues({});
      
      // Initialize services
      dataService = DataService();
      await dataService.init();
      
      // Clear any existing data
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
      description: 'Property 23: Total debt includes KMH debts, credit card debts, and loan debts',
      generator: () {
        // Generate KMH accounts (some with negative balances)
        final kmhAccountCount = PropertyTest.randomInt(min: 0, max: 5);
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
        
        // Generate credit card wallets (type='credit_card')
        // Note: Credit card debts are tracked as wallet balances
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
        
        // Generate loans
        final loanCount = PropertyTest.randomInt(min: 0, max: 3);
        final loans = List.generate(loanCount, (index) {
          final remainingAmount = PropertyTest.randomPositiveDouble(min: 1000, max: 100000);
          return {
            'id': const Uuid().v4(),
            'name': 'Loan ${index + 1}',
            'remainingAmount': remainingAmount,
            'totalAmount': remainingAmount,
          };
        });
        
        return {
          'kmhAccounts': kmhAccounts,
          'creditCards': creditCards,
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
        final loansData = data['loans'] as List<Map<String, dynamic>>;
        
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
        
        // Create all credit card wallets
        for (var cardData in creditCardsData) {
          final wallet = Wallet(
            id: cardData['id'],
            name: cardData['name'],
            balance: cardData['balance'],
            type: cardData['type'],
            color: cardData['color'],
            icon: cardData['icon'],
            creditLimit: cardData['creditLimit'],
          );
          await dataService.addWallet(wallet);
        }
        
        // Create all loans
        for (var loanData in loansData) {
          final loan = Loan(
            id: loanData['id'],
            name: loanData['name'],
            bankName: 'Test Bank',
            totalAmount: loanData['totalAmount'],
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
        
        // Calculate expected debts (same logic as home screen)
        final expectedKmhDebts = kmhAccountsData
            .where((a) => (a['balance'] as double) < 0)
            .fold(0.0, (sum, a) => sum + (a['balance'] as double).abs());
        
        final expectedCreditCardDebts = creditCardsData
            .fold(0.0, (sum, a) => sum + (a['balance'] as double).abs());
        
        final expectedLoanDebts = loansData
            .fold(0.0, (sum, a) => sum + (a['remainingAmount'] as double));
        
        final expectedTotalDebt = expectedKmhDebts + expectedCreditCardDebts + expectedLoanDebts;
        
        // Calculate actual debts (same logic as home screen)
        final actualKmhDebts = retrievedWallets
            .where((w) => w.isKmhAccount && w.balance < 0)
            .fold(0.0, (sum, w) => sum + w.balance.abs());
        
        final actualCreditCardDebts = retrievedWallets
            .where((w) => w.type == 'credit_card')
            .fold(0.0, (sum, w) => sum + w.balance.abs());
        
        final actualLoanDebts = retrievedLoans
            .fold(0.0, (sum, loan) => sum + loan.remainingAmount);
        
        final actualTotalDebt = actualKmhDebts + actualCreditCardDebts + actualLoanDebts;
        
        // Property 1: Total debt should equal sum of all debt types
        expect(actualTotalDebt, equals(expectedTotalDebt),
          reason: 'Total debt should equal credit card debts + KMH debts + loan debts');
        
        // Property 2: KMH debts should be included in total debt
        expect(actualTotalDebt, greaterThanOrEqualTo(actualKmhDebts),
          reason: 'Total debt should include KMH debts');
        
        // Property 3: Credit card debts should be included in total debt
        expect(actualTotalDebt, greaterThanOrEqualTo(actualCreditCardDebts),
          reason: 'Total debt should include credit card debts');
        
        // Property 4: Loan debts should be included in total debt
        expect(actualTotalDebt, greaterThanOrEqualTo(actualLoanDebts),
          reason: 'Total debt should include loan debts');
        
        // Property 5: Each component should be calculated correctly
        expect(actualKmhDebts, equals(expectedKmhDebts),
          reason: 'KMH debts should be calculated correctly');
        expect(actualCreditCardDebts, equals(expectedCreditCardDebts),
          reason: 'Credit card debts should be calculated correctly');
        expect(actualLoanDebts, equals(expectedLoanDebts),
          reason: 'Loan debts should be calculated correctly');
        
        // Property 6: All debt components should be non-negative
        expect(actualKmhDebts, greaterThanOrEqualTo(0),
          reason: 'KMH debts should be non-negative');
        expect(actualCreditCardDebts, greaterThanOrEqualTo(0),
          reason: 'Credit card debts should be non-negative');
        expect(actualLoanDebts, greaterThanOrEqualTo(0),
          reason: 'Loan debts should be non-negative');
        expect(actualTotalDebt, greaterThanOrEqualTo(0),
          reason: 'Total debt should be non-negative');
        
        return true;
      },
      iterations: 100,
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 23: Total debt with only KMH debts',
      generator: () {
        final kmhAccountCount = PropertyTest.randomInt(min: 1, max: 5);
        final kmhAccounts = List.generate(kmhAccountCount, (index) {
          return {
            'id': const Uuid().v4(),
            'name': 'KMH Account ${index + 1}',
            'balance': -PropertyTest.randomPositiveDouble(min: 100, max: 50000),
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
        await prefs.setString('loans', '[]');
        await dataService.saveWallets([]);
        
        final kmhAccountsData = data['kmhAccounts'] as List<Map<String, dynamic>>;
        
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
          );
          await dataService.addWallet(wallet);
        }
        
        // Retrieve data
        final retrievedWallets = await dataService.getWallets();
        final retrievedLoans = await dataService.getLoans();
        
        // Calculate debts
        final kmhDebts = retrievedWallets
            .where((w) => w.isKmhAccount && w.balance < 0)
            .fold(0.0, (sum, w) => sum + w.balance.abs());
        
        final creditCardDebts = retrievedWallets
            .where((w) => w.type == 'credit_card')
            .fold(0.0, (sum, w) => sum + w.balance.abs());
        
        final loanDebts = retrievedLoans
            .fold(0.0, (sum, loan) => sum + loan.remainingAmount);
        
        final totalDebt = kmhDebts + creditCardDebts + loanDebts;
        
        // Property: When only KMH debts exist, total debt should equal KMH debts
        expect(totalDebt, equals(kmhDebts),
          reason: 'Total debt should equal KMH debts when no other debts exist');
        expect(creditCardDebts, equals(0),
          reason: 'Credit card debts should be zero');
        expect(loanDebts, equals(0),
          reason: 'Loan debts should be zero');
        
        return true;
      },
      iterations: 100,
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 23: Total debt with no KMH debts',
      generator: () {
        // Generate credit card wallets
        final creditCardCount = PropertyTest.randomInt(min: 1, max: 5);
        final creditCards = List.generate(creditCardCount, (index) {
          return {
            'id': const Uuid().v4(),
            'name': 'Credit Card ${index + 1}',
            'balance': PropertyTest.randomPositiveDouble(min: 100, max: 20000),
            'type': 'credit_card',
            'color': '#${PropertyTest.randomInt(min: 0, max: 0xFFFFFF).toRadixString(16).padLeft(6, '0')}',
            'icon': 'credit_card',
            'creditLimit': PropertyTest.randomPositiveDouble(min: 5000, max: 50000),
          };
        });
        
        // Generate loans
        final loanCount = PropertyTest.randomInt(min: 1, max: 3);
        final loans = List.generate(loanCount, (index) {
          final remainingAmount = PropertyTest.randomPositiveDouble(min: 1000, max: 100000);
          return {
            'id': const Uuid().v4(),
            'name': 'Loan ${index + 1}',
            'remainingAmount': remainingAmount,
            'totalAmount': remainingAmount,
          };
        });
        
        return {
          'creditCards': creditCards,
          'loans': loans,
        };
      },
      property: (data) async {
        // Clear data
        final prefs = await dataService.getPrefs();
        await prefs.setString('wallets', '[]');
        await prefs.setString('loans', '[]');
        await dataService.saveWallets([]);
        
        final creditCardsData = data['creditCards'] as List<Map<String, dynamic>>;
        final loansData = data['loans'] as List<Map<String, dynamic>>;
        
        // Create credit card wallets
        for (var cardData in creditCardsData) {
          final wallet = Wallet(
            id: cardData['id'],
            name: cardData['name'],
            balance: cardData['balance'],
            type: cardData['type'],
            color: cardData['color'],
            icon: cardData['icon'],
            creditLimit: cardData['creditLimit'],
          );
          await dataService.addWallet(wallet);
        }
        
        // Create loans
        for (var loanData in loansData) {
          final loan = Loan(
            id: loanData['id'],
            name: loanData['name'],
            bankName: 'Test Bank',
            totalAmount: loanData['totalAmount'],
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
        
        // Retrieve data
        final retrievedWallets = await dataService.getWallets();
        final retrievedLoans = await dataService.getLoans();
        
        // Calculate debts
        final kmhDebts = retrievedWallets
            .where((w) => w.isKmhAccount && w.balance < 0)
            .fold(0.0, (sum, w) => sum + w.balance.abs());
        
        final creditCardDebts = retrievedWallets
            .where((w) => w.type == 'credit_card')
            .fold(0.0, (sum, w) => sum + w.balance.abs());
        
        final loanDebts = retrievedLoans
            .fold(0.0, (sum, loan) => sum + loan.remainingAmount);
        
        final totalDebt = kmhDebts + creditCardDebts + loanDebts;
        
        final expectedTotal = creditCardDebts + loanDebts;
        
        // Property: When no KMH debts exist, total debt should equal credit card + loan debts
        expect(kmhDebts, equals(0),
          reason: 'KMH debts should be zero');
        expect(totalDebt, equals(expectedTotal),
          reason: 'Total debt should equal credit card debts + loan debts when no KMH debts exist');
        
        return true;
      },
      iterations: 100,
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 23: Total debt with zero debts',
      generator: () {
        // Generate KMH accounts with positive balances only
        final kmhAccountCount = PropertyTest.randomInt(min: 0, max: 3);
        final kmhAccounts = List.generate(kmhAccountCount, (index) {
          return {
            'id': const Uuid().v4(),
            'name': 'KMH Account ${index + 1}',
            'balance': PropertyTest.randomPositiveDouble(min: 100, max: 50000),
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
        await prefs.setString('loans', '[]');
        await dataService.saveWallets([]);
        
        final kmhAccountsData = data['kmhAccounts'] as List<Map<String, dynamic>>;
        
        // Create KMH accounts with positive balances
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
        
        // Retrieve data
        final retrievedWallets = await dataService.getWallets();
        final retrievedLoans = await dataService.getLoans();
        
        // Calculate debts
        final kmhDebts = retrievedWallets
            .where((w) => w.isKmhAccount && w.balance < 0)
            .fold(0.0, (sum, w) => sum + w.balance.abs());
        
        final creditCardDebts = retrievedWallets
            .where((w) => w.type == 'credit_card')
            .fold(0.0, (sum, w) => sum + w.balance.abs());
        
        final loanDebts = retrievedLoans
            .fold(0.0, (sum, loan) => sum + loan.remainingAmount);
        
        final totalDebt = kmhDebts + creditCardDebts + loanDebts;
        
        // Property: When no debts exist, total debt should be zero
        expect(totalDebt, equals(0),
          reason: 'Total debt should be zero when no debts exist');
        expect(kmhDebts, equals(0),
          reason: 'KMH debts should be zero');
        expect(creditCardDebts, equals(0),
          reason: 'Credit card debts should be zero');
        expect(loanDebts, equals(0),
          reason: 'Loan debts should be zero');
        
        return true;
      },
      iterations: 100,
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 23: Total debt calculation is additive',
      generator: () {
        // Generate one of each debt type
        final kmhBalance = -PropertyTest.randomPositiveDouble(min: 1000, max: 50000);
        final creditCardBalance = PropertyTest.randomPositiveDouble(min: 1000, max: 20000);
        final loanBalance = PropertyTest.randomPositiveDouble(min: 5000, max: 100000);
        
        return {
          'kmhBalance': kmhBalance,
          'creditCardBalance': creditCardBalance,
          'loanBalance': loanBalance,
        };
      },
      property: (data) async {
        // Clear data
        final prefs = await dataService.getPrefs();
        await prefs.setString('wallets', '[]');
        await prefs.setString('loans', '[]');
        await dataService.saveWallets([]);
        
        final kmhBalance = data['kmhBalance'] as double;
        final creditCardBalance = data['creditCardBalance'] as double;
        final loanBalance = data['loanBalance'] as double;
        
        // Create one KMH account
        final kmhWallet = Wallet(
          id: const Uuid().v4(),
          name: 'KMH Account',
          balance: kmhBalance,
          type: 'bank',
          color: '#FF0000',
          icon: 'account_balance',
          creditLimit: 100000.0,
          interestRate: 24.0,
        );
        await dataService.addWallet(kmhWallet);
        
        // Create one credit card wallet
        final creditCardWallet = Wallet(
          id: const Uuid().v4(),
          name: 'Credit Card',
          balance: creditCardBalance,
          type: 'credit_card',
          color: '#00FF00',
          icon: 'credit_card',
          creditLimit: 50000.0,
        );
        await dataService.addWallet(creditCardWallet);
        
        // Create one loan
        final loan = Loan(
          id: const Uuid().v4(),
          name: 'Test Loan',
          bankName: 'Test Bank',
          totalAmount: loanBalance,
          remainingAmount: loanBalance,
          totalInstallments: 12,
          remainingInstallments: 12,
          currentInstallment: 1,
          installmentAmount: loanBalance / 12,
          startDate: DateTime.now(),
          endDate: DateTime.now().add(const Duration(days: 365)),
          walletId: const Uuid().v4(),
          installments: [],
        );
        await dataService.addLoan(loan);
        
        // Retrieve data
        final retrievedWallets = await dataService.getWallets();
        final retrievedLoans = await dataService.getLoans();
        
        // Calculate debts
        final kmhDebts = retrievedWallets
            .where((w) => w.isKmhAccount && w.balance < 0)
            .fold(0.0, (sum, w) => sum + w.balance.abs());
        
        final creditCardDebts = retrievedWallets
            .where((w) => w.type == 'credit_card')
            .fold(0.0, (sum, w) => sum + w.balance.abs());
        
        final loanDebts = retrievedLoans
            .fold(0.0, (sum, loan) => sum + loan.remainingAmount);
        
        final totalDebt = kmhDebts + creditCardDebts + loanDebts;
        
        // Expected values
        final expectedKmhDebt = kmhBalance.abs();
        final expectedCreditCardDebt = creditCardBalance;
        final expectedLoanDebt = loanBalance;
        final expectedTotalDebt = expectedKmhDebt + expectedCreditCardDebt + expectedLoanDebt;
        
        // Property: Total debt should be the sum of individual components
        expect(kmhDebts, equals(expectedKmhDebt),
          reason: 'KMH debt should match expected value');
        expect(creditCardDebts, equals(expectedCreditCardDebt),
          reason: 'Credit card debt should match expected value');
        expect(loanDebts, equals(expectedLoanDebt),
          reason: 'Loan debt should match expected value');
        expect(totalDebt, equals(expectedTotalDebt),
          reason: 'Total debt should equal sum of all components');
        
        // Property: Removing any component should reduce total debt
        final totalWithoutKmh = creditCardDebts + loanDebts;
        final totalWithoutCC = kmhDebts + loanDebts;
        final totalWithoutLoan = kmhDebts + creditCardDebts;
        
        expect(totalDebt, greaterThan(totalWithoutKmh),
          reason: 'Total debt should be greater than total without KMH');
        expect(totalDebt, greaterThan(totalWithoutCC),
          reason: 'Total debt should be greater than total without credit cards');
        expect(totalDebt, greaterThan(totalWithoutLoan),
          reason: 'Total debt should be greater than total without loans');
        
        return true;
      },
      iterations: 100,
    );
  });
}
