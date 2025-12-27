import 'package:flutter_test/flutter_test.dart';
import 'package:money/models/wallet.dart';
import '../property_test_utils.dart';
import 'package:uuid/uuid.dart';

/// **Feature: kmh-account-management, Property 1: KMH Hesap Tanımlama**
/// **Validates: Requirements 1.1**
/// 
/// Property: For any bank account, if creditLimit > 0, the system should 
/// identify this account as a KMH account.
void main() {
  group('KMH Account Identification Property Tests', () {
    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 1: Bank accounts with creditLimit > 0 should be identified as KMH accounts',
      generator: () {
        return {
          'id': const Uuid().v4(),
          'name': PropertyTest.randomString(minLength: 5, maxLength: 30),
          'balance': PropertyTest.randomDouble(min: -50000, max: 50000),
          'type': 'bank',
          'color': '#${PropertyTest.randomInt(min: 0, max: 0xFFFFFF).toRadixString(16).padLeft(6, '0')}',
          'icon': 'account_balance',
          'creditLimit': PropertyTest.randomPositiveDouble(min: 0.01, max: 100000),
        };
      },
      property: (data) {
        // Create a bank account with creditLimit > 0
        final account = Wallet(
          id: data['id'],
          name: data['name'],
          balance: data['balance'],
          type: data['type'],
          color: data['color'],
          icon: data['icon'],
          creditLimit: data['creditLimit'],
        );

        // Property: Should be identified as KMH account
        expect(account.isKmhAccount, isTrue,
            reason: 'Bank account with creditLimit ${data['creditLimit']} should be KMH');
        
        // Verify the conditions
        expect(account.type, equals('bank'));
        expect(account.creditLimit, greaterThan(0));
        
        return true;
      },
      iterations: 100,
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 1: Bank accounts with creditLimit = 0 should NOT be identified as KMH accounts',
      generator: () {
        return {
          'id': const Uuid().v4(),
          'name': PropertyTest.randomString(minLength: 5, maxLength: 30),
          'balance': PropertyTest.randomDouble(min: -50000, max: 50000),
          'type': 'bank',
          'color': '#${PropertyTest.randomInt(min: 0, max: 0xFFFFFF).toRadixString(16).padLeft(6, '0')}',
          'icon': 'account_balance',
          'creditLimit': 0.0,
        };
      },
      property: (data) {
        // Create a bank account with creditLimit = 0
        final account = Wallet(
          id: data['id'],
          name: data['name'],
          balance: data['balance'],
          type: data['type'],
          color: data['color'],
          icon: data['icon'],
          creditLimit: data['creditLimit'],
        );

        // Property: Should NOT be identified as KMH account
        expect(account.isKmhAccount, isFalse,
            reason: 'Bank account with creditLimit 0 should not be KMH');
        
        // Verify the conditions
        expect(account.type, equals('bank'));
        expect(account.creditLimit, equals(0.0));
        
        return true;
      },
      iterations: 100,
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 1: Non-bank accounts should NOT be identified as KMH accounts regardless of creditLimit',
      generator: () {
        final types = ['cash', 'credit_card'];
        return {
          'id': const Uuid().v4(),
          'name': PropertyTest.randomString(minLength: 5, maxLength: 30),
          'balance': PropertyTest.randomDouble(min: -50000, max: 50000),
          'type': types[PropertyTest.randomInt(min: 0, max: types.length - 1)],
          'color': '#${PropertyTest.randomInt(min: 0, max: 0xFFFFFF).toRadixString(16).padLeft(6, '0')}',
          'icon': 'account_balance_wallet',
          'creditLimit': PropertyTest.randomPositiveDouble(min: 0.01, max: 100000),
        };
      },
      property: (data) {
        // Create a non-bank account with creditLimit > 0
        final account = Wallet(
          id: data['id'],
          name: data['name'],
          balance: data['balance'],
          type: data['type'],
          color: data['color'],
          icon: data['icon'],
          creditLimit: data['creditLimit'],
        );

        // Property: Should NOT be identified as KMH account (not bank type)
        expect(account.isKmhAccount, isFalse,
            reason: 'Non-bank account (${data['type']}) should not be KMH even with creditLimit ${data['creditLimit']}');
        
        // Verify the conditions
        expect(account.type, isNot(equals('bank')));
        expect(account.creditLimit, greaterThan(0));
        
        return true;
      },
      iterations: 100,
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 1: KMH identification should be consistent across operations',
      generator: () {
        return {
          'id': const Uuid().v4(),
          'name': PropertyTest.randomString(minLength: 5, maxLength: 30),
          'balance': PropertyTest.randomDouble(min: -50000, max: 50000),
          'type': 'bank',
          'color': '#${PropertyTest.randomInt(min: 0, max: 0xFFFFFF).toRadixString(16).padLeft(6, '0')}',
          'icon': 'account_balance',
          'creditLimit': PropertyTest.randomPositiveDouble(min: 1000, max: 100000),
          'newBalance': PropertyTest.randomDouble(min: -50000, max: 50000),
        };
      },
      property: (data) {
        // Create a KMH account
        final account = Wallet(
          id: data['id'],
          name: data['name'],
          balance: data['balance'],
          type: data['type'],
          color: data['color'],
          icon: data['icon'],
          creditLimit: data['creditLimit'],
        );

        // Property: Should be identified as KMH account
        expect(account.isKmhAccount, isTrue);
        
        // Update balance (common operation)
        final updatedAccount = account.copyWith(balance: data['newBalance']);
        
        // Property: Should still be identified as KMH account after balance update
        expect(updatedAccount.isKmhAccount, isTrue,
            reason: 'KMH identification should persist after balance update');
        
        // Property: Round-trip through JSON should preserve KMH identification
        final json = account.toJson();
        final restored = Wallet.fromJson(json);
        expect(restored.isKmhAccount, isTrue,
            reason: 'KMH identification should persist after JSON round-trip');
        
        return true;
      },
      iterations: 100,
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 1: Converting regular bank account to KMH should update identification',
      generator: () {
        return {
          'id': const Uuid().v4(),
          'name': PropertyTest.randomString(minLength: 5, maxLength: 30),
          'balance': PropertyTest.randomDouble(min: -50000, max: 50000),
          'type': 'bank',
          'color': '#${PropertyTest.randomInt(min: 0, max: 0xFFFFFF).toRadixString(16).padLeft(6, '0')}',
          'icon': 'account_balance',
          'creditLimit': 0.0,
          'newCreditLimit': PropertyTest.randomPositiveDouble(min: 1000, max: 100000),
        };
      },
      property: (data) {
        // Create a regular bank account (creditLimit = 0)
        final regularAccount = Wallet(
          id: data['id'],
          name: data['name'],
          balance: data['balance'],
          type: data['type'],
          color: data['color'],
          icon: data['icon'],
          creditLimit: data['creditLimit'],
        );

        // Property: Should NOT be identified as KMH account initially
        expect(regularAccount.isKmhAccount, isFalse);
        
        // Convert to KMH by adding credit limit
        final kmhAccount = regularAccount.copyWith(
          creditLimit: data['newCreditLimit'],
        );
        
        // Property: Should now be identified as KMH account
        expect(kmhAccount.isKmhAccount, isTrue,
            reason: 'Account should be identified as KMH after adding creditLimit ${data['newCreditLimit']}');
        
        // Verify the credit limit was updated
        expect(kmhAccount.creditLimit, equals(data['newCreditLimit']));
        expect(kmhAccount.creditLimit, greaterThan(0));
        
        return true;
      },
      iterations: 100,
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 1: Removing credit limit should remove KMH identification',
      generator: () {
        return {
          'id': const Uuid().v4(),
          'name': PropertyTest.randomString(minLength: 5, maxLength: 30),
          'balance': PropertyTest.randomDouble(min: -50000, max: 50000),
          'type': 'bank',
          'color': '#${PropertyTest.randomInt(min: 0, max: 0xFFFFFF).toRadixString(16).padLeft(6, '0')}',
          'icon': 'account_balance',
          'creditLimit': PropertyTest.randomPositiveDouble(min: 1000, max: 100000),
        };
      },
      property: (data) {
        // Create a KMH account
        final kmhAccount = Wallet(
          id: data['id'],
          name: data['name'],
          balance: data['balance'],
          type: data['type'],
          color: data['color'],
          icon: data['icon'],
          creditLimit: data['creditLimit'],
        );

        // Property: Should be identified as KMH account initially
        expect(kmhAccount.isKmhAccount, isTrue);
        
        // Remove credit limit
        final regularAccount = kmhAccount.copyWith(creditLimit: 0.0);
        
        // Property: Should NOT be identified as KMH account anymore
        expect(regularAccount.isKmhAccount, isFalse,
            reason: 'Account should not be identified as KMH after removing credit limit');
        
        // Verify the credit limit was removed
        expect(regularAccount.creditLimit, equals(0.0));
        
        return true;
      },
      iterations: 100,
    );
  });
}
