import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:parion/models/reward_points.dart';
import 'package:parion/models/reward_transaction.dart';
import 'package:parion/models/limit_alert.dart';
import 'package:parion/services/reward_points_service.dart';
import 'package:parion/services/credit_card_box_service.dart';
import '../property_test_utils.dart';
import 'package:uuid/uuid.dart';

/// Property-based tests for RewardPointsService
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  setUpAll(() async {
    // Initialize Hive for testing with a temporary directory
    Hive.init('./test_hive');
    
    // Register adapters
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

  group('RewardPointsService Property Tests', () {
    late RewardPointsService service;

    setUp(() async {
      service = RewardPointsService();
      // Clear data before each test
      await CreditCardBoxService.rewardPointsBox.clear();
      await CreditCardBoxService.rewardTransactionsBox.clear();
    });

    /// **Feature: enhanced-credit-card-tracking, Property 9: Puan Dönüşüm Oranı**
    /// **Validates: Requirements 4.2**
    /// 
    /// Property: For any conversion rate, the system should correctly store
    /// the rate and use it in calculations.
    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 9: Conversion rate should be correctly stored and used in calculations',
      generator: () {
        final rewardTypes = ['bonus', 'worldpuan', 'miles', 'cashback'];
        return {
          'cardId': const Uuid().v4(),
          'rewardType': rewardTypes[PropertyTest.randomInt(min: 0, max: rewardTypes.length - 1)],
          'conversionRate': PropertyTest.randomPositiveDouble(min: 0.001, max: 10.0),
          'pointsBalance': PropertyTest.randomPositiveDouble(min: 0, max: 100000),
        };
      },
      property: (data) async {
        final cardId = data['cardId'] as String;
        final rewardType = data['rewardType'] as String;
        final conversionRate = data['conversionRate'] as double;
        final pointsBalance = data['pointsBalance'] as double;

        // Initialize rewards with a conversion rate
        final rewardPoints = await service.initializeRewards(
          cardId,
          rewardType,
          conversionRate,
        );

        // Property 1: The conversion rate should be correctly stored
        expect(rewardPoints.conversionRate, equals(conversionRate));

        // Property 2: The conversion rate should be retrievable
        final retrieved = await service.getRewardPoints(cardId);
        expect(retrieved, isNotNull);
        expect(retrieved!.conversionRate, equals(conversionRate));

        // Add some points to test calculation
        await service.addPoints(cardId, pointsBalance, 'Test points');

        // Property 3: The conversion rate should be used in currency calculations
        final valueInCurrency = await service.getPointsValueInCurrency(cardId);
        final expectedValue = pointsBalance * conversionRate;
        
        // Use a small epsilon for floating point comparison
        expect((valueInCurrency - expectedValue).abs(), lessThan(0.0001));

        // Property 4: The conversion rate should be preserved through updates
        final summary = await service.getPointsSummary(cardId);
        expect(summary['conversionRate'], equals(conversionRate));

        return true;
      },
      iterations: 100,
    );

    test('Property 9: Zero or negative conversion rate should be rejected', () async {
      final cardId = const Uuid().v4();

      // Test zero conversion rate
      expect(
        () => service.initializeRewards(cardId, 'bonus', 0.0),
        throwsException,
      );

      // Test negative conversion rate
      expect(
        () => service.initializeRewards(cardId, 'bonus', -1.0),
        throwsException,
      );
    });

    test('Property 9: Conversion rate should be updatable', () async {
      final cardId = const Uuid().v4();
      final initialRate = 1.0;
      final newRate = 2.5;

      // Initialize with initial rate
      await service.initializeRewards(cardId, 'bonus', initialRate);

      // Update conversion rate
      await service.updateRewardConfiguration(cardId, conversionRate: newRate);

      // Verify the rate was updated
      final updated = await service.getRewardPoints(cardId);
      expect(updated!.conversionRate, equals(newRate));

      // Add points and verify calculation uses new rate
      await service.addPoints(cardId, 100, 'Test');
      final valueInCurrency = await service.getPointsValueInCurrency(cardId);
      expect(valueInCurrency, equals(100 * newRate));
    });

    /// **Feature: enhanced-credit-card-tracking, Property 10: Otomatik Puan Hesaplama**
    /// **Validates: Requirements 4.3**
    /// 
    /// Property: For any transaction amount, the system should automatically
    /// calculate the earned points correctly.
    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 10: Points should be automatically calculated for transaction amounts',
      generator: () {
        final rewardTypes = ['bonus', 'worldpuan', 'miles', 'cashback'];
        return {
          'cardId': const Uuid().v4(),
          'rewardType': rewardTypes[PropertyTest.randomInt(min: 0, max: rewardTypes.length - 1)],
          'conversionRate': PropertyTest.randomPositiveDouble(min: 0.001, max: 10.0),
          'transactionAmount': PropertyTest.randomPositiveDouble(min: 0.01, max: 100000),
        };
      },
      property: (data) async {
        final cardId = data['cardId'] as String;
        final rewardType = data['rewardType'] as String;
        final conversionRate = data['conversionRate'] as double;
        final transactionAmount = data['transactionAmount'] as double;

        // Initialize rewards
        await service.initializeRewards(cardId, rewardType, conversionRate);

        // Property 1: Calculate points for transaction
        final calculatedPoints = await service.calculatePointsForTransaction(
          cardId,
          transactionAmount,
        );

        // Property 2: Points should be non-negative
        expect(calculatedPoints, greaterThanOrEqualTo(0));

        // Property 3: For positive amounts, points should be positive
        if (transactionAmount > 0) {
          expect(calculatedPoints, greaterThan(0));
        }

        // Property 4: Points calculation should be consistent
        // (calling it twice with same amount should give same result)
        final calculatedPoints2 = await service.calculatePointsForTransaction(
          cardId,
          transactionAmount,
        );
        expect(calculatedPoints2, equals(calculatedPoints));

        // Property 5: Current implementation uses 1:1 ratio (1 TL = 1 point)
        // This is the expected behavior based on the service implementation
        expect(calculatedPoints, equals(transactionAmount));

        // Property 6: Adding points should update balance correctly
        final initialBalance = await service.getPointsBalance(cardId);
        await service.addPoints(cardId, calculatedPoints, 'Transaction points');
        final newBalance = await service.getPointsBalance(cardId);
        
        expect((newBalance - initialBalance - calculatedPoints).abs(), lessThan(0.0001));

        return true;
      },
      iterations: 100,
    );

    test('Property 10: Zero or negative amounts should return zero points', () async {
      final cardId = const Uuid().v4();
      await service.initializeRewards(cardId, 'bonus', 1.0);

      // Test zero amount
      final zeroPoints = await service.calculatePointsForTransaction(cardId, 0);
      expect(zeroPoints, equals(0));

      // Test negative amount
      final negativePoints = await service.calculatePointsForTransaction(cardId, -100);
      expect(negativePoints, equals(0));
    });

    test('Property 10: Points calculation should work for cards without reward system', () async {
      final cardId = const Uuid().v4();
      
      // Don't initialize rewards for this card
      final points = await service.calculatePointsForTransaction(cardId, 100);
      
      // Should return 0 for cards without reward system
      expect(points, equals(0));
    });

    /// **Feature: enhanced-credit-card-tracking, Property 11: Puan Bakiyesi Invariant'ı**
    /// **Validates: Requirements 4.5**
    /// 
    /// Property: For any points usage, the new balance should be calculated
    /// by subtracting the used points from the old balance.
    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 11: Points balance invariant should hold after spending points',
      generator: () {
        final rewardTypes = ['bonus', 'worldpuan', 'miles', 'cashback'];
        final initialBalance = PropertyTest.randomPositiveDouble(min: 100, max: 100000);
        final pointsToSpend = PropertyTest.randomPositiveDouble(min: 1, max: initialBalance);
        
        return {
          'cardId': const Uuid().v4(),
          'rewardType': rewardTypes[PropertyTest.randomInt(min: 0, max: rewardTypes.length - 1)],
          'conversionRate': PropertyTest.randomPositiveDouble(min: 0.001, max: 10.0),
          'initialBalance': initialBalance,
          'pointsToSpend': pointsToSpend,
        };
      },
      property: (data) async {
        final cardId = data['cardId'] as String;
        final rewardType = data['rewardType'] as String;
        final conversionRate = data['conversionRate'] as double;
        final initialBalance = data['initialBalance'] as double;
        final pointsToSpend = data['pointsToSpend'] as double;

        // Initialize rewards
        await service.initializeRewards(cardId, rewardType, conversionRate);

        // Add initial balance
        await service.addPoints(cardId, initialBalance, 'Initial balance');

        // Get balance before spending
        final balanceBefore = await service.getPointsBalance(cardId);
        expect((balanceBefore - initialBalance).abs(), lessThan(0.0001));

        // Spend points
        await service.spendPoints(cardId, pointsToSpend, 'Test spending');

        // Get balance after spending
        final balanceAfter = await service.getPointsBalance(cardId);

        // Property 1: New balance = Old balance - Points spent (Invariant)
        final expectedBalance = balanceBefore - pointsToSpend;
        expect((balanceAfter - expectedBalance).abs(), lessThan(0.0001));

        // Property 2: Balance should never be negative
        expect(balanceAfter, greaterThanOrEqualTo(0));

        // Property 3: Balance should decrease by exactly the amount spent
        final decrease = balanceBefore - balanceAfter;
        expect((decrease - pointsToSpend).abs(), lessThan(0.0001));

        // Property 4: Transaction history should reflect the spending
        final transactions = await service.getPointsHistory(cardId);
        final spendingTransactions = transactions.where((t) => t.isSpending).toList();
        expect(spendingTransactions.isNotEmpty, isTrue);
        
        final lastSpending = spendingTransactions.first;
        expect((lastSpending.pointsSpent - pointsToSpend).abs(), lessThan(0.0001));

        return true;
      },
      iterations: 100,
    );

    test('Property 11: Cannot spend more points than available', () async {
      final cardId = const Uuid().v4();
      await service.initializeRewards(cardId, 'bonus', 1.0);
      
      // Add 100 points
      await service.addPoints(cardId, 100, 'Test');
      
      // Try to spend 200 points (more than available)
      expect(
        () => service.spendPoints(cardId, 200, 'Test'),
        throwsException,
      );
      
      // Balance should remain unchanged
      final balance = await service.getPointsBalance(cardId);
      expect(balance, equals(100));
    });

    test('Property 11: Multiple operations should maintain balance invariant', () async {
      final cardId = const Uuid().v4();
      await service.initializeRewards(cardId, 'bonus', 1.0);
      
      // Perform multiple operations
      await service.addPoints(cardId, 100, 'Add 1');
      await service.addPoints(cardId, 50, 'Add 2');
      await service.spendPoints(cardId, 30, 'Spend 1');
      await service.addPoints(cardId, 20, 'Add 3');
      await service.spendPoints(cardId, 40, 'Spend 2');
      
      // Expected balance: 100 + 50 - 30 + 20 - 40 = 100
      final balance = await service.getPointsBalance(cardId);
      expect(balance, equals(100));
      
      // Verify transaction history
      final transactions = await service.getPointsHistory(cardId);
      expect(transactions.length, equals(5));
      
      // Calculate balance from transactions
      final totalEarned = transactions.fold<double>(0, (sum, t) => sum + t.pointsEarned);
      final totalSpent = transactions.fold<double>(0, (sum, t) => sum + t.pointsSpent);
      final calculatedBalance = totalEarned - totalSpent;
      
      expect(calculatedBalance, equals(balance));
    });

    test('Property 11: Zero points spending should be rejected', () async {
      final cardId = const Uuid().v4();
      await service.initializeRewards(cardId, 'bonus', 1.0);
      await service.addPoints(cardId, 100, 'Test');
      
      expect(
        () => service.spendPoints(cardId, 0, 'Test'),
        throwsException,
      );
    });

    test('Property 11: Negative points spending should be rejected', () async {
      final cardId = const Uuid().v4();
      await service.initializeRewards(cardId, 'bonus', 1.0);
      await service.addPoints(cardId, 100, 'Test');
      
      expect(
        () => service.spendPoints(cardId, -10, 'Test'),
        throwsException,
      );
    });
  });
}
