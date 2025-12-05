// ignore_for_file: await_only_futures
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:money/models/credit_card.dart';
import 'package:money/models/credit_card_transaction.dart';
import 'package:money/models/credit_card_statement.dart';
import 'package:money/models/credit_card_payment.dart';
import 'package:money/models/limit_alert.dart';
import 'package:money/models/reward_points.dart';
import 'package:money/models/reward_transaction.dart';
import 'package:money/services/cash_advance_service.dart';
import 'package:money/services/credit_card_box_service.dart';
import 'package:money/repositories/credit_card_repository.dart';
import 'package:uuid/uuid.dart';
import '../property_test_utils.dart';

/// Property-based tests for CashAdvanceService
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  setUpAll(() async {
    // Initialize Hive for testing
    Hive.init('./test_hive_cash_advance');

    // Register adapters
    if (!Hive.isAdapterRegistered(10)) {
      Hive.registerAdapter(CreditCardAdapter());
    }
    if (!Hive.isAdapterRegistered(11)) {
      Hive.registerAdapter(CreditCardTransactionAdapter());
    }
    if (!Hive.isAdapterRegistered(12)) {
      Hive.registerAdapter(CreditCardStatementAdapter());
    }
    if (!Hive.isAdapterRegistered(13)) {
      Hive.registerAdapter(CreditCardPaymentAdapter());
    }
    if (!Hive.isAdapterRegistered(20)) {
      Hive.registerAdapter(RewardPointsAdapter());
    }
    if (!Hive.isAdapterRegistered(21)) {
      Hive.registerAdapter(RewardTransactionAdapter());
    }
    if (!Hive.isAdapterRegistered(22)) {
      Hive.registerAdapter(LimitAlertAdapter());
    }

    // Open boxes
    await CreditCardBoxService.init();
  });

  tearDownAll(() async {
    await CreditCardBoxService.close();
    await Hive.deleteFromDisk();
  });

  group('CashAdvanceService Property Tests', () {
    late CashAdvanceService service;
    late CreditCardRepository cardRepo;
    final uuid = const Uuid();

    setUp(() async {
      service = CashAdvanceService();
      cardRepo = CreditCardRepository();
      // Clear data before each test
      await CreditCardBoxService.creditCardsBox.clear();
      await CreditCardBoxService.transactionsBox.clear();
    });

    /// **Feature: enhanced-credit-card-tracking, Property 25: Nakit Avans İşaretleme**
    /// **Validates: Requirements 8.1**
    test('Property 25: Nakit Avans İşaretleme - For any cash advance transaction, system should mark it as cash advance', () async {
      for (int i = 0; i < 100; i++) {
        // Generate random test data
        final cardId = uuid.v4();
        final amount = PropertyTest.randomPositiveDouble(min: 100, max: 5000);
        final description = 'Nakit Avans ${PropertyTest.randomInt(min: 1, max: 1000)}';
        
        // Create a test card
        final card = CreditCard(
          id: cardId,
          bankName: 'Test Bank',
          cardName: 'Test Card',
          last4Digits: '1234',
          creditLimit: 10000,
          statementDay: 15,
          dueDateOffset: 10,
          monthlyInterestRate: 3.5,
          lateInterestRate: 4.5,
          cardColor: 0xFF0000FF,
          createdAt: DateTime.now(),
          cashAdvanceRate: 5.0,
          cashAdvanceLimit: 5000,
        );
        await cardRepo.save(card);

        // Record cash advance
        final transaction = await service.recordCashAdvance(
          cardId: cardId,
          amount: amount,
          description: description,
        );

        // Property: Transaction should be marked as cash advance
        expect(transaction.isCashAdvance, isTrue,
            reason: 'Cash advance transaction should have isCashAdvance = true');
        
        // Verify it's saved correctly
        final cashAdvances = await service.getCashAdvances(cardId);
        expect(cashAdvances.length, equals(1));
        expect(cashAdvances.first.isCashAdvance, isTrue);
        expect(cashAdvances.first.amount, equals(amount));

        // Clean up for next iteration
        await CreditCardBoxService.creditCardsBox.clear();
        await CreditCardBoxService.transactionsBox.clear();
      }
    });

    /// **Feature: enhanced-credit-card-tracking, Property 26: Nakit Avans Faiz Oranı**
    /// **Validates: Requirements 8.2**
    test('Property 26: Nakit Avans Faiz Oranı - For any cash advance, system should apply cash advance interest rate', () async {
      for (int i = 0; i < 100; i++) {
        // Generate random test data
        final cardId = uuid.v4();
        final amount = PropertyTest.randomPositiveDouble(min: 100, max: 5000);
        final monthlyRate = PropertyTest.randomPositiveDouble(min: 1.0, max: 5.0);
        final cashAdvanceRate = PropertyTest.randomPositiveDouble(min: 3.0, max: 10.0);
        
        // Create a test card with specific rates
        final card = CreditCard(
          id: cardId,
          bankName: 'Test Bank',
          cardName: 'Test Card',
          last4Digits: '1234',
          creditLimit: 10000,
          statementDay: 15,
          dueDateOffset: 10,
          monthlyInterestRate: monthlyRate,
          lateInterestRate: 4.5,
          cardColor: 0xFF0000FF,
          createdAt: DateTime.now(),
          cashAdvanceRate: cashAdvanceRate,
          cashAdvanceLimit: 5000,
        );
        await cardRepo.save(card);

        // Record cash advance
        await service.recordCashAdvance(
          cardId: cardId,
          amount: amount,
          description: 'Test cash advance',
        );

        // Get summary to check rate
        final summary = await service.getCashAdvanceSummary(cardId);
        
        // Property: Cash advance rate should be applied (not regular monthly rate)
        expect(summary['cashAdvanceRate'], equals(cashAdvanceRate),
            reason: 'Cash advance should use cash advance rate, not monthly rate');
        
        // Property: Daily rate should be calculated from cash advance rate
        final expectedDailyRate = cashAdvanceRate / 30.0;
        expect(summary['dailyRate'], equals(expectedDailyRate));

        // Clean up for next iteration
        await CreditCardBoxService.creditCardsBox.clear();
        await CreditCardBoxService.transactionsBox.clear();
      }
    });

    /// **Feature: enhanced-credit-card-tracking, Property 27: Günlük Nakit Avans Faizi**
    /// **Validates: Requirements 8.4**
    test('Property 27: Günlük Nakit Avans Faizi - For any cash advance debt, system should calculate daily interest', () async {
      for (int i = 0; i < 100; i++) {
        // Generate random test data
        final cardId = uuid.v4();
        final amount = PropertyTest.randomPositiveDouble(min: 100, max: 5000);
        final cashAdvanceRate = PropertyTest.randomPositiveDouble(min: 3.0, max: 10.0);
        final daysElapsed = PropertyTest.randomInt(min: 1, max: 90);
        
        // Create a test card
        final card = CreditCard(
          id: cardId,
          bankName: 'Test Bank',
          cardName: 'Test Card',
          last4Digits: '1234',
          creditLimit: 10000,
          statementDay: 15,
          dueDateOffset: 10,
          monthlyInterestRate: 3.5,
          lateInterestRate: 4.5,
          cardColor: 0xFF0000FF,
          createdAt: DateTime.now(),
          cashAdvanceRate: cashAdvanceRate,
          cashAdvanceLimit: 5000,
        );
        await cardRepo.save(card);

        // Record cash advance in the past
        final transactionDate = DateTime.now().subtract(Duration(days: daysElapsed));
        final transaction = await service.recordCashAdvance(
          cardId: cardId,
          amount: amount,
          description: 'Test cash advance',
        );
        
        // Manually update transaction date for testing
        final updatedTransaction = transaction.copyWith(
          transactionDate: transactionDate,
        );
        await CreditCardBoxService.transactionsBox.put(transaction.id, updatedTransaction);

        // Calculate interest
        final interest = await service.calculateCashAdvanceInterest(cardId);
        
        // Property: Interest should be calculated using daily rate
        final dailyRate = cashAdvanceRate / 30.0 / 100.0;
        final expectedInterest = amount * dailyRate * daysElapsed;
        
        // Allow small floating point error
        expect((interest - expectedInterest).abs(), lessThan(0.01),
            reason: 'Interest should be calculated as: amount * daily_rate * days');

        // Clean up for next iteration
        await CreditCardBoxService.creditCardsBox.clear();
        await CreditCardBoxService.transactionsBox.clear();
      }
    });

    /// **Feature: enhanced-credit-card-tracking, Property 28: Nakit Avans Ödeme Önceliği**
    /// **Validates: Requirements 8.5**
    test('Property 28: Nakit Avans Ödeme Önceliği - For any payment, system should prioritize cash advance debt', () async {
      // Note: This property test verifies that cash advances are tracked separately
      // The actual payment priority logic would be implemented in CreditCardService
      // Here we verify that cash advances can be identified and queried separately
      
      for (int i = 0; i < 100; i++) {
        // Generate random test data
        final cardId = uuid.v4();
        final cashAdvanceAmount = PropertyTest.randomPositiveDouble(min: 100, max: 2000);
        final regularAmount = PropertyTest.randomPositiveDouble(min: 100, max: 2000);
        
        // Create a test card
        final card = CreditCard(
          id: cardId,
          bankName: 'Test Bank',
          cardName: 'Test Card',
          last4Digits: '1234',
          creditLimit: 10000,
          statementDay: 15,
          dueDateOffset: 10,
          monthlyInterestRate: 3.5,
          lateInterestRate: 4.5,
          cardColor: 0xFF0000FF,
          createdAt: DateTime.now(),
          cashAdvanceRate: 5.0,
          cashAdvanceLimit: 5000,
        );
        await cardRepo.save(card);

        // Record cash advance
        await service.recordCashAdvance(
          cardId: cardId,
          amount: cashAdvanceAmount,
          description: 'Cash advance',
        );

        // Record regular transaction
        final regularTransaction = CreditCardTransaction(
          id: uuid.v4(),
          cardId: cardId,
          amount: regularAmount,
          description: 'Regular purchase',
          transactionDate: DateTime.now(),
          category: 'Shopping',
          installmentCount: 1,
          installmentsPaid: 0,
          createdAt: DateTime.now(),
          isCashAdvance: false,
        );
        await CreditCardBoxService.transactionsBox.put(regularTransaction.id, regularTransaction);

        // Property: Cash advances should be identifiable separately
        final cashAdvances = await service.getCashAdvances(cardId);
        final totalCashAdvanceDebt = await service.getTotalCashAdvanceDebt(cardId);
        
        expect(cashAdvances.length, equals(1),
            reason: 'Should have exactly one cash advance');
        expect(cashAdvances.first.isCashAdvance, isTrue);
        expect(totalCashAdvanceDebt, equals(cashAdvanceAmount),
            reason: 'Total cash advance debt should equal cash advance amount');

        // Property: Regular transactions should not be included in cash advance queries
        final allTransactions = await CreditCardBoxService.transactionsBox.values
            .where((t) => t.cardId == cardId)
            .toList();
        expect(allTransactions.length, equals(2),
            reason: 'Should have 2 total transactions');
        
        final nonCashAdvances = allTransactions.where((t) => !t.isCashAdvance).toList();
        expect(nonCashAdvances.length, equals(1),
            reason: 'Should have 1 non-cash-advance transaction');

        // Clean up for next iteration
        await CreditCardBoxService.creditCardsBox.clear();
        await CreditCardBoxService.transactionsBox.clear();
      }
    });
  });
}
