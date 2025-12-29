import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:money/models/wallet.dart';
import 'package:money/services/payment_planner_service.dart';
import 'package:money/services/kmh_interest_calculator.dart';
import '../property_test_utils.dart';

/// Property-based tests for Payment Plan Calculation
/// 
/// These tests verify Property 25: Payment Plan Calculation
/// Validates: Requirements 7.1, 7.2
void main() {
  group('Payment Plan Calculation Property Tests', () {
    late PaymentPlannerService service;
    late KmhInterestCalculator calculator;
    late Directory testDir;

    setUpAll(() async {
      // Create a temporary directory for testing
      testDir = await Directory.systemTemp.createTemp('payment_plan_test_');
      
      // Initialize Hive with the test directory
      Hive.init(testDir.path);
    });

    setUp(() {
      calculator = KmhInterestCalculator();
      service = PaymentPlannerService(calculator: calculator);
    });

    tearDownAll(() async {
      await Hive.close();
      // Clean up test directory
      if (await testDir.exists()) {
        await testDir.delete(recursive: true);
      }
    });

    // Feature: kmh-account-management, Property 25: Ödeme Planı Hesaplama
    // Validates: Requirements 7.1, 7.2
    PropertyTest.forAll<Map<String, double>>(
      description: 'property: payment plan calculation is mathematically correct',
      generator: () {
        // Generate random debt and monthly payment
        // Debt: 1,000 - 50,000 TL
        final debt = PropertyTest.randomPositiveDouble(min: 1000.0, max: 50000.0);
        
        // Annual rate: 10% - 50%
        final annualRate = PropertyTest.randomPositiveDouble(min: 10.0, max: 50.0);
        
        // Calculate monthly interest to ensure payment is sufficient
        final monthlyInterest = calculator.estimateMonthlyInterest(
          balance: -debt,
          annualRate: annualRate,
          days: 30,
        );
        
        // Monthly payment: must be more than monthly interest
        // Generate between 1.1x to 5x the monthly interest
        final multiplier = 1.1 + PropertyTest.randomPositiveDouble(min: 0.0, max: 3.9);
        final monthlyPayment = monthlyInterest * multiplier;
        
        return {
          'debt': debt,
          'monthlyPayment': monthlyPayment,
          'annualRate': annualRate,
        };
      },
      property: (data) {
        final debt = data['debt']!;
        final monthlyPayment = data['monthlyPayment']!;
        final annualRate = data['annualRate']!;
        
        // Create a test KMH account
        final account = Wallet(
          id: 'test-wallet',
          name: 'Test KMH',
          type: 'bank',
          balance: -debt, // Negative balance = debt
          creditLimit: debt * 2, // Ensure it's a KMH account
          interestRate: annualRate,
          color: '#FF0000',
          icon: 'bank',
        );
        
        // Calculate payment plan
        final plan = service.calculatePaymentPlan(
          account: account,
          monthlyPayment: monthlyPayment,
        );
        
        // Plan should be created
        if (plan == null) {
          return false;
        }
        
        // Verify basic properties
        if (plan.initialDebt != debt) return false;
        if (plan.monthlyPayment != monthlyPayment) return false;
        if (plan.annualRate != annualRate) return false;
        
        // Verify mathematical correctness by simulating the payment schedule
        double remainingDebt = debt;
        double totalInterestPaid = 0.0;
        int monthsSimulated = 0;
        const maxMonths = 1200; // Safety limit
        
        while (remainingDebt > 0.01 && monthsSimulated < maxMonths) {
          // Calculate interest for this month
          final monthlyInterest = calculator.estimateMonthlyInterest(
            balance: -remainingDebt,
            annualRate: annualRate,
            days: 30,
          );
          
          // Add interest to debt
          remainingDebt += monthlyInterest;
          totalInterestPaid += monthlyInterest;
          
          // Apply payment
          if (monthlyPayment >= remainingDebt) {
            // Final payment
            remainingDebt = 0;
          } else {
            remainingDebt -= monthlyPayment;
          }
          
          monthsSimulated++;
        }
        
        // Verify the calculated values match our simulation
        // Allow small tolerance for floating point arithmetic
        const tolerance = 1.0; // 1 TL tolerance
        const monthTolerance = 1; // 1 month tolerance
        
        final durationMatch = (plan.durationMonths - monthsSimulated).abs() <= monthTolerance;
        final interestMatch = (plan.totalInterest - totalInterestPaid).abs() <= tolerance;
        final totalMatch = (plan.totalPayment - (debt + totalInterestPaid)).abs() <= tolerance;
        
        // All three must match
        return durationMatch && interestMatch && totalMatch;
      },
      iterations: 100,
    );

    // Additional property: total payment equals initial debt plus total interest
    PropertyTest.forAll<Map<String, double>>(
      description: 'property: total payment equals initial debt plus total interest',
      generator: () {
        final debt = PropertyTest.randomPositiveDouble(min: 1000.0, max: 50000.0);
        final annualRate = PropertyTest.randomPositiveDouble(min: 10.0, max: 50.0);
        
        final monthlyInterest = calculator.estimateMonthlyInterest(
          balance: -debt,
          annualRate: annualRate,
          days: 30,
        );
        
        final multiplier = 1.1 + PropertyTest.randomPositiveDouble(min: 0.0, max: 3.9);
        final monthlyPayment = monthlyInterest * multiplier;
        
        return {
          'debt': debt,
          'monthlyPayment': monthlyPayment,
          'annualRate': annualRate,
        };
      },
      property: (data) {
        final debt = data['debt']!;
        final monthlyPayment = data['monthlyPayment']!;
        final annualRate = data['annualRate']!;
        
        final account = Wallet(
          id: 'test-wallet',
          name: 'Test KMH',
          type: 'bank',
          balance: -debt,
          creditLimit: debt * 2,
          interestRate: annualRate,
          color: '#FF0000',
          icon: 'bank',
        );
        
        final plan = service.calculatePaymentPlan(
          account: account,
          monthlyPayment: monthlyPayment,
        );
        
        if (plan == null) return false;
        
        // Property: totalPayment = initialDebt + totalInterest
        const tolerance = 0.01;
        final expected = plan.initialDebt + plan.totalInterest;
        final difference = (plan.totalPayment - expected).abs();
        
        return difference < tolerance;
      },
      iterations: 100,
    );

    // Property: insufficient payment returns null
    PropertyTest.forAll<Map<String, double>>(
      description: 'property: insufficient monthly payment returns null plan',
      generator: () {
        final debt = PropertyTest.randomPositiveDouble(min: 1000.0, max: 50000.0);
        final annualRate = PropertyTest.randomPositiveDouble(min: 10.0, max: 50.0);
        
        // Calculate monthly interest
        final monthlyInterest = calculator.estimateMonthlyInterest(
          balance: -debt,
          annualRate: annualRate,
          days: 30,
        );
        
        // Generate payment that is less than or equal to monthly interest
        // This should make the plan impossible
        final insufficientPayment = monthlyInterest * PropertyTest.randomPositiveDouble(min: 0.1, max: 1.0);
        
        return {
          'debt': debt,
          'monthlyPayment': insufficientPayment,
          'annualRate': annualRate,
        };
      },
      property: (data) {
        final debt = data['debt']!;
        final monthlyPayment = data['monthlyPayment']!;
        final annualRate = data['annualRate']!;
        
        final account = Wallet(
          id: 'test-wallet',
          name: 'Test KMH',
          type: 'bank',
          balance: -debt,
          creditLimit: debt * 2,
          interestRate: annualRate,
          color: '#FF0000',
          icon: 'bank',
        );
        
        final plan = service.calculatePaymentPlan(
          account: account,
          monthlyPayment: monthlyPayment,
        );
        
        // Property: insufficient payment should return null
        return plan == null;
      },
      iterations: 100,
    );

    // Property: higher monthly payment results in shorter duration
    PropertyTest.forAll<Map<String, double>>(
      description: 'property: higher monthly payment results in shorter duration',
      generator: () {
        final debt = PropertyTest.randomPositiveDouble(min: 5000.0, max: 30000.0);
        final annualRate = PropertyTest.randomPositiveDouble(min: 15.0, max: 40.0);
        
        final monthlyInterest = calculator.estimateMonthlyInterest(
          balance: -debt,
          annualRate: annualRate,
          days: 30,
        );
        
        // Generate two different payment amounts
        final payment1 = monthlyInterest * (1.5 + PropertyTest.randomPositiveDouble(min: 0.0, max: 1.0));
        final payment2 = payment1 * (1.2 + PropertyTest.randomPositiveDouble(min: 0.0, max: 0.8));
        
        return {
          'debt': debt,
          'payment1': payment1,
          'payment2': payment2,
          'annualRate': annualRate,
        };
      },
      property: (data) {
        final debt = data['debt']!;
        final payment1 = data['payment1']!;
        final payment2 = data['payment2']!;
        final annualRate = data['annualRate']!;
        
        final account = Wallet(
          id: 'test-wallet',
          name: 'Test KMH',
          type: 'bank',
          balance: -debt,
          creditLimit: debt * 2,
          interestRate: annualRate,
          color: '#FF0000',
          icon: 'bank',
        );
        
        final plan1 = service.calculatePaymentPlan(
          account: account,
          monthlyPayment: payment1,
        );
        
        final plan2 = service.calculatePaymentPlan(
          account: account,
          monthlyPayment: payment2,
        );
        
        if (plan1 == null || plan2 == null) return false;
        
        // Property: higher payment should result in shorter duration
        return plan2.durationMonths < plan1.durationMonths;
      },
      iterations: 100,
    );

    // Property: higher monthly payment results in lower total interest
    PropertyTest.forAll<Map<String, double>>(
      description: 'property: higher monthly payment results in lower total interest',
      generator: () {
        final debt = PropertyTest.randomPositiveDouble(min: 5000.0, max: 30000.0);
        final annualRate = PropertyTest.randomPositiveDouble(min: 15.0, max: 40.0);
        
        final monthlyInterest = calculator.estimateMonthlyInterest(
          balance: -debt,
          annualRate: annualRate,
          days: 30,
        );
        
        final payment1 = monthlyInterest * (1.5 + PropertyTest.randomPositiveDouble(min: 0.0, max: 1.0));
        final payment2 = payment1 * (1.2 + PropertyTest.randomPositiveDouble(min: 0.0, max: 0.8));
        
        return {
          'debt': debt,
          'payment1': payment1,
          'payment2': payment2,
          'annualRate': annualRate,
        };
      },
      property: (data) {
        final debt = data['debt']!;
        final payment1 = data['payment1']!;
        final payment2 = data['payment2']!;
        final annualRate = data['annualRate']!;
        
        final account = Wallet(
          id: 'test-wallet',
          name: 'Test KMH',
          type: 'bank',
          balance: -debt,
          creditLimit: debt * 2,
          interestRate: annualRate,
          color: '#FF0000',
          icon: 'bank',
        );
        
        final plan1 = service.calculatePaymentPlan(
          account: account,
          monthlyPayment: payment1,
        );
        
        final plan2 = service.calculatePaymentPlan(
          account: account,
          monthlyPayment: payment2,
        );
        
        if (plan1 == null || plan2 == null) return false;
        
        // Property: higher payment should result in lower total interest
        return plan2.totalInterest < plan1.totalInterest;
      },
      iterations: 100,
    );

    // Edge case: zero debt should return null
    test('edge case: zero debt returns null plan', () {
      final account = Wallet(
        id: 'test-wallet',
        name: 'Test KMH',
        type: 'bank',
        balance: 0.0,
        creditLimit: 10000.0,
        interestRate: 24.0,
        color: '#FF0000',
        icon: 'bank',
      );
      
      final plan = service.calculatePaymentPlan(
        account: account,
        monthlyPayment: 1000.0,
      );
      
      expect(plan, isNull);
    });

    // Edge case: positive balance (no debt) should return null
    test('edge case: positive balance returns null plan', () {
      final account = Wallet(
        id: 'test-wallet',
        name: 'Test KMH',
        type: 'bank',
        balance: 5000.0,
        creditLimit: 10000.0,
        interestRate: 24.0,
        color: '#FF0000',
        icon: 'bank',
      );
      
      final plan = service.calculatePaymentPlan(
        account: account,
        monthlyPayment: 1000.0,
      );
      
      expect(plan, isNull);
    });

    // Edge case: non-KMH account should return null
    test('edge case: non-KMH account returns null plan', () {
      final account = Wallet(
        id: 'test-wallet',
        name: 'Test Regular',
        type: 'bank',
        balance: -5000.0,
        creditLimit: 0.0, // Not a KMH account
        interestRate: 0.0,
        color: '#FF0000',
        icon: 'bank',
      );
      
      final plan = service.calculatePaymentPlan(
        account: account,
        monthlyPayment: 1000.0,
      );
      
      expect(plan, isNull);
    });
  });
}
