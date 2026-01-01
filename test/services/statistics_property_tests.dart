import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:parion/models/credit_card.dart';
import 'package:parion/models/credit_card_transaction.dart';
import 'package:parion/models/wallet.dart';
import 'package:parion/models/kmh_transaction.dart';
import 'package:parion/models/kmh_transaction_type.dart';
import 'package:parion/services/statistics_service.dart';
import 'package:parion/services/data_service.dart';
import 'package:parion/services/kmh_service.dart';
import 'package:parion/services/kmh_box_service.dart';
import 'package:parion/services/credit_card_box_service.dart';
import 'package:parion/repositories/kmh_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../property_test_utils.dart';

/// **Feature: statistics-improvements, Property-Based Tests**
/// **Validates: Requirements 1.1, 1.5, 2.1, 5.1, 10.2**
///
/// Property 1: Nakit Akışı Hesaplama Doğruluğu
/// Property 2: Kategori Dağılımı Tutarlılığı
/// Property 4: Net Varlık Hesaplama
/// Property 7: Karşılaştırma Yüzdesi
void main() {
  late StatisticsService statisticsService;
  late DataService dataService;
  late KmhService kmhService;
  late KmhRepository kmhRepository;
  late Directory testDir;

  setUpAll(() async {
    // Create a temporary directory for testing
    testDir = await Directory.systemTemp.createTemp('statistics_test_');
    
    // Initialize Hive with the test directory
    Hive.init(testDir.path);
    
    // Register adapters
    if (!Hive.isAdapterRegistered(31)) {
      Hive.registerAdapter(KmhTransactionTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(30)) {
      Hive.registerAdapter(KmhTransactionAdapter());
    }
    if (!Hive.isAdapterRegistered(10)) {
      Hive.registerAdapter(CreditCardAdapter());
    }
    if (!Hive.isAdapterRegistered(11)) {
      Hive.registerAdapter(CreditCardTransactionAdapter());
    }
    
    // Initialize box services
    await CreditCardBoxService.init();
    await KmhBoxService.init();
  });

  setUp(() async {
    // Initialize SharedPreferences with empty data for each test
    SharedPreferences.setMockInitialValues({});
    
    // Clear boxes before each test
    await CreditCardBoxService.clearAll();
    await KmhBoxService.clearAll();
    
    // Initialize services
    dataService = DataService();
    await dataService.init();
    kmhRepository = KmhRepository();
    kmhService = KmhService(
      dataService: dataService,
      repository: kmhRepository,
    );
    statisticsService = StatisticsService();
  });

  tearDownAll(() async {
    // Clean up
    await CreditCardBoxService.close();
    await KmhBoxService.close();
    await Hive.close();
    if (await testDir.exists()) {
      await testDir.delete(recursive: true);
    }
  });

  group('Property 1: Nakit Akışı Hesaplama Doğruluğu', () {
    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'For any tarih aralığı, toplam gelir ve gider doğru hesaplanmalıdır',
      generator: () {
        // Generate random date range
        final startDate = PropertyTest.randomDateTime(
          start: DateTime(2023, 1, 1),
          end: DateTime(2024, 6, 1),
        );
        final endDate = startDate.add(Duration(
          days: PropertyTest.randomInt(min: 30, max: 365),
        ));
        
        // Generate random transactions
        final numTransactions = PropertyTest.randomInt(min: 5, max: 20);
        final transactions = <Map<String, dynamic>>[];
        double expectedIncome = 0;
        double expectedExpense = 0;
        
        for (int i = 0; i < numTransactions; i++) {
          final isIncome = PropertyTest.randomBool();
          final amount = PropertyTest.randomPositiveDouble(min: 10, max: 5000);
          final transactionDate = PropertyTest.randomDateTime(
            start: startDate,
            end: endDate,
          );
          
          if (isIncome) {
            expectedIncome += amount;
          } else {
            expectedExpense += amount;
          }
          
          transactions.add({
            'isIncome': isIncome,
            'amount': amount,
            'date': transactionDate,
          });
        }
        
        return {
          'startDate': startDate,
          'endDate': endDate,
          'transactions': transactions,
          'expectedIncome': expectedIncome,
          'expectedExpense': expectedExpense,
        };
      },
      property: (data) async {
        final startDate = data['startDate'] as DateTime;
        final endDate = data['endDate'] as DateTime;
        final transactions = data['transactions'] as List<Map<String, dynamic>>;
        final expectedIncome = data['expectedIncome'] as double;
        final expectedExpense = data['expectedExpense'] as double;
        
        // Create test data
        final wallet = await kmhService.createKmhAccount(
          bankName: 'Test KMH',
          creditLimit: 100000,
          interestRate: 24.0,
          initialBalance: 0,
        );
        
        // Add transactions directly with specified dates
        double currentBalance = 0;
        for (var txn in transactions) {
          final amount = txn['amount'] as double;
          final isIncome = txn['isIncome'] as bool;
          final date = txn['date'] as DateTime;
          
          if (isIncome) {
            currentBalance += amount;
          } else {
            currentBalance -= amount;
          }
          
          final kmhTxn = KmhTransaction(
            id: 'txn_${DateTime.now().millisecondsSinceEpoch}_${transactions.indexOf(txn)}',
            walletId: wallet.id,
            amount: amount,
            date: date,
            description: 'Test ${isIncome ? "income" : "expense"}',
            type: isIncome ? KmhTransactionType.deposit : KmhTransactionType.withdrawal,
            balanceAfter: currentBalance,
          );
          await kmhRepository.addTransaction(kmhTxn);
        }
        
        // Calculate cash flow
        final result = await statisticsService.calculateCashFlow(
          startDate: startDate,
          endDate: endDate,
        );
        
        // Verify property: total income = sum of all income transactions
        // and total expense = sum of all expense transactions
        final tolerance = 0.01; // Allow small floating point differences
        final incomeMatches = (result.totalIncome - expectedIncome).abs() < tolerance;
        final expenseMatches = (result.totalExpense - expectedExpense).abs() < tolerance;
        final netFlowMatches = (result.netCashFlow - (expectedIncome - expectedExpense)).abs() < tolerance;
        
        if (!incomeMatches || !expenseMatches || !netFlowMatches) {
          print('Expected: income=$expectedIncome, expense=$expectedExpense');
          print('Got: income=${result.totalIncome}, expense=${result.totalExpense}');
          print('Date range: $startDate to $endDate');
          print('Transactions: ${transactions.length}');
        }
        
        return incomeMatches && expenseMatches && netFlowMatches;
      },
      iterations: 100,
    );
  });

  group('Property 2: Kategori Dağılımı Tutarlılığı', () {
    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'For any harcama analizi, tüm kategorilerin toplamı = toplam harcama olmalıdır',
      generator: () {
        // Generate random date range
        final startDate = PropertyTest.randomDateTime(
          start: DateTime(2023, 1, 1),
          end: DateTime(2024, 6, 1),
        );
        final endDate = startDate.add(Duration(
          days: PropertyTest.randomInt(min: 30, max: 180),
        ));
        
        // Generate random categories and amounts
        final categories = ['Market', 'Ulaşım', 'Eğlence', 'Faturalar', 'Diğer'];
        final categoryAmounts = <String, double>{};
        double totalExpected = 0;
        
        final numTransactions = PropertyTest.randomInt(min: 10, max: 20);
        final transactions = <Map<String, dynamic>>[];
        
        for (int i = 0; i < numTransactions; i++) {
          final category = categories[PropertyTest.randomInt(min: 0, max: categories.length - 1)];
          final amount = PropertyTest.randomPositiveDouble(min: 10, max: 1000);
          final transactionDate = PropertyTest.randomDateTime(
            start: startDate,
            end: endDate,
          );
          
          categoryAmounts[category] = (categoryAmounts[category] ?? 0) + amount;
          totalExpected += amount;
          
          transactions.add({
            'category': category,
            'amount': amount,
            'date': transactionDate,
          });
        }
        
        return {
          'startDate': startDate,
          'endDate': endDate,
          'transactions': transactions,
          'expectedTotal': totalExpected,
          'expectedCategoryAmounts': categoryAmounts,
        };
      },
      property: (data) async {
        final startDate = data['startDate'] as DateTime;
        final endDate = data['endDate'] as DateTime;
        final transactions = data['transactions'] as List<Map<String, dynamic>>;
        final expectedTotal = data['expectedTotal'] as double;
        
        // Create test data - create a credit card
        final ccBox = Hive.box<CreditCard>('credit_cards');
        final card = CreditCard(
          id: 'test_card_${DateTime.now().millisecondsSinceEpoch}',
          bankName: 'Test Bank',
          cardName: 'Test Card',
          last4Digits: '1234',
          creditLimit: 50000,
          statementDay: 15,
          dueDateOffset: 10,
          monthlyInterestRate: 2.5,
          lateInterestRate: 3.5,
          cardColor: 0xFF0000FF,
          createdAt: DateTime.now(),
        );
        await ccBox.put(card.id, card);
        
        // Add transactions
        final ccTxnBox = Hive.box<CreditCardTransaction>('cc_transactions');
        for (var txn in transactions) {
          final ccTxn = CreditCardTransaction(
            id: 'txn_${DateTime.now().millisecondsSinceEpoch}_${transactions.indexOf(txn)}',
            cardId: card.id,
            amount: txn['amount'] as double,
            transactionDate: txn['date'] as DateTime,
            description: 'Test transaction',
            category: txn['category'] as String,
            installmentCount: 1,
            createdAt: DateTime.now(),
          );
          await ccTxnBox.put(ccTxn.id, ccTxn);
        }
        
        // Analyze spending
        final result = await statisticsService.analyzeSpending(
          startDate: startDate,
          endDate: endDate,
        );
        
        // Verify property: sum of all categories = total spending
        final categorySum = result.categoryBreakdown.values.fold<double>(
          0, 
          (sum, amount) => sum + amount,
        );
        
        final tolerance = 0.01;
        final totalMatches = (result.totalSpending - expectedTotal).abs() < tolerance;
        final categorySumMatches = (categorySum - result.totalSpending).abs() < tolerance;
        
        return totalMatches && categorySumMatches;
      },
      iterations: 100,
    );
  });

  group('Property 4: Net Varlık Hesaplama', () {
    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'For any finansal durum, net varlık = toplam varlıklar - toplam borçlar olmalıdır',
      generator: () {
        // Generate random assets and liabilities
        final numWallets = PropertyTest.randomInt(min: 2, max: 5);
        final wallets = <Map<String, dynamic>>[];
        double expectedAssets = 0;
        double expectedLiabilities = 0;
        
        for (int i = 0; i < numWallets; i++) {
          final hasPositiveBalance = PropertyTest.randomBool();
          final balance = hasPositiveBalance
              ? PropertyTest.randomPositiveDouble(min: 100, max: 50000)
              : -PropertyTest.randomPositiveDouble(min: 100, max: 20000);
          
          if (balance > 0) {
            expectedAssets += balance;
          } else {
            expectedLiabilities += balance.abs();
          }
          
          wallets.add({
            'balance': balance,
            'isKmh': PropertyTest.randomBool(),
          });
        }
        
        return {
          'wallets': wallets,
          'expectedAssets': expectedAssets,
          'expectedLiabilities': expectedLiabilities,
          'expectedNetWorth': expectedAssets - expectedLiabilities,
        };
      },
      property: (data) async {
        final wallets = data['wallets'] as List<Map<String, dynamic>>;
        final expectedAssets = data['expectedAssets'] as double;
        final expectedLiabilities = data['expectedLiabilities'] as double;
        final expectedNetWorth = data['expectedNetWorth'] as double;
        
        // Create test data
        for (var walletData in wallets) {
          final isKmh = walletData['isKmh'] as bool;
          final balance = walletData['balance'] as double;
          
          if (isKmh) {
            await kmhService.createKmhAccount(
              bankName: 'Test KMH ${wallets.indexOf(walletData)}',
              creditLimit: 10000,
              interestRate: 24.0,
              initialBalance: balance,
            );
          } else {
            final wallet = Wallet(
              id: 'wallet_${DateTime.now().millisecondsSinceEpoch}_${wallets.indexOf(walletData)}',
              name: 'Test Wallet ${wallets.indexOf(walletData)}',
              balance: balance,
              type: 'cash',
              color: '#FF0000',
              icon: 'wallet',
            );
            await dataService.addWallet(wallet);
          }
        }
        
        // Analyze assets
        final result = await statisticsService.analyzeAssets();
        
        // Verify property: net worth = total assets - total liabilities
        final tolerance = 0.01;
        final assetsMatch = (result.totalAssets - expectedAssets).abs() < tolerance;
        final liabilitiesMatch = (result.totalLiabilities - expectedLiabilities).abs() < tolerance;
        final netWorthMatch = (result.netWorth - expectedNetWorth).abs() < tolerance;
        final calculationMatch = (result.netWorth - (result.totalAssets - result.totalLiabilities)).abs() < tolerance;
        
        return assetsMatch && liabilitiesMatch && netWorthMatch && calculationMatch;
      },
      iterations: 100,
    );
  });

  group('Property 7: Karşılaştırma Yüzdesi', () {
    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'For any dönem karşılaştırması, değişim yüzdesi = ((yeni değer - eski değer) / eski değer) × 100 olmalıdır',
      generator: () {
        // Generate two random periods
        final period1Start = PropertyTest.randomDateTime(
          start: DateTime(2023, 1, 1),
          end: DateTime(2023, 6, 1),
        );
        final period1End = period1Start.add(Duration(days: 30));
        
        final period2Start = period1End.add(Duration(days: 1));
        final period2End = period2Start.add(Duration(days: 30));
        
        // Generate random values for period 1
        final period1Income = PropertyTest.randomPositiveDouble(min: 1000, max: 10000);
        final period1Expense = PropertyTest.randomPositiveDouble(min: 500, max: 8000);
        
        // Generate random values for period 2
        final period2Income = PropertyTest.randomPositiveDouble(min: 1000, max: 10000);
        final period2Expense = PropertyTest.randomPositiveDouble(min: 500, max: 8000);
        
        // Calculate expected percentage changes
        final incomeChange = period1Income != 0 
            ? ((period2Income - period1Income) / period1Income.abs()) * 100
            : (period2Income > 0 ? 100.0 : 0.0);
        
        final expenseChange = period1Expense != 0
            ? ((period2Expense - period1Expense) / period1Expense.abs()) * 100
            : (period2Expense > 0 ? 100.0 : 0.0);
        
        final period1NetFlow = period1Income - period1Expense;
        final period2NetFlow = period2Income - period2Expense;
        final netFlowChange = period1NetFlow != 0
            ? ((period2NetFlow - period1NetFlow) / period1NetFlow.abs()) * 100
            : (period2NetFlow > 0 ? 100.0 : (period2NetFlow < 0 ? -100.0 : 0.0));
        
        return {
          'period1Start': period1Start,
          'period1End': period1End,
          'period2Start': period2Start,
          'period2End': period2End,
          'period1Income': period1Income,
          'period1Expense': period1Expense,
          'period2Income': period2Income,
          'period2Expense': period2Expense,
          'expectedIncomeChange': incomeChange,
          'expectedExpenseChange': expenseChange,
          'expectedNetFlowChange': netFlowChange,
        };
      },
      property: (data) async {
        final period1Start = data['period1Start'] as DateTime;
        final period1End = data['period1End'] as DateTime;
        final period2Start = data['period2Start'] as DateTime;
        final period2End = data['period2End'] as DateTime;
        final period1Income = data['period1Income'] as double;
        final period1Expense = data['period1Expense'] as double;
        final period2Income = data['period2Income'] as double;
        final period2Expense = data['period2Expense'] as double;
        final expectedIncomeChange = data['expectedIncomeChange'] as double;
        final expectedExpenseChange = data['expectedExpenseChange'] as double;
        final expectedNetFlowChange = data['expectedNetFlowChange'] as double;
        
        // Create test data for both periods
        final wallet = await kmhService.createKmhAccount(
          bankName: 'Test KMH',
          creditLimit: 100000,
          interestRate: 24.0,
          initialBalance: 0,
        );
        
        // Add period 1 transactions with specific dates
        double currentBalance = 0;
        
        currentBalance += period1Income;
        final p1IncomeTxn = KmhTransaction(
          id: 'p1_income',
          walletId: wallet.id,
          amount: period1Income,
          date: period1Start.add(Duration(days: 5)),
          description: 'Period 1 Income',
          type: KmhTransactionType.deposit,
          balanceAfter: currentBalance,
        );
        await kmhRepository.addTransaction(p1IncomeTxn);
        
        currentBalance -= period1Expense;
        final p1ExpenseTxn = KmhTransaction(
          id: 'p1_expense',
          walletId: wallet.id,
          amount: period1Expense,
          date: period1Start.add(Duration(days: 10)),
          description: 'Period 1 Expense',
          type: KmhTransactionType.withdrawal,
          balanceAfter: currentBalance,
        );
        await kmhRepository.addTransaction(p1ExpenseTxn);
        
        // Add period 2 transactions with specific dates
        currentBalance += period2Income;
        final p2IncomeTxn = KmhTransaction(
          id: 'p2_income',
          walletId: wallet.id,
          amount: period2Income,
          date: period2Start.add(Duration(days: 5)),
          description: 'Period 2 Income',
          type: KmhTransactionType.deposit,
          balanceAfter: currentBalance,
        );
        await kmhRepository.addTransaction(p2IncomeTxn);
        
        currentBalance -= period2Expense;
        final p2ExpenseTxn = KmhTransaction(
          id: 'p2_expense',
          walletId: wallet.id,
          amount: period2Expense,
          date: period2Start.add(Duration(days: 10)),
          description: 'Period 2 Expense',
          type: KmhTransactionType.withdrawal,
          balanceAfter: currentBalance,
        );
        await kmhRepository.addTransaction(p2ExpenseTxn);
        
        // Compare periods
        final result = await statisticsService.comparePeriods(
          period1Start: period1Start,
          period1End: period1End,
          period2Start: period2Start,
          period2End: period2End,
        );
        
        // Verify property: percentage change = ((new - old) / old) × 100
        final tolerance = 1.0; // Allow 1% tolerance for floating point
        final incomeChangeMatches = (result.income.percentageChange - expectedIncomeChange).abs() < tolerance;
        final expenseChangeMatches = (result.expense.percentageChange - expectedExpenseChange).abs() < tolerance;
        final netFlowChangeMatches = (result.netCashFlow.percentageChange - expectedNetFlowChange).abs() < tolerance;
        
        return incomeChangeMatches && expenseChangeMatches && netFlowChangeMatches;
      },
      iterations: 100,
    );
  });
}
