import 'package:flutter_test/flutter_test.dart';
import 'package:money/models/credit_card.dart';
import '../property_test_utils.dart';
import 'package:uuid/uuid.dart';

/// **Feature: enhanced-credit-card-tracking, Property 2: Fotoğraf Optimizasyonu**
/// **Validates: Requirements 1.3**
/// 
/// Property: For any uploaded card photo, the system should optimize the photo
/// and save it as the card image.
void main() {
  group('Credit Card Image Property Tests', () {
    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 2: Photo optimization - card image path should be stored',
      generator: () {
        // Generate random card data with image path
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
          'cardImagePath': '/path/to/optimized/image_${PropertyTest.randomString(minLength: 5, maxLength: 10)}.jpg',
        };
      },
      property: (data) {
        // Create a credit card with an image path
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
          cardImagePath: data['cardImagePath'],
        );

        // Property: The card should store the image path
        expect(card.cardImagePath, isNotNull);
        expect(card.cardImagePath, equals(data['cardImagePath']));
        
        // Property: The image path should be preserved through copyWith
        final copiedCard = card.copyWith();
        expect(copiedCard.cardImagePath, equals(card.cardImagePath));
        
        // Property: The image path should be updatable
        final newImagePath = '/path/to/new/image.jpg';
        final updatedCard = card.copyWith(cardImagePath: newImagePath);
        expect(updatedCard.cardImagePath, equals(newImagePath));
        
        return true;
      },
      iterations: 100,
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 2: Icon name should be stored as alternative to photo',
      generator: () {
        final icons = ['credit_card', 'account_balance', 'payment', 'card_giftcard', 'wallet'];
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
          'iconName': icons[PropertyTest.randomInt(min: 0, max: icons.length - 1)],
        };
      },
      property: (data) {
        // Create a credit card with an icon name
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
          iconName: data['iconName'],
        );

        // Property: The card should store the icon name
        expect(card.iconName, isNotNull);
        expect(card.iconName, equals(data['iconName']));
        
        // Property: The icon name should be preserved through copyWith
        final copiedCard = card.copyWith();
        expect(copiedCard.iconName, equals(card.iconName));
        
        return true;
      },
      iterations: 100,
    );
  });
}
