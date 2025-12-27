import 'package:flutter_test/flutter_test.dart';
import 'package:money/models/wallet.dart';
import '../property_test_utils.dart';
import 'package:uuid/uuid.dart';

/// **Feature: kmh-account-management, Property 2: KMH Hesap Veri Bütünlüğü**
/// **Validates: Requirements 1.2**
/// 
/// Property: For any KMH account created, all required fields (bankName, 
/// accountNumber, creditLimit, interestRate) should be saved and when read 
/// back should contain the same values.
void main() {
  group('KMH Account Data Integrity Property Tests', () {
    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 2: KMH account data integrity - all required fields preserved',
      generator: () {
        return {
          'id': const Uuid().v4(),
          'name': PropertyTest.randomString(minLength: 5, maxLength: 30), // Bank name
          'balance': PropertyTest.randomDouble(min: -50000, max: 50000),
          'type': 'bank',
          'color': '#${PropertyTest.randomInt(min: 0, max: 0xFFFFFF).toRadixString(16).padLeft(6, '0')}',
          'icon': 'account_balance',
          'creditLimit': PropertyTest.randomPositiveDouble(min: 1000, max: 100000),
          'interestRate': PropertyTest.randomPositiveDouble(min: 1, max: 50),
          'lastInterestDate': PropertyTest.randomDateTime(),
          'accruedInterest': PropertyTest.randomPositiveDouble(min: 0, max: 10000),
          'accountNumber': PropertyTest.randomInt(min: 100000, max: 999999).toString() + 
                           PropertyTest.randomInt(min: 1000, max: 9999).toString(),
        };
      },
      property: (data) {
        // Create a KMH account (Wallet with type='bank' and creditLimit > 0)
        final kmhAccount = Wallet(
          id: data['id'],
          name: data['name'],
          balance: data['balance'],
          type: data['type'],
          color: data['color'],
          icon: data['icon'],
          creditLimit: data['creditLimit'],
          interestRate: data['interestRate'],
          lastInterestDate: data['lastInterestDate'],
          accruedInterest: data['accruedInterest'],
          accountNumber: data['accountNumber'],
        );

        // Property 1: All required fields should be saved correctly
        expect(kmhAccount.name, equals(data['name']));
        expect(kmhAccount.accountNumber, equals(data['accountNumber']));
        expect(kmhAccount.creditLimit, equals(data['creditLimit']));
        expect(kmhAccount.interestRate, equals(data['interestRate']));
        
        // Property 2: Account should be identified as KMH account
        expect(kmhAccount.isKmhAccount, isTrue);
        
        // Property 3: Round-trip through JSON should preserve all fields
        final json = kmhAccount.toJson();
        final restored = Wallet.fromJson(json);
        
        expect(restored.id, equals(kmhAccount.id));
        expect(restored.name, equals(kmhAccount.name));
        expect(restored.balance, equals(kmhAccount.balance));
        expect(restored.type, equals(kmhAccount.type));
        expect(restored.creditLimit, equals(kmhAccount.creditLimit));
        expect(restored.interestRate, equals(kmhAccount.interestRate));
        expect(restored.accountNumber, equals(kmhAccount.accountNumber));
        expect(restored.accruedInterest, equals(kmhAccount.accruedInterest));
        
        // Property 4: DateTime fields should be preserved (within millisecond precision)
        if (kmhAccount.lastInterestDate != null && restored.lastInterestDate != null) {
          expect(
            restored.lastInterestDate!.difference(kmhAccount.lastInterestDate!).inMilliseconds.abs(),
            lessThan(1000),
          );
        }
        
        // Property 5: copyWith should preserve all fields when no changes
        final copied = kmhAccount.copyWith();
        expect(copied.name, equals(kmhAccount.name));
        expect(copied.accountNumber, equals(kmhAccount.accountNumber));
        expect(copied.creditLimit, equals(kmhAccount.creditLimit));
        expect(copied.interestRate, equals(kmhAccount.interestRate));
        expect(copied.accruedInterest, equals(kmhAccount.accruedInterest));
        
        return true;
      },
      iterations: 100,
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 2: KMH account updates should preserve data integrity',
      generator: () {
        return {
          'id': const Uuid().v4(),
          'name': PropertyTest.randomString(minLength: 5, maxLength: 30),
          'balance': PropertyTest.randomDouble(min: -50000, max: 50000),
          'type': 'bank',
          'color': '#${PropertyTest.randomInt(min: 0, max: 0xFFFFFF).toRadixString(16).padLeft(6, '0')}',
          'icon': 'account_balance',
          'creditLimit': PropertyTest.randomPositiveDouble(min: 1000, max: 100000),
          'interestRate': PropertyTest.randomPositiveDouble(min: 1, max: 50),
          'lastInterestDate': PropertyTest.randomDateTime(),
          'accruedInterest': PropertyTest.randomPositiveDouble(min: 0, max: 10000),
          'accountNumber': PropertyTest.randomInt(min: 100000, max: 999999).toString() + 
                           PropertyTest.randomInt(min: 1000, max: 9999).toString(),
          'newCreditLimit': PropertyTest.randomPositiveDouble(min: 1000, max: 100000),
          'newInterestRate': PropertyTest.randomPositiveDouble(min: 1, max: 50),
        };
      },
      property: (data) {
        // Create initial KMH account
        final kmhAccount = Wallet(
          id: data['id'],
          name: data['name'],
          balance: data['balance'],
          type: data['type'],
          color: data['color'],
          icon: data['icon'],
          creditLimit: data['creditLimit'],
          interestRate: data['interestRate'],
          lastInterestDate: data['lastInterestDate'],
          accruedInterest: data['accruedInterest'],
          accountNumber: data['accountNumber'],
        );

        // Update credit limit and interest rate
        final updated = kmhAccount.copyWith(
          creditLimit: data['newCreditLimit'],
          interestRate: data['newInterestRate'],
        );

        // Property: Updated fields should have new values
        expect(updated.creditLimit, equals(data['newCreditLimit']));
        expect(updated.interestRate, equals(data['newInterestRate']));
        
        // Property: Other fields should remain unchanged
        expect(updated.id, equals(kmhAccount.id));
        expect(updated.name, equals(kmhAccount.name));
        expect(updated.balance, equals(kmhAccount.balance));
        expect(updated.accountNumber, equals(kmhAccount.accountNumber));
        expect(updated.accruedInterest, equals(kmhAccount.accruedInterest));
        
        // Property: Should still be identified as KMH account
        expect(updated.isKmhAccount, isTrue);
        
        return true;
      },
      iterations: 100,
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 2: Non-KMH bank accounts should not be identified as KMH',
      generator: () {
        return {
          'id': const Uuid().v4(),
          'name': PropertyTest.randomString(minLength: 5, maxLength: 30),
          'balance': PropertyTest.randomDouble(min: -50000, max: 50000),
          'type': 'bank',
          'color': '#${PropertyTest.randomInt(min: 0, max: 0xFFFFFF).toRadixString(16).padLeft(6, '0')}',
          'icon': 'account_balance',
          'creditLimit': 0.0, // No credit limit = not KMH
        };
      },
      property: (data) {
        // Create a regular bank account (no credit limit)
        final regularAccount = Wallet(
          id: data['id'],
          name: data['name'],
          balance: data['balance'],
          type: data['type'],
          color: data['color'],
          icon: data['icon'],
          creditLimit: data['creditLimit'],
        );

        // Property: Should NOT be identified as KMH account
        expect(regularAccount.isKmhAccount, isFalse);
        
        // Property: KMH-specific fields should be null or zero
        expect(regularAccount.creditLimit, equals(0.0));
        expect(regularAccount.interestRate, isNull);
        expect(regularAccount.accountNumber, isNull);
        
        return true;
      },
      iterations: 100,
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 2: Non-bank accounts should not be identified as KMH',
      generator: () {
        final types = ['cash', 'credit_card'];
        return {
          'id': const Uuid().v4(),
          'name': PropertyTest.randomString(minLength: 5, maxLength: 30),
          'balance': PropertyTest.randomDouble(min: -50000, max: 50000),
          'type': types[PropertyTest.randomInt(min: 0, max: types.length - 1)],
          'color': '#${PropertyTest.randomInt(min: 0, max: 0xFFFFFF).toRadixString(16).padLeft(6, '0')}',
          'icon': 'account_balance_wallet',
          'creditLimit': PropertyTest.randomPositiveDouble(min: 1000, max: 100000),
        };
      },
      property: (data) {
        // Create a non-bank account (even with credit limit)
        final nonBankAccount = Wallet(
          id: data['id'],
          name: data['name'],
          balance: data['balance'],
          type: data['type'],
          color: data['color'],
          icon: data['icon'],
          creditLimit: data['creditLimit'],
        );

        // Property: Should NOT be identified as KMH account (not bank type)
        expect(nonBankAccount.isKmhAccount, isFalse);
        
        return true;
      },
      iterations: 100,
    );
  });
}
