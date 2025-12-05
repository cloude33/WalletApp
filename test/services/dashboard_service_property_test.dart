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
import 'package:money/services/dashboard_service.dart';
import 'package:money/services/credit_card_box_service.dart';
import 'package:money/repositories/credit_card_repository.dart';
import '../property_test_utils.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';

/// Property-based tests for DashboardService
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  setUpAll(() async {
    // Initialize Hive for testing with a temporary directory
    Hive.init('./test_hive_dashboard');
    
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

  group('DashboardService Property Tests', () {
    late DashboardService service;
    late CreditCardRepository cardRepo;

    setUp(() async {
      service = DashboardService();
      cardRepo = CreditCardRepository();
      
      // Clear cache before each test
      service.clearCache();
      
      // Clear data before each test
      await CreditCardBoxService.creditCardsBox.clear();
      await CreditCardBoxService.transactionsBox.clear();
      await CreditCardBoxService.statementsBox.clear();
      await CreditCardBoxService.paymentsBox.clear();
    });

    /// Helper function to create a test credit card
    CreditCard createTestCard({
      String? id,
      double? creditLimit,
      double? initialDebt,
    }) {
      return CreditCard(
        id: id ?? const Uuid().v4(),
        bankName: PropertyTest.randomString(minLength: 3, maxLength: 15),
        cardName: PropertyTest.randomString(minLength: 3, maxLength: 15),
        last4Digits: PropertyTest.randomInt(min: 1000, max: 9999).toString(),
        creditLimit: creditLimit ?? PropertyTest.randomPositiveDouble(min: 1000, max: 100000),
        statementDay: PropertyTest.randomInt(min: 1, max: 28),
        dueDateOffset: PropertyTest.randomInt(min: 10, max: 20),
        monthlyInterestRate: PropertyTest.randomPositiveDouble(min: 1.0, max: 5.0),
        lateInterestRate: PropertyTest.randomPositiveDouble(min: 2.0, max: 6.0),
        cardColor: Colors.blue.value,
        createdAt: DateTime.now(),
        isActive: true,
        initialDebt: initialDebt ?? 0,
      );
    }

    /// **Feature: enhanced-credit-card-tracking, Property 1: Kullanılabilir Limit Invariant'ı**
    /// **Validates: Requirements 2.2**
    /// 
    /// Property: For any credit card, the available limit should always be
    /// calculated by subtracting the total debt from the total limit.
    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 1: Available limit = Total limit - Total debt (Invariant)',
      generator: () {
        final creditLimit = PropertyTest.randomPositiveDouble(min: 5000, max: 100000);
        final initialDebt = PropertyTest.randomPositiveDouble(min: 0, max: creditLimit * 0.8);
        
        return {
          'cardId': const Uuid().v4(),
          'creditLimit': creditLimit,
          'initialDebt': initialDebt,
        };
      },
      property: (data) async {
        // Clear data for this iteration
        await CreditCardBoxService.creditCardsBox.clear();
        service.clearCache(); // Clear cache for each iteration
        
        final cardId = data['cardId'] as String;
        final creditLimit = data['creditLimit'] as double;
        final initialDebt = data['initialDebt'] as double;

        // Create and save a card with initial debt
        final card = createTestCard(
          id: cardId,
          creditLimit: creditLimit,
          initialDebt: initialDebt,
        );
        await cardRepo.save(card);

        // Get total debt and available credit (force refresh to bypass cache)
        final totalDebt = await service.getTotalDebtAllCards(forceRefresh: true);
        final totalLimit = await service.getTotalLimitAllCards();
        final availableCredit = await service.getTotalAvailableCreditAllCards();

        // Property 1: Available credit = Total limit - Total debt (Invariant)
        final expectedAvailable = totalLimit - totalDebt;
        
        // Debug output
        if ((availableCredit - expectedAvailable).abs() >= 0.01) {
          print('DEBUG: creditLimit=$creditLimit, initialDebt=$initialDebt');
          print('DEBUG: totalLimit=$totalLimit, totalDebt=$totalDebt');
          print('DEBUG: availableCredit=$availableCredit, expectedAvailable=$expectedAvailable');
          print('DEBUG: difference=${(availableCredit - expectedAvailable).abs()}');
        }
        
        expect((availableCredit - expectedAvailable).abs(), lessThan(0.01));

        // Property 2: Available credit should never be negative
        // (though it can be if debt exceeds limit)
        expect(availableCredit, equals(expectedAvailable));

        // Property 3: For a single card, the relationship should hold
        expect((totalLimit - creditLimit).abs(), lessThan(0.01));
        expect((totalDebt - initialDebt).abs(), lessThan(0.01));
        expect((availableCredit - (creditLimit - initialDebt)).abs(), lessThan(0.01));

        return true;
      },
      iterations: 100,
    );

    test('Property 1: Available limit invariant with multiple cards', () async {
      // Create multiple cards with different limits and debts
      final card1 = createTestCard(creditLimit: 10000, initialDebt: 2000);
      final card2 = createTestCard(creditLimit: 20000, initialDebt: 5000);
      final card3 = createTestCard(creditLimit: 15000, initialDebt: 0);

      await cardRepo.save(card1);
      await cardRepo.save(card2);
      await cardRepo.save(card3);

      // Get totals
      final totalLimit = await service.getTotalLimitAllCards();
      final totalDebt = await service.getTotalDebtAllCards();
      final availableCredit = await service.getTotalAvailableCreditAllCards();

      // Verify invariant
      expect(totalLimit, equals(45000)); // 10000 + 20000 + 15000
      expect(totalDebt, equals(7000)); // 2000 + 5000 + 0
      expect(availableCredit, equals(38000)); // 45000 - 7000
      expect(availableCredit, equals(totalLimit - totalDebt));
    });

    test('Property 1: Available limit invariant with no cards', () async {
      // No cards in the system
      final totalLimit = await service.getTotalLimitAllCards();
      final totalDebt = await service.getTotalDebtAllCards();
      final availableCredit = await service.getTotalAvailableCreditAllCards();

      // All should be zero
      expect(totalLimit, equals(0));
      expect(totalDebt, equals(0));
      expect(availableCredit, equals(0));
      expect(availableCredit, equals(totalLimit - totalDebt));
    });

    test('Property 1: Available limit invariant with inactive cards', () async {
      // Create active and inactive cards
      final activeCard = createTestCard(creditLimit: 10000, initialDebt: 2000);
      final inactiveCard = createTestCard(creditLimit: 20000, initialDebt: 5000);
      inactiveCard.isActive = false;

      await cardRepo.save(activeCard);
      await cardRepo.save(inactiveCard);

      // Get totals (should only include active cards)
      final totalLimit = await service.getTotalLimitAllCards();
      final totalDebt = await service.getTotalDebtAllCards();
      final availableCredit = await service.getTotalAvailableCreditAllCards();

      // Verify only active card is counted
      expect(totalLimit, equals(10000));
      expect(totalDebt, equals(2000));
      expect(availableCredit, equals(8000));
      expect(availableCredit, equals(totalLimit - totalDebt));
    });

    /// **Feature: enhanced-credit-card-tracking, Property 50: Dashboard Kullanılabilir Limit**
    /// **Validates: Requirements 14.3**
    /// 
    /// Property: For any dashboard summary calculation, the system should
    /// correctly calculate the total available limit.
    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 50: Dashboard should correctly calculate total available limit',
      generator: () {
        final numCards = PropertyTest.randomInt(min: 1, max: 5);
        final cards = <Map<String, dynamic>>[];
        
        for (int i = 0; i < numCards; i++) {
          final creditLimit = PropertyTest.randomPositiveDouble(min: 5000, max: 50000);
          final initialDebt = PropertyTest.randomPositiveDouble(min: 0, max: creditLimit * 0.9);
          
          cards.add({
            'cardId': const Uuid().v4(),
            'creditLimit': creditLimit,
            'initialDebt': initialDebt,
          });
        }
        
        return {'cards': cards};
      },
      property: (data) async {
        // Clear data for this iteration
        await CreditCardBoxService.creditCardsBox.clear();
        service.clearCache(); // Clear cache for each iteration
        
        final cards = data['cards'] as List<Map<String, dynamic>>;

        // Create and save all cards
        double expectedTotalLimit = 0;
        double expectedTotalDebt = 0;
        
        for (var cardData in cards) {
          final card = createTestCard(
            id: cardData['cardId'] as String,
            creditLimit: cardData['creditLimit'] as double,
            initialDebt: cardData['initialDebt'] as double,
          );
          await cardRepo.save(card);
          
          expectedTotalLimit += cardData['creditLimit'] as double;
          expectedTotalDebt += cardData['initialDebt'] as double;
        }

        final expectedAvailable = expectedTotalLimit - expectedTotalDebt;

        // Get dashboard summary (force refresh to bypass cache)
        final summary = await service.getDashboardSummary(forceRefresh: true);

        // Property 1: Dashboard should include total available credit
        expect(summary.containsKey('totalAvailableCredit'), isTrue);

        // Property 2: Total available credit should be correctly calculated
        final actualAvailable = summary['totalAvailableCredit'] as double;
        expect((actualAvailable - expectedAvailable).abs(), lessThan(0.01));

        // Property 3: Dashboard should include total limit
        expect(summary.containsKey('totalLimit'), isTrue);
        final actualLimit = summary['totalLimit'] as double;
        expect((actualLimit - expectedTotalLimit).abs(), lessThan(0.01));

        // Property 4: Dashboard should include total debt
        expect(summary.containsKey('totalDebt'), isTrue);
        final actualDebt = summary['totalDebt'] as double;
        expect((actualDebt - expectedTotalDebt).abs(), lessThan(0.01));

        // Property 5: Dashboard invariant: available = limit - debt
        expect((actualAvailable - (actualLimit - actualDebt)).abs(), lessThan(0.01));

        // Property 6: Dashboard should include utilization percentage
        expect(summary.containsKey('utilizationPercentage'), isTrue);
        final utilization = summary['utilizationPercentage'] as double;
        
        if (expectedTotalLimit > 0) {
          final expectedUtilization = (expectedTotalDebt / expectedTotalLimit) * 100;
          expect((utilization - expectedUtilization).abs(), lessThan(0.01));
        } else {
          expect(utilization, equals(0));
        }

        return true;
      },
      iterations: 100,
    );

    test('Property 50: Dashboard summary should include all required fields', () async {
      // Create a card
      final card = createTestCard(creditLimit: 10000, initialDebt: 3000);
      await cardRepo.save(card);

      // Get dashboard summary
      final summary = await service.getDashboardSummary();

      // Verify all required fields are present
      expect(summary.containsKey('totalDebt'), isTrue);
      expect(summary.containsKey('totalLimit'), isTrue);
      expect(summary.containsKey('totalAvailableCredit'), isTrue);
      expect(summary.containsKey('utilizationPercentage'), isTrue);
      expect(summary.containsKey('debtDistribution'), isTrue);
      expect(summary.containsKey('limitUtilization'), isTrue);
      expect(summary.containsKey('upcomingPayments'), isTrue);

      // Verify values
      expect(summary['totalDebt'], equals(3000));
      expect(summary['totalLimit'], equals(10000));
      expect(summary['totalAvailableCredit'], equals(7000));
      expect(summary['utilizationPercentage'], equals(30.0));
    });

    test('Property 50: Dashboard with zero limit should handle gracefully', () async {
      // This is an edge case - cards should have positive limits
      // but we test the calculation handles it
      final summary = await service.getDashboardSummary();

      // With no cards, all values should be zero
      expect(summary['totalDebt'], equals(0));
      expect(summary['totalLimit'], equals(0));
      expect(summary['totalAvailableCredit'], equals(0));
      expect(summary['utilizationPercentage'], equals(0));
    });

    test('Property 50: Dashboard debt distribution should sum to total debt', () async {
      // Create multiple cards
      final card1 = createTestCard(creditLimit: 10000, initialDebt: 2000);
      final card2 = createTestCard(creditLimit: 20000, initialDebt: 5000);
      final card3 = createTestCard(creditLimit: 15000, initialDebt: 3000);

      await cardRepo.save(card1);
      await cardRepo.save(card2);
      await cardRepo.save(card3);

      // Get dashboard summary
      final summary = await service.getDashboardSummary();
      final debtDistribution = summary['debtDistribution'] as Map<String, double>;

      // Sum of debt distribution should equal total debt
      final distributionSum = debtDistribution.values.fold<double>(0, (sum, debt) => sum + debt);
      final totalDebt = summary['totalDebt'] as double;

      expect((distributionSum - totalDebt).abs(), lessThan(0.01));
      expect(totalDebt, equals(10000)); // 2000 + 5000 + 3000
    });

    test('Property 50: Dashboard limit utilization should be percentages', () async {
      // Create cards with different utilization levels
      final card1 = createTestCard(creditLimit: 10000, initialDebt: 5000); // 50%
      final card2 = createTestCard(creditLimit: 20000, initialDebt: 16000); // 80%
      final card3 = createTestCard(creditLimit: 15000, initialDebt: 0); // 0%

      await cardRepo.save(card1);
      await cardRepo.save(card2);
      await cardRepo.save(card3);

      // Get dashboard summary
      final summary = await service.getDashboardSummary();
      final limitUtilization = summary['limitUtilization'] as Map<String, double>;

      // All utilization values should be between 0 and 100
      for (var utilization in limitUtilization.values) {
        expect(utilization, greaterThanOrEqualTo(0));
        expect(utilization, lessThanOrEqualTo(100));
      }

      // Verify specific utilizations
      expect(limitUtilization.values.any((u) => (u - 50.0).abs() < 0.01), isTrue);
      expect(limitUtilization.values.any((u) => (u - 80.0).abs() < 0.01), isTrue);
      expect(limitUtilization.values.any((u) => u == 0), isTrue);
    });
  });
}
