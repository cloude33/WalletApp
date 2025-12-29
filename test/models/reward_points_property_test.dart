import 'package:flutter_test/flutter_test.dart';
import 'package:money/models/reward_points.dart';
import 'package:money/models/credit_card.dart';
import '../property_test_utils.dart';
import 'package:uuid/uuid.dart';

/// **Feature: enhanced-credit-card-tracking, Property 8: Puan Türü Kaydı**
/// **Validates: Requirements 4.1**
/// 
/// Property: For any reward type selection, the system should correctly save
/// the reward type.
void main() {
  group('Reward Points Property Tests', () {
    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 8: Reward type should be correctly saved in RewardPoints',
      generator: () {
        final rewardTypes = ['bonus', 'worldpuan', 'miles', 'cashback'];
        return {
          'id': const Uuid().v4(),
          'cardId': const Uuid().v4(),
          'rewardType': rewardTypes[PropertyTest.randomInt(min: 0, max: rewardTypes.length - 1)],
          'pointsBalance': PropertyTest.randomPositiveDouble(min: 0, max: 100000),
          'conversionRate': PropertyTest.randomPositiveDouble(min: 0.001, max: 10),
          'lastUpdated': PropertyTest.randomDateTime(),
          'createdAt': PropertyTest.randomDateTime(),
        };
      },
      property: (data) {
        // Create a RewardPoints with a reward type
        final rewardPoints = RewardPoints(
          id: data['id'],
          cardId: data['cardId'],
          rewardType: data['rewardType'],
          pointsBalance: data['pointsBalance'],
          conversionRate: data['conversionRate'],
          lastUpdated: data['lastUpdated'],
          createdAt: data['createdAt'],
        );

        // Property: The reward type should be correctly saved
        expect(rewardPoints.rewardType, equals(data['rewardType']));
        
        // Property: The reward type should be one of the valid types
        final validTypes = ['bonus', 'worldpuan', 'miles', 'cashback'];
        expect(validTypes.contains(rewardPoints.rewardType.toLowerCase()), isTrue);
        
        // Property: The reward type should be preserved through copyWith
        final copiedRewardPoints = rewardPoints.copyWith();
        expect(copiedRewardPoints.rewardType, equals(rewardPoints.rewardType));
        
        // Property: Validation should pass for valid reward types
        expect(rewardPoints.validate(), isNull);
        
        return true;
      },
      iterations: 100,
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 8: Reward type should be correctly saved in CreditCard',
      generator: () {
        final rewardTypes = ['bonus', 'worldpuan', 'miles', 'cashback'];
        return {
          'id': const Uuid().v4(),
          'bankName': PropertyTest.randomString(minLength: 3, maxLength: 20),
          'cardName': PropertyTest.randomString(minLength: 3, maxLength: 20),
          'last4Digits': PropertyTest.randomInt(min: 1000, max: 9999).toString(),
          'creditLimit': PropertyTest.randomPositiveDouble(min: 1000, max: 100000),
          'statementDay': PropertyTest.randomInt(min: 1, max: 31),
          'dueDateOffset': PropertyTest.randomInt(min: 5, max: 30),
          'monthlyInterestRate': PropertyTest.randomPositiveDouble(min: 1, max: 10),
          'lateInterestRate': PropertyTest.randomPositiveDouble(min: 1, max: 15),
          'cardColor': PropertyTest.randomInt(min: 0, max: 0xFFFFFFFF),
          'createdAt': PropertyTest.randomDateTime(),
          'rewardType': rewardTypes[PropertyTest.randomInt(min: 0, max: rewardTypes.length - 1)],
        };
      },
      property: (data) {
        // Create a credit card with a reward type
        final card = CreditCard(
          id: data['id'],
          bankName: data['bankName'],
          cardName: data['cardName'],
          last4Digits: data['last4Digits'],
          creditLimit: data['creditLimit'],
          statementDay: data['statementDay'],
          dueDateOffset: data['dueDateOffset'],
          monthlyInterestRate: data['monthlyInterestRate'],
          lateInterestRate: data['lateInterestRate'],
          cardColor: data['cardColor'],
          createdAt: data['createdAt'],
          rewardType: data['rewardType'],
        );

        // Property: The reward type should be correctly saved
        expect(card.rewardType, equals(data['rewardType']));
        
        // Property: The reward type should be one of the valid types
        final validTypes = ['bonus', 'worldpuan', 'miles', 'cashback'];
        expect(validTypes.contains(card.rewardType!.toLowerCase()), isTrue);
        
        // Property: The reward type should be preserved through copyWith
        final copiedCard = card.copyWith();
        expect(copiedCard.rewardType, equals(card.rewardType));
        
        // Property: The reward type should be updatable
        final newRewardType = 'miles';
        final updatedCard = card.copyWith(rewardType: newRewardType);
        expect(updatedCard.rewardType, equals(newRewardType));
        
        return true;
      },
      iterations: 100,
    );

    test('Property 8: Invalid reward types should fail validation', () {
      final invalidRewardPoints = RewardPoints(
        id: const Uuid().v4(),
        cardId: const Uuid().v4(),
        rewardType: 'invalid_type',
        pointsBalance: 100,
        conversionRate: 1.0,
        lastUpdated: DateTime.now(),
        createdAt: DateTime.now(),
      );

      // Property: Invalid reward type should fail validation
      expect(invalidRewardPoints.validate(), isNotNull);
      expect(invalidRewardPoints.validate(), contains('Geçersiz puan türü'));
    });
  });
}
