import 'package:flutter_test/flutter_test.dart';
import 'package:parion/services/kmh_interest_calculator.dart';
import '../property_test_utils.dart';

/// Property-based tests for KmhInterestCalculator
/// 
/// These tests verify the correctness properties defined in the design document.
void main() {
  group('KmhInterestCalculator Property Tests', () {
    late KmhInterestCalculator calculator;

    setUp(() {
      calculator = KmhInterestCalculator();
    });

    // Feature: kmh-account-management, Property 10: Faiz Hesaplama Koşulu
    // Validates: Requirements 3.1
    PropertyTest.forAll<double>(
      description: 'property: interest calculated only for negative balances',
      generator: () {
        // Generate random balance (can be positive, negative, or zero)
        final isNegative = PropertyTest.randomBool();
        if (isNegative) {
          return -PropertyTest.randomPositiveDouble(min: 0.01, max: 100000.0);
        } else {
          return PropertyTest.randomPositiveDouble(min: 0.0, max: 100000.0);
        }
      },
      property: (balance) {
        final annualRate = 24.0; // Use a fixed rate for this test
        
        // Calculate daily interest using the service
        final interest = calculator.calculateDailyInterest(
          balance: balance,
          annualRate: annualRate,
        );
        
        // Property: interest should be calculated (> 0) only when balance is negative
        if (balance < 0) {
          // For negative balances, interest must be positive
          return interest > 0;
        } else {
          // For positive or zero balances, interest must be zero
          return interest == 0.0;
        }
      },
      iterations: 100,
    );

    // Feature: kmh-account-management, Property 11: Faiz Formülü Doğruluğu
    // Validates: Requirements 3.2
    PropertyTest.forAll<Map<String, double>>(
      description: 'property: daily interest formula accuracy for negative balances',
      generator: () {
        // Generate random negative balance and interest rate
        final balance = -PropertyTest.randomPositiveDouble(min: 1.0, max: 100000.0);
        final annualRate = PropertyTest.randomPositiveDouble(min: 0.1, max: 100.0);
        
        return {
          'balance': balance,
          'annualRate': annualRate,
        };
      },
      property: (data) {
        final balance = data['balance']!;
        final annualRate = data['annualRate']!;
        
        // Calculate daily interest using the service
        final actualInterest = calculator.calculateDailyInterest(
          balance: balance,
          annualRate: annualRate,
        );
        
        // Calculate expected interest using the formula: |balance| × annualRate / 365 / 100
        final expectedInterest = balance.abs() * annualRate / 365 / 100;
        
        // Verify the formula is correct (with small tolerance for floating point)
        final tolerance = 0.0001;
        final difference = (actualInterest - expectedInterest).abs();
        
        return difference < tolerance;
      },
      iterations: 100,
    );


    // Additional test: verify zero interest for positive balances
    PropertyTest.forAll<Map<String, double>>(
      description: 'property: no interest on positive balances',
      generator: () {
        // Generate random positive balance and interest rate
        final balance = PropertyTest.randomPositiveDouble(min: 0.0, max: 100000.0);
        final annualRate = PropertyTest.randomPositiveDouble(min: 0.1, max: 100.0);
        
        return {
          'balance': balance,
          'annualRate': annualRate,
        };
      },
      property: (data) {
        final balance = data['balance']!;
        final annualRate = data['annualRate']!;
        
        // Calculate daily interest using the service
        final actualInterest = calculator.calculateDailyInterest(
          balance: balance,
          annualRate: annualRate,
        );
        
        // For positive balances, interest should always be 0
        return actualInterest == 0.0;
      },
      iterations: 100,
    );

    // Edge case test: verify zero interest for zero balance
    test('property: zero interest for zero balance', () {
      final annualRate = 24.0;
      
      final interest = calculator.calculateDailyInterest(
        balance: 0.0,
        annualRate: annualRate,
      );
      
      expect(interest, equals(0.0));
    });

    // Feature: kmh-account-management, Property 13: Faiz Tahmin Doğruluğu
    // Validates: Requirements 3.5
    PropertyTest.forAll<Map<String, double>>(
      description: 'property: monthly interest estimate equals daily interest × 30',
      generator: () {
        // Generate random negative balance and interest rate
        final balance = -PropertyTest.randomPositiveDouble(min: 1.0, max: 100000.0);
        final annualRate = PropertyTest.randomPositiveDouble(min: 0.1, max: 100.0);
        
        return {
          'balance': balance,
          'annualRate': annualRate,
        };
      },
      property: (data) {
        final balance = data['balance']!;
        final annualRate = data['annualRate']!;
        
        // Calculate monthly interest estimate using the service
        final monthlyInterest = calculator.estimateMonthlyInterest(
          balance: balance,
          annualRate: annualRate,
          days: 30,
        );
        
        // Calculate expected monthly interest: daily interest × 30
        final dailyInterest = calculator.calculateDailyInterest(
          balance: balance,
          annualRate: annualRate,
        );
        final expectedMonthlyInterest = dailyInterest * 30;
        
        // Verify the formula is correct (with small tolerance for floating point)
        final tolerance = 0.0001;
        final difference = (monthlyInterest - expectedMonthlyInterest).abs();
        
        return difference < tolerance;
      },
      iterations: 100,
    );

    // Feature: kmh-account-management, Property 13: Faiz Tahmin Doğruluğu
    // Validates: Requirements 3.5
    PropertyTest.forAll<Map<String, double>>(
      description: 'property: annual interest estimate equals |balance| × annualRate / 100',
      generator: () {
        // Generate random negative balance and interest rate
        final balance = -PropertyTest.randomPositiveDouble(min: 1.0, max: 100000.0);
        final annualRate = PropertyTest.randomPositiveDouble(min: 0.1, max: 100.0);
        
        return {
          'balance': balance,
          'annualRate': annualRate,
        };
      },
      property: (data) {
        final balance = data['balance']!;
        final annualRate = data['annualRate']!;
        
        // Calculate annual interest estimate using the service
        final annualInterest = calculator.estimateAnnualInterest(
          balance: balance,
          annualRate: annualRate,
        );
        
        // Calculate expected annual interest: |balance| × annualRate / 100
        final expectedAnnualInterest = balance.abs() * (annualRate / 100);
        
        // Verify the formula is correct (with small tolerance for floating point)
        final tolerance = 0.0001;
        final difference = (annualInterest - expectedAnnualInterest).abs();
        
        return difference < tolerance;
      },
      iterations: 100,
    );

    // Additional test: verify zero estimates for positive balances
    PropertyTest.forAll<Map<String, double>>(
      description: 'property: no interest estimates for positive balances',
      generator: () {
        // Generate random positive balance and interest rate
        final balance = PropertyTest.randomPositiveDouble(min: 0.0, max: 100000.0);
        final annualRate = PropertyTest.randomPositiveDouble(min: 0.1, max: 100.0);
        
        return {
          'balance': balance,
          'annualRate': annualRate,
        };
      },
      property: (data) {
        final balance = data['balance']!;
        final annualRate = data['annualRate']!;
        
        // Calculate interest estimates using the service
        final monthlyInterest = calculator.estimateMonthlyInterest(
          balance: balance,
          annualRate: annualRate,
        );
        final annualInterest = calculator.estimateAnnualInterest(
          balance: balance,
          annualRate: annualRate,
        );
        
        // For positive balances, all estimates should be 0
        return monthlyInterest == 0.0 && annualInterest == 0.0;
      },
      iterations: 100,
    );
  });
}
