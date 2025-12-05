// ignore_for_file: deprecated_member_use
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:money/models/credit_card.dart';
import 'package:money/models/credit_card_transaction.dart';
import 'package:money/models/credit_card_statement.dart';
import 'package:money/models/credit_card_payment.dart';
import 'package:money/models/reward_points.dart';
import 'package:money/models/reward_transaction.dart';
import 'package:money/models/limit_alert.dart';
import 'package:money/services/payment_simulator_service.dart';
import 'package:money/services/credit_card_service.dart';
import 'package:money/services/credit_card_box_service.dart';
import '../property_test_utils.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';

/// Property-based tests for PaymentSimulatorService
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  setUpAll(() async {
    // Initialize Hive for testing with a temporary directory
    Hive.init('./test_hive_payment_sim');
    
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
    // Close and delete boxes
    await CreditCardBoxService.close();
    await Hive.deleteFromDisk();
  });

  group('PaymentSimulatorService Property Tests', () {
    late PaymentSimulatorService service;
    late CreditCardService cardService;

    setUp(() async {
      service = PaymentSimulatorService();
      cardService = CreditCardService();
      
      // Clear data before each test
      await CreditCardBoxService.creditCardsBox.clear();
      await CreditCardBoxService.transactionsBox.clear();
      await CreditCardBoxService.statementsBox.clear();
      await CreditCardBoxService.paymentsBox.clear();
    });

    /// Helper function to create a test card with debt
    Future<CreditCard> createTestCardWithDebt({
      required double debt,
      required double interestRate,
    }) async {
      final cardId = const Uuid().v4();
      final card = CreditCard(
        id: cardId,
        bankName: 'Test Bank',
        cardName: 'Test Card',
        last4Digits: '1234',
        creditLimit: 50000,
        statementDay: 15,
        dueDateOffset: 10,
        monthlyInterestRate: interestRate,
        lateInterestRate: interestRate + 1.0,
        cardColor: Colors.blue.value,
        createdAt: DateTime.now(),
        initialDebt: debt,
      );
      
      await cardService.createCard(card);
      return card;
    }

    /// **Feature: enhanced-credit-card-tracking, Property 22: Kalan Borç ve Faiz Hesaplama**
    /// **Validates: Requirements 7.2**
    /// 
    /// Property: For any payment amount, the system should correctly calculate
    /// the remaining debt and interest charged.
    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 22: Remaining debt and interest should be correctly calculated',
      generator: () {
        final debt = PropertyTest.randomPositiveDouble(min: 1000, max: 50000);
        final paymentAmount = PropertyTest.randomPositiveDouble(min: 100, max: debt);
        final interestRate = PropertyTest.randomPositiveDouble(min: 1.0, max: 5.0);
        
        return {
          'debt': debt,
          'paymentAmount': paymentAmount,
          'interestRate': interestRate,
        };
      },
      property: (data) async {
        final debt = data['debt'] as double;
        final paymentAmount = data['paymentAmount'] as double;
        final interestRate = data['interestRate'] as double;

        // Create card with debt
        final card = await createTestCardWithDebt(
          debt: debt,
          interestRate: interestRate,
        );

        // Simulate payment
        final simulation = await service.simulatePayment(
          cardId: card.id,
          paymentAmount: paymentAmount,
        );

        // Property 1: Current debt should match the card's debt
        expect((simulation.currentDebt - debt).abs(), lessThan(0.01));

        // Property 2: Remaining debt = Current debt - Payment amount
        final expectedRemainingDebt = debt - paymentAmount;
        expect((simulation.remainingDebt - expectedRemainingDebt).abs(), lessThan(0.01));

        // Property 3: Interest charged = Remaining debt * (Interest rate / 100)
        final expectedInterest = expectedRemainingDebt * (interestRate / 100);
        expect((simulation.interestCharged - expectedInterest).abs(), lessThan(0.01));

        // Property 4: Remaining debt should be non-negative
        expect(simulation.remainingDebt, greaterThanOrEqualTo(0));

        // Property 5: Interest charged should be non-negative
        expect(simulation.interestCharged, greaterThanOrEqualTo(0));

        // Property 6: If payment equals debt, remaining debt should be zero
        if ((paymentAmount - debt).abs() < 0.01) {
          expect(simulation.remainingDebt, lessThan(0.01));
          expect(simulation.interestCharged, lessThan(0.01));
        }

        // Property 7: Proposed payment should match input
        expect((simulation.proposedPayment - paymentAmount).abs(), lessThan(0.01));

        return true;
      },
      iterations: 100,
    );

    test('Property 22: Zero payment should leave debt unchanged', () async {
      final card = await createTestCardWithDebt(debt: 5000, interestRate: 3.0);
      
      final simulation = await service.simulatePayment(
        cardId: card.id,
        paymentAmount: 0,
      );
      
      expect(simulation.remainingDebt, equals(5000));
      expect(simulation.interestCharged, equals(5000 * 0.03));
    });

    test('Property 22: Payment exceeding debt should be rejected', () async {
      final card = await createTestCardWithDebt(debt: 5000, interestRate: 3.0);
      
      expect(
        () => service.simulatePayment(cardId: card.id, paymentAmount: 6000),
        throwsException,
      );
    });

    test('Property 22: Negative payment should be rejected', () async {
      final card = await createTestCardWithDebt(debt: 5000, interestRate: 3.0);
      
      expect(
        () => service.simulatePayment(cardId: card.id, paymentAmount: -100),
        throwsException,
      );
    });

    /// **Feature: enhanced-credit-card-tracking, Property 23: Asgari Ödeme Faiz Hesaplama**
    /// **Validates: Requirements 7.3**
    /// 
    /// Property: For any minimum payment selection, the system should correctly
    /// calculate the interest applied to the remaining debt.
    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 23: Minimum payment interest should be correctly calculated',
      generator: () {
        final debt = PropertyTest.randomPositiveDouble(min: 1000, max: 50000);
        final interestRate = PropertyTest.randomPositiveDouble(min: 1.0, max: 5.0);
        
        return {
          'debt': debt,
          'interestRate': interestRate,
        };
      },
      property: (data) async {
        final debt = data['debt'] as double;
        final interestRate = data['interestRate'] as double;

        // Create card with debt
        final card = await createTestCardWithDebt(
          debt: debt,
          interestRate: interestRate,
        );

        // Simulate minimum payment
        final simulation = await service.simulateMinimumPayment(card.id);

        // Property 1: Minimum payment should be calculated (typically 33% of debt or minimum 100)
        final expectedMinPayment = debt * 0.33 > 100 ? debt * 0.33 : 100.0;
        final actualMinPayment = simulation['minimumPayment'] as double;
        expect((actualMinPayment - expectedMinPayment).abs(), lessThan(0.01));

        // Property 2: Remaining debt = Current debt - Minimum payment
        final expectedRemainingDebt = debt - actualMinPayment;
        final actualRemainingDebt = simulation['remainingDebt'] as double;
        expect((actualRemainingDebt - expectedRemainingDebt).abs(), lessThan(0.01));

        // Property 3: Interest charged = Remaining debt * (Interest rate / 100)
        final expectedInterest = expectedRemainingDebt * (interestRate / 100);
        final actualInterest = simulation['interestCharged'] as double;
        expect((actualInterest - expectedInterest).abs(), lessThan(0.01));

        // Property 4: Interest should be non-negative
        expect(actualInterest, greaterThanOrEqualTo(0));

        // Property 5: Remaining debt should be less than current debt
        expect(actualRemainingDebt, lessThan(debt));

        // Property 6: Months to payoff should be calculated
        final monthsToPayoff = simulation['monthsToPayoff'] as int;
        expect(monthsToPayoff, greaterThanOrEqualTo(0));

        // Property 7: Total cost should be greater than or equal to current debt
        final totalCost = simulation['totalCost'] as double;
        if (totalCost.isFinite) {
          expect(totalCost, greaterThanOrEqualTo(debt));
        }

        return true;
      },
      iterations: 100,
    );

    test('Property 23: Minimum payment for small debt should be at least 100', () async {
      final card = await createTestCardWithDebt(debt: 200, interestRate: 3.0);
      
      final simulation = await service.simulateMinimumPayment(card.id);
      final minPayment = simulation['minimumPayment'] as double;
      
      // For debt of 200, 33% would be 66, but minimum should be 100
      expect(minPayment, equals(100.0));
    });

    test('Property 23: Minimum payment for large debt should be 33%', () async {
      final card = await createTestCardWithDebt(debt: 10000, interestRate: 3.0);
      
      final simulation = await service.simulateMinimumPayment(card.id);
      final minPayment = simulation['minimumPayment'] as double;
      
      // For debt of 10000, 33% is 3300
      expect((minPayment - 3300).abs(), lessThan(0.01));
    });

    test('Property 23: Zero debt should return zero minimum payment', () async {
      final card = await createTestCardWithDebt(debt: 0, interestRate: 3.0);
      
      final simulation = await service.simulateMinimumPayment(card.id);
      
      expect(simulation['minimumPayment'], equals(0.0));
      expect(simulation['remainingDebt'], equals(0.0));
      expect(simulation['interestCharged'], equals(0.0));
    });

    /// **Feature: enhanced-credit-card-tracking, Property 24: Erken Kapatma Faiz Tasarrufu**
    /// **Validates: Requirements 7.4**
    /// 
    /// Property: For any early payoff simulation, the system should correctly
    /// calculate the interest savings from paying off the entire debt.
    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 24: Early payoff interest savings should be correctly calculated',
      generator: () {
        final debt = PropertyTest.randomPositiveDouble(min: 1000, max: 50000);
        final interestRate = PropertyTest.randomPositiveDouble(min: 1.0, max: 5.0);
        
        return {
          'debt': debt,
          'interestRate': interestRate,
        };
      },
      property: (data) async {
        final debt = data['debt'] as double;
        final interestRate = data['interestRate'] as double;

        // Create card with debt
        final card = await createTestCardWithDebt(
          debt: debt,
          interestRate: interestRate,
        );

        // Simulate early payoff
        final simulation = await service.simulateEarlyPayoff(card.id);

        // Property 1: Early payoff amount should equal current debt
        final earlyPayoffAmount = simulation['earlyPayoffAmount'] as double;
        expect((earlyPayoffAmount - debt).abs(), lessThan(0.01));

        // Property 2: Interest saved should be non-negative
        final interestSaved = simulation['interestSaved'] as double;
        expect(interestSaved, greaterThanOrEqualTo(0));

        // Property 3: Months saved should be non-negative
        final monthsSaved = simulation['monthsSaved'] as int;
        expect(monthsSaved, greaterThanOrEqualTo(0));

        // Property 4: Full payment total cost should equal current debt
        final fullPaymentCost = simulation['fullPaymentTotalCost'] as double;
        expect((fullPaymentCost - debt).abs(), lessThan(0.01));

        // Property 5: Minimum payment total cost should be greater than full payment cost
        final minPaymentCost = simulation['minimumPaymentTotalCost'] as double;
        if (minPaymentCost.isFinite) {
          expect(minPaymentCost, greaterThanOrEqualTo(fullPaymentCost));
        }

        // Property 6: Interest saved = Minimum payment total cost - Full payment cost
        final expectedSavings = minPaymentCost.isFinite ? minPaymentCost - fullPaymentCost : 0.0;
        if (expectedSavings.isFinite) {
          expect((interestSaved - expectedSavings).abs(), lessThan(0.01));
        }

        // Property 7: If debt is small enough that minimum payment covers it, savings might be minimal
        if (debt < 100) {
          // For very small debts, savings might be zero or minimal
          expect(interestSaved, greaterThanOrEqualTo(0));
        }

        return true;
      },
      iterations: 100,
    );

    test('Property 24: Early payoff for zero debt should return zero savings', () async {
      final card = await createTestCardWithDebt(debt: 0, interestRate: 3.0);
      
      final simulation = await service.simulateEarlyPayoff(card.id);
      
      expect(simulation['earlyPayoffAmount'], equals(0.0));
      expect(simulation['interestSaved'], equals(0.0));
      expect(simulation['monthsSaved'], equals(0));
    });

    test('Property 24: Early payoff should always save interest for significant debt', () async {
      final card = await createTestCardWithDebt(debt: 10000, interestRate: 3.0);
      
      final simulation = await service.simulateEarlyPayoff(card.id);
      final interestSaved = simulation['interestSaved'] as double;
      
      // For a debt of 10000 with 3% monthly interest, there should be significant savings
      expect(interestSaved, greaterThan(0));
    });

    test('Property 24: Early payoff savings should increase with higher interest rates', () async {
      final debt = 10000.0;
      
      // Create two cards with different interest rates
      final card1 = await createTestCardWithDebt(debt: debt, interestRate: 2.0);
      final card2 = await createTestCardWithDebt(debt: debt, interestRate: 4.0);
      
      final simulation1 = await service.simulateEarlyPayoff(card1.id);
      final simulation2 = await service.simulateEarlyPayoff(card2.id);
      
      final savings1 = simulation1['interestSaved'] as double;
      final savings2 = simulation2['interestSaved'] as double;
      
      // Higher interest rate should result in higher or equal savings
      // (equal is possible if minimum payment is same for both)
      expect(savings2, greaterThanOrEqualTo(savings1));
      
      // At least one should have positive savings
      expect(savings1 + savings2, greaterThan(0));
    });

    test('Property 24: Early payoff savings should increase with higher debt', () async {
      final interestRate = 3.0;
      
      // Create two cards with different debt amounts
      final card1 = await createTestCardWithDebt(debt: 5000, interestRate: interestRate);
      final card2 = await createTestCardWithDebt(debt: 15000, interestRate: interestRate);
      
      final simulation1 = await service.simulateEarlyPayoff(card1.id);
      final simulation2 = await service.simulateEarlyPayoff(card2.id);
      
      final savings1 = simulation1['interestSaved'] as double;
      final savings2 = simulation2['interestSaved'] as double;
      
      // Higher debt should result in higher savings
      expect(savings2, greaterThan(savings1));
    });

    test('Property 24: Full payment simulation should match early payoff', () async {
      final card = await createTestCardWithDebt(debt: 10000, interestRate: 3.0);
      
      final earlyPayoff = await service.simulateEarlyPayoff(card.id);
      final fullPayment = await service.simulateFullPayment(card.id);
      
      final earlyPayoffAmount = earlyPayoff['earlyPayoffAmount'] as double;
      final fullPaymentAmount = fullPayment['fullPayment'] as double;
      
      // Both should be equal to the current debt
      expect((earlyPayoffAmount - fullPaymentAmount).abs(), lessThan(0.01));
    });

    // Additional integration tests
    test('Compare payment options should return sorted results', () async {
      final card = await createTestCardWithDebt(debt: 10000, interestRate: 3.0);
      
      final paymentAmounts = [1000.0, 3000.0, 5000.0, 8000.0];
      final comparison = await service.comparePaymentOptions(card.id, paymentAmounts);
      
      final comparisons = comparison['comparisons'] as List<Map<String, dynamic>>;
      
      // Should have results for all valid amounts
      expect(comparisons.length, equals(4));
      
      // Results should be sorted by total cost (ascending)
      for (int i = 0; i < comparisons.length - 1; i++) {
        final cost1 = comparisons[i]['totalCost'] as double;
        final cost2 = comparisons[i + 1]['totalCost'] as double;
        expect(cost1, lessThanOrEqualTo(cost2));
      }
    });

    test('Calculate interest savings should work correctly', () async {
      final card = await createTestCardWithDebt(debt: 10000, interestRate: 3.0);
      
      // Calculate savings for paying 5000 instead of minimum
      final savings = await service.calculateInterestSavings(
        cardId: card.id,
        proposedPayment: 5000,
      );
      
      // Savings should be positive since paying more per month
      // results in less total interest paid
      expect(savings, greaterThan(0));
    });

    test('Payment recommendation should provide reasonable suggestions', () async {
      final card = await createTestCardWithDebt(debt: 10000, interestRate: 3.0);
      
      final recommendation = await service.getPaymentRecommendation(card.id);
      
      expect(recommendation['recommendation'], equals('partial_payment'));
      expect(recommendation['currentDebt'], equals(10000));
      
      final minPayment = recommendation['minimumPayment'] as double;
      final recommendedPayment = recommendation['recommendedPayment'] as double;
      final fullPayment = recommendation['fullPayment'] as double;
      
      // Recommended should be between minimum and full
      expect(recommendedPayment, greaterThan(minPayment));
      expect(recommendedPayment, lessThan(fullPayment));
      
      // Recommended should be around 50% of debt
      expect((recommendedPayment - 5000).abs(), lessThan(1.0));
    });
  });
}
