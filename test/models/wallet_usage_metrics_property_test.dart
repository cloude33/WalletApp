import 'package:flutter_test/flutter_test.dart';
import 'package:parion/models/wallet.dart';
import '../property_test_utils.dart';
import 'package:uuid/uuid.dart';

/// **Feature: kmh-account-management, Property 14: Kullanım Metrikleri Hesaplama**
/// **Validates: Requirements 4.1**
///
/// Property: For any KMH account, usedCredit = |balance| (if negative),
/// availableCredit = creditLimit + balance,
/// utilizationRate = (usedCredit / creditLimit) × 100
void main() {
  group('KMH Usage Metrics Calculation Property Tests', () {
    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 14: Used credit calculation for negative balance',
      generator: () {
        return {
          'id': const Uuid().v4(),
          'name': PropertyTest.randomString(minLength: 5, maxLength: 30),
          'balance': -PropertyTest.randomPositiveDouble(
            min: 1,
            max: 50000,
          ), // Negative balance
          'type': 'bank',
          'color':
              '#${PropertyTest.randomInt(min: 0, max: 0xFFFFFF).toRadixString(16).padLeft(6, '0')}',
          'icon': 'account_balance',
          'creditLimit': PropertyTest.randomPositiveDouble(
            min: 1000,
            max: 100000,
          ),
        };
      },
      property: (data) {
        final account = Wallet(
          id: data['id'],
          name: data['name'],
          balance: data['balance'],
          type: data['type'],
          color: data['color'],
          icon: data['icon'],
          creditLimit: data['creditLimit'],
        );

        // Property: usedCredit = |balance| when balance is negative
        final expectedUsedCredit = data['balance'].abs();
        expect(
          account.usedCredit,
          equals(expectedUsedCredit),
          reason: 'usedCredit should equal |balance| for negative balance',
        );

        return true;
      },
      iterations: 100,
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 14: Used credit should be 0 for positive balance',
      generator: () {
        return {
          'id': const Uuid().v4(),
          'name': PropertyTest.randomString(minLength: 5, maxLength: 30),
          'balance': PropertyTest.randomPositiveDouble(
            min: 0.01,
            max: 50000,
          ), // Positive balance
          'type': 'bank',
          'color':
              '#${PropertyTest.randomInt(min: 0, max: 0xFFFFFF).toRadixString(16).padLeft(6, '0')}',
          'icon': 'account_balance',
          'creditLimit': PropertyTest.randomPositiveDouble(
            min: 1000,
            max: 100000,
          ),
        };
      },
      property: (data) {
        final account = Wallet(
          id: data['id'],
          name: data['name'],
          balance: data['balance'],
          type: data['type'],
          color: data['color'],
          icon: data['icon'],
          creditLimit: data['creditLimit'],
        );

        // Property: usedCredit = 0 when balance is positive
        expect(
          account.usedCredit,
          equals(0.0),
          reason: 'usedCredit should be 0 for positive balance',
        );

        return true;
      },
      iterations: 100,
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 14: Used credit should be 0 for zero balance',
      generator: () {
        return {
          'id': const Uuid().v4(),
          'name': PropertyTest.randomString(minLength: 5, maxLength: 30),
          'balance': 0.0, // Zero balance
          'type': 'bank',
          'color':
              '#${PropertyTest.randomInt(min: 0, max: 0xFFFFFF).toRadixString(16).padLeft(6, '0')}',
          'icon': 'account_balance',
          'creditLimit': PropertyTest.randomPositiveDouble(
            min: 1000,
            max: 100000,
          ),
        };
      },
      property: (data) {
        final account = Wallet(
          id: data['id'],
          name: data['name'],
          balance: data['balance'],
          type: data['type'],
          color: data['color'],
          icon: data['icon'],
          creditLimit: data['creditLimit'],
        );

        // Property: usedCredit = 0 when balance is zero
        expect(
          account.usedCredit,
          equals(0.0),
          reason: 'usedCredit should be 0 for zero balance',
        );

        return true;
      },
      iterations: 100,
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 14: Available credit calculation',
      generator: () {
        return {
          'id': const Uuid().v4(),
          'name': PropertyTest.randomString(minLength: 5, maxLength: 30),
          'balance': PropertyTest.randomDouble(min: -50000, max: 50000),
          'type': 'bank',
          'color':
              '#${PropertyTest.randomInt(min: 0, max: 0xFFFFFF).toRadixString(16).padLeft(6, '0')}',
          'icon': 'account_balance',
          'creditLimit': PropertyTest.randomPositiveDouble(
            min: 1000,
            max: 100000,
          ),
        };
      },
      property: (data) {
        final account = Wallet(
          id: data['id'],
          name: data['name'],
          balance: data['balance'],
          type: data['type'],
          color: data['color'],
          icon: data['icon'],
          creditLimit: data['creditLimit'],
        );

        // Property: availableCredit = creditLimit + balance
        final expectedAvailableCredit = data['creditLimit'] + data['balance'];
        expect(
          account.availableCredit,
          equals(expectedAvailableCredit),
          reason: 'availableCredit should equal creditLimit + balance',
        );

        return true;
      },
      iterations: 100,
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description:
          'Property 14: Utilization rate calculation for negative balance',
      generator: () {
        return {
          'id': const Uuid().v4(),
          'name': PropertyTest.randomString(minLength: 5, maxLength: 30),
          'balance': -PropertyTest.randomPositiveDouble(
            min: 1,
            max: 50000,
          ), // Negative balance
          'type': 'bank',
          'color':
              '#${PropertyTest.randomInt(min: 0, max: 0xFFFFFF).toRadixString(16).padLeft(6, '0')}',
          'icon': 'account_balance',
          'creditLimit': PropertyTest.randomPositiveDouble(
            min: 1000,
            max: 100000,
          ),
        };
      },
      property: (data) {
        final account = Wallet(
          id: data['id'],
          name: data['name'],
          balance: data['balance'],
          type: data['type'],
          color: data['color'],
          icon: data['icon'],
          creditLimit: data['creditLimit'],
        );

        // Property: utilizationRate = (usedCredit / creditLimit) × 100
        final usedCredit = data['balance'].abs();
        final expectedUtilizationRate =
            (usedCredit / data['creditLimit']) * 100;

        expect(
          account.utilizationRate,
          closeTo(expectedUtilizationRate, 0.01),
          reason:
              'utilizationRate should equal (usedCredit / creditLimit) × 100',
        );

        // Verify it's within valid range [0, 100+]
        expect(account.utilizationRate, greaterThanOrEqualTo(0.0));

        return true;
      },
      iterations: 100,
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description:
          'Property 14: Utilization rate should be 0 for positive balance',
      generator: () {
        return {
          'id': const Uuid().v4(),
          'name': PropertyTest.randomString(minLength: 5, maxLength: 30),
          'balance': PropertyTest.randomPositiveDouble(
            min: 0.01,
            max: 50000,
          ), // Positive balance
          'type': 'bank',
          'color':
              '#${PropertyTest.randomInt(min: 0, max: 0xFFFFFF).toRadixString(16).padLeft(6, '0')}',
          'icon': 'account_balance',
          'creditLimit': PropertyTest.randomPositiveDouble(
            min: 1000,
            max: 100000,
          ),
        };
      },
      property: (data) {
        final account = Wallet(
          id: data['id'],
          name: data['name'],
          balance: data['balance'],
          type: data['type'],
          color: data['color'],
          icon: data['icon'],
          creditLimit: data['creditLimit'],
        );

        // Property: utilizationRate = 0 when balance is positive (no credit used)
        expect(
          account.utilizationRate,
          equals(0.0),
          reason: 'utilizationRate should be 0 for positive balance',
        );

        return true;
      },
      iterations: 100,
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description:
          'Property 14: Utilization rate should be 0 for zero credit limit',
      generator: () {
        return {
          'id': const Uuid().v4(),
          'name': PropertyTest.randomString(minLength: 5, maxLength: 30),
          'balance': PropertyTest.randomDouble(min: -50000, max: 50000),
          'type': 'bank',
          'color':
              '#${PropertyTest.randomInt(min: 0, max: 0xFFFFFF).toRadixString(16).padLeft(6, '0')}',
          'icon': 'account_balance',
          'creditLimit': 0.0, // Zero credit limit
        };
      },
      property: (data) {
        final account = Wallet(
          id: data['id'],
          name: data['name'],
          balance: data['balance'],
          type: data['type'],
          color: data['color'],
          icon: data['icon'],
          creditLimit: data['creditLimit'],
        );

        // Property: utilizationRate = 0 when creditLimit is 0 (avoid division by zero)
        expect(
          account.utilizationRate,
          equals(0.0),
          reason: 'utilizationRate should be 0 when creditLimit is 0',
        );

        return true;
      },
      iterations: 100,
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 14: Metrics consistency across balance changes',
      generator: () {
        return {
          'id': const Uuid().v4(),
          'name': PropertyTest.randomString(minLength: 5, maxLength: 30),
          'initialBalance': PropertyTest.randomDouble(min: -50000, max: 50000),
          'type': 'bank',
          'color':
              '#${PropertyTest.randomInt(min: 0, max: 0xFFFFFF).toRadixString(16).padLeft(6, '0')}',
          'icon': 'account_balance',
          'creditLimit': PropertyTest.randomPositiveDouble(
            min: 1000,
            max: 100000,
          ),
          'balanceChange': PropertyTest.randomDouble(min: -10000, max: 10000),
        };
      },
      property: (data) {
        final account = Wallet(
          id: data['id'],
          name: data['name'],
          balance: data['initialBalance'],
          type: data['type'],
          color: data['color'],
          icon: data['icon'],
          creditLimit: data['creditLimit'],
        );

        // Update balance
        final newBalance = data['initialBalance'] + data['balanceChange'];
        final updatedAccount = account.copyWith(balance: newBalance);

        // Property: Metrics should be recalculated correctly after balance change
        final expectedUsedCredit = newBalance < 0 ? newBalance.abs() : 0.0;
        final expectedAvailableCredit = data['creditLimit'] + newBalance;
        final expectedUtilizationRate = data['creditLimit'] > 0
            ? (expectedUsedCredit / data['creditLimit']) * 100
            : 0.0;

        expect(
          updatedAccount.usedCredit,
          equals(expectedUsedCredit),
          reason: 'usedCredit should be recalculated after balance change',
        );
        expect(
          updatedAccount.availableCredit,
          equals(expectedAvailableCredit),
          reason: 'availableCredit should be recalculated after balance change',
        );
        expect(
          updatedAccount.utilizationRate,
          closeTo(expectedUtilizationRate, 0.01),
          reason: 'utilizationRate should be recalculated after balance change',
        );

        return true;
      },
      iterations: 100,
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description:
          'Property 14: Metrics consistency across credit limit changes',
      generator: () {
        return {
          'id': const Uuid().v4(),
          'name': PropertyTest.randomString(minLength: 5, maxLength: 30),
          'balance': PropertyTest.randomDouble(min: -50000, max: 50000),
          'type': 'bank',
          'color':
              '#${PropertyTest.randomInt(min: 0, max: 0xFFFFFF).toRadixString(16).padLeft(6, '0')}',
          'icon': 'account_balance',
          'initialCreditLimit': PropertyTest.randomPositiveDouble(
            min: 1000,
            max: 100000,
          ),
          'newCreditLimit': PropertyTest.randomPositiveDouble(
            min: 1000,
            max: 100000,
          ),
        };
      },
      property: (data) {
        final account = Wallet(
          id: data['id'],
          name: data['name'],
          balance: data['balance'],
          type: data['type'],
          color: data['color'],
          icon: data['icon'],
          creditLimit: data['initialCreditLimit'],
        );

        // Update credit limit
        final updatedAccount = account.copyWith(
          creditLimit: data['newCreditLimit'],
        );

        // Property: usedCredit should remain the same (depends only on balance)
        expect(
          updatedAccount.usedCredit,
          equals(account.usedCredit),
          reason: 'usedCredit should not change when only creditLimit changes',
        );

        // Property: availableCredit should be recalculated
        final expectedAvailableCredit =
            data['newCreditLimit'] + data['balance'];
        expect(
          updatedAccount.availableCredit,
          equals(expectedAvailableCredit),
          reason:
              'availableCredit should be recalculated after creditLimit change',
        );

        // Property: utilizationRate should be recalculated
        final usedCredit = data['balance'] < 0 ? data['balance'].abs() : 0.0;
        final expectedUtilizationRate = data['newCreditLimit'] > 0
            ? (usedCredit / data['newCreditLimit']) * 100
            : 0.0;
        expect(
          updatedAccount.utilizationRate,
          closeTo(expectedUtilizationRate, 0.01),
          reason:
              'utilizationRate should be recalculated after creditLimit change',
        );

        return true;
      },
      iterations: 100,
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 14: Metrics relationship invariants',
      generator: () {
        return {
          'id': const Uuid().v4(),
          'name': PropertyTest.randomString(minLength: 5, maxLength: 30),
          'balance': PropertyTest.randomDouble(min: -50000, max: 50000),
          'type': 'bank',
          'color':
              '#${PropertyTest.randomInt(min: 0, max: 0xFFFFFF).toRadixString(16).padLeft(6, '0')}',
          'icon': 'account_balance',
          'creditLimit': PropertyTest.randomPositiveDouble(
            min: 1000,
            max: 100000,
          ),
        };
      },
      property: (data) {
        final account = Wallet(
          id: data['id'],
          name: data['name'],
          balance: data['balance'],
          type: data['type'],
          color: data['color'],
          icon: data['icon'],
          creditLimit: data['creditLimit'],
        );

        // Property: usedCredit should never be negative
        expect(
          account.usedCredit,
          greaterThanOrEqualTo(0.0),
          reason: 'usedCredit should never be negative',
        );

        // Property: availableCredit = creditLimit - usedCredit (when balance is negative)
        if (data['balance'] < 0) {
          final expectedAvailableCredit =
              data['creditLimit'] - account.usedCredit;
          expect(
            account.availableCredit,
            closeTo(expectedAvailableCredit, 0.01),
            reason:
                'availableCredit should equal creditLimit - usedCredit for negative balance',
          );
        }

        // Property: utilizationRate should never be negative
        expect(
          account.utilizationRate,
          greaterThanOrEqualTo(0.0),
          reason: 'utilizationRate should never be negative',
        );

        // Property: If usedCredit = 0, then utilizationRate = 0
        if (account.usedCredit == 0.0) {
          expect(
            account.utilizationRate,
            equals(0.0),
            reason: 'utilizationRate should be 0 when usedCredit is 0',
          );
        }

        // Property: If usedCredit = creditLimit, then utilizationRate = 100
        if (account.usedCredit == data['creditLimit'] &&
            data['creditLimit'] > 0) {
          expect(
            account.utilizationRate,
            closeTo(100.0, 0.01),
            reason:
                'utilizationRate should be 100 when usedCredit equals creditLimit',
          );
        }

        // Property: If balance is positive, availableCredit > creditLimit
        if (data['balance'] > 0) {
          expect(
            account.availableCredit,
            greaterThan(data['creditLimit']),
            reason:
                'availableCredit should be greater than creditLimit for positive balance',
          );
        }

        // Property: If balance is negative, availableCredit < creditLimit
        if (data['balance'] < 0) {
          expect(
            account.availableCredit,
            lessThan(data['creditLimit']),
            reason:
                'availableCredit should be less than creditLimit for negative balance',
          );
        }

        return true;
      },
      iterations: 100,
    );
  });
}
