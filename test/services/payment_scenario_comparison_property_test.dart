import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:parion/models/wallet.dart';
import 'package:parion/services/payment_planner_service.dart';
import 'package:parion/services/kmh_interest_calculator.dart';
import '../property_test_utils.dart';

/// Property-based tests for Payment Scenario Comparison
/// 
/// These tests verify Property 26: Payment Scenario Comparison
/// Validates: Requirement 7.3
void main() {
  group('Payment Scenario Comparison Property Tests', () {
    late PaymentPlannerService service;
    late KmhInterestCalculator calculator;
    late Directory testDir;

    setUpAll(() async {
      // Create a temporary directory for testing
      testDir = await Directory.systemTemp.createTemp('payment_scenario_test_');
      
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

    // Feature: kmh-account-management, Property 26: Ödeme Senaryoları Karşılaştırma
    // Validates: Requirement 7.3
    PropertyTest.forAll<Map<String, double>>(
      description: 'property: generated scenarios are comparable and have valid duration and cost',
      generator: () {
        // Generate random debt and interest rate
        // Debt: 5,000 - 50,000 TL
        final debt = PropertyTest.randomPositiveDouble(min: 5000.0, max: 50000.0);
        
        // Annual rate: 15% - 40%
        final annualRate = PropertyTest.randomPositiveDouble(min: 15.0, max: 40.0);
        
        return {
          'debt': debt,
          'annualRate': annualRate,
        };
      },
      property: (data) {
        final debt = data['debt']!;
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
        
        // Generate payment scenarios
        final scenarios = service.generatePaymentScenarios(account: account);
        
        // Property 1: Should generate at least one scenario
        if (scenarios.isEmpty) {
          return false;
        }
        
        // Property 2: All scenarios should have valid duration (> 0)
        for (final scenario in scenarios) {
          if (scenario.durationMonths <= 0) {
            return false;
          }
        }
        
        // Property 3: All scenarios should have valid cost calculations
        for (final scenario in scenarios) {
          // Total payment should equal debt + interest
          const tolerance = 1.0;
          final expectedTotal = debt + scenario.totalInterest;
          if ((scenario.totalPayment - expectedTotal).abs() > tolerance) {
            return false;
          }
          
          // Total interest should be non-negative
          if (scenario.totalInterest < 0) {
            return false;
          }
          
          // Monthly payment should be positive
          if (scenario.monthlyPayment <= 0) {
            return false;
          }
        }
        
        // Property 4: Scenarios should be comparable (ordered by monthly payment)
        // Higher monthly payment should result in shorter duration
        if (scenarios.length >= 2) {
          for (int i = 0; i < scenarios.length - 1; i++) {
            final current = scenarios[i];
            final next = scenarios[i + 1];
            
            // If next has higher monthly payment, it should have shorter or equal duration
            if (next.monthlyPayment > current.monthlyPayment) {
              if (next.durationMonths > current.durationMonths) {
                return false;
              }
            }
          }
        }
        
        return true;
      },
      iterations: 100,
    );

    // Property: Higher monthly payment scenarios have lower total interest
    PropertyTest.forAll<Map<String, double>>(
      description: 'property: scenarios with higher monthly payments have lower total interest',
      generator: () {
        final debt = PropertyTest.randomPositiveDouble(min: 10000.0, max: 40000.0);
        final annualRate = PropertyTest.randomPositiveDouble(min: 18.0, max: 35.0);
        
        return {
          'debt': debt,
          'annualRate': annualRate,
        };
      },
      property: (data) {
        final debt = data['debt']!;
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
        
        final scenarios = service.generatePaymentScenarios(account: account);
        
        // Need at least 2 scenarios to compare
        if (scenarios.length < 2) {
          return true; // Skip this iteration
        }
        
        // Sort scenarios by monthly payment
        final sortedScenarios = List.from(scenarios)
          ..sort((a, b) => a.monthlyPayment.compareTo(b.monthlyPayment));
        
        // Property: Each successive scenario (with higher payment) should have
        // lower or equal total interest
        for (int i = 0; i < sortedScenarios.length - 1; i++) {
          final lower = sortedScenarios[i];
          final higher = sortedScenarios[i + 1];
          
          // Higher monthly payment should result in lower total interest
          if (higher.totalInterest > lower.totalInterest) {
            return false;
          }
        }
        
        return true;
      },
      iterations: 100,
    );

    // Property: Scenario comparison provides valid metrics
    PropertyTest.forAll<Map<String, double>>(
      description: 'property: scenario comparison provides mathematically correct metrics',
      generator: () {
        final debt = PropertyTest.randomPositiveDouble(min: 8000.0, max: 35000.0);
        final annualRate = PropertyTest.randomPositiveDouble(min: 16.0, max: 38.0);
        
        return {
          'debt': debt,
          'annualRate': annualRate,
        };
      },
      property: (data) {
        final debt = data['debt']!;
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
        
        final scenarios = service.generatePaymentScenarios(account: account);
        
        // Need at least 2 scenarios to compare
        if (scenarios.length < 2) {
          return true; // Skip this iteration
        }
        
        // Compare first two scenarios
        final scenario1 = scenarios[0];
        final scenario2 = scenarios[1];
        
        final comparison = service.compareScenarios(
          scenario1: scenario1,
          scenario2: scenario2,
        );
        
        // Verify comparison metrics are mathematically correct
        const tolerance = 0.01;
        
        // Monthly difference
        final expectedMonthlyDiff = scenario2.monthlyPayment - scenario1.monthlyPayment;
        if ((comparison['monthlyDifference'] - expectedMonthlyDiff).abs() > tolerance) {
          return false;
        }
        
        // Duration difference
        final expectedDurationDiff = scenario2.durationMonths - scenario1.durationMonths;
        if (comparison['durationDifference'] != expectedDurationDiff) {
          return false;
        }
        
        // Interest difference
        final expectedInterestDiff = scenario2.totalInterest - scenario1.totalInterest;
        if ((comparison['interestDifference'] - expectedInterestDiff).abs() > tolerance) {
          return false;
        }
        
        // Total difference
        final expectedTotalDiff = scenario2.totalPayment - scenario1.totalPayment;
        if ((comparison['totalDifference'] - expectedTotalDiff).abs() > tolerance) {
          return false;
        }
        
        // Percentage savings
        if (scenario2.totalPayment > 0) {
          final expectedPercentage = ((scenario2.totalPayment - scenario1.totalPayment) /
              scenario2.totalPayment * 100);
          if ((comparison['percentageSavings'] - expectedPercentage).abs() > tolerance) {
            return false;
          }
        }
        
        return true;
      },
      iterations: 100,
    );

    // Property: All scenarios for same debt should sum to same initial debt
    PropertyTest.forAll<Map<String, double>>(
      description: 'property: all scenarios pay off the same initial debt',
      generator: () {
        final debt = PropertyTest.randomPositiveDouble(min: 7000.0, max: 30000.0);
        final annualRate = PropertyTest.randomPositiveDouble(min: 17.0, max: 36.0);
        
        return {
          'debt': debt,
          'annualRate': annualRate,
        };
      },
      property: (data) {
        final debt = data['debt']!;
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
        
        final scenarios = service.generatePaymentScenarios(account: account);
        
        if (scenarios.isEmpty) {
          return false;
        }
        
        // Property: All scenarios should pay off the same debt amount
        // totalPayment - totalInterest should equal the initial debt
        const tolerance = 1.0;
        
        for (final scenario in scenarios) {
          final paidDebt = scenario.totalPayment - scenario.totalInterest;
          if ((paidDebt - debt).abs() > tolerance) {
            return false;
          }
        }
        
        return true;
      },
      iterations: 100,
    );

    // Property: Minimum payment scenario has longest duration
    PropertyTest.forAll<Map<String, double>>(
      description: 'property: minimum payment scenario has longest duration',
      generator: () {
        final debt = PropertyTest.randomPositiveDouble(min: 10000.0, max: 40000.0);
        final annualRate = PropertyTest.randomPositiveDouble(min: 18.0, max: 35.0);
        
        return {
          'debt': debt,
          'annualRate': annualRate,
        };
      },
      property: (data) {
        final debt = data['debt']!;
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
        
        final scenarios = service.generatePaymentScenarios(account: account);
        
        if (scenarios.length < 2) {
          return true; // Skip if not enough scenarios
        }
        
        // Find minimum payment scenario (should be first one)
        final minScenario = scenarios.reduce((a, b) => 
          a.monthlyPayment < b.monthlyPayment ? a : b
        );
        
        // Property: Minimum payment scenario should have longest duration
        for (final scenario in scenarios) {
          if (scenario != minScenario) {
            if (scenario.durationMonths > minScenario.durationMonths) {
              return false;
            }
          }
        }
        
        return true;
      },
      iterations: 100,
    );

    // Property: Aggressive payment scenario has shortest duration
    PropertyTest.forAll<Map<String, double>>(
      description: 'property: aggressive payment scenario has shortest duration',
      generator: () {
        final debt = PropertyTest.randomPositiveDouble(min: 10000.0, max: 40000.0);
        final annualRate = PropertyTest.randomPositiveDouble(min: 18.0, max: 35.0);
        
        return {
          'debt': debt,
          'annualRate': annualRate,
        };
      },
      property: (data) {
        final debt = data['debt']!;
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
        
        final scenarios = service.generatePaymentScenarios(account: account);
        
        if (scenarios.length < 2) {
          return true; // Skip if not enough scenarios
        }
        
        // Find aggressive payment scenario (highest monthly payment)
        final aggressiveScenario = scenarios.reduce((a, b) => 
          a.monthlyPayment > b.monthlyPayment ? a : b
        );
        
        // Property: Aggressive payment scenario should have shortest duration
        for (final scenario in scenarios) {
          if (scenario != aggressiveScenario) {
            if (scenario.durationMonths < aggressiveScenario.durationMonths) {
              return false;
            }
          }
        }
        
        return true;
      },
      iterations: 100,
    );

    // Edge case: Zero debt returns empty scenarios
    test('edge case: zero debt returns empty scenarios', () {
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
      
      final scenarios = service.generatePaymentScenarios(account: account);
      
      expect(scenarios, isEmpty);
    });

    // Edge case: Positive balance returns empty scenarios
    test('edge case: positive balance returns empty scenarios', () {
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
      
      final scenarios = service.generatePaymentScenarios(account: account);
      
      expect(scenarios, isEmpty);
    });

    // Edge case: Non-KMH account returns empty scenarios
    test('edge case: non-KMH account returns empty scenarios', () {
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
      
      final scenarios = service.generatePaymentScenarios(account: account);
      
      expect(scenarios, isEmpty);
    });

    // Edge case: Very small debt generates valid scenarios
    test('edge case: very small debt generates valid scenarios', () {
      final account = Wallet(
        id: 'test-wallet',
        name: 'Test KMH',
        type: 'bank',
        balance: -100.0,
        creditLimit: 10000.0,
        interestRate: 24.0,
        color: '#FF0000',
        icon: 'bank',
      );
      
      final scenarios = service.generatePaymentScenarios(account: account);
      
      // Should generate at least one scenario
      expect(scenarios.isNotEmpty, isTrue);
      
      // All scenarios should have valid values
      for (final scenario in scenarios) {
        expect(scenario.durationMonths, greaterThan(0));
        expect(scenario.totalInterest, greaterThanOrEqualTo(0));
        expect(scenario.monthlyPayment, greaterThan(0));
      }
    });

    // Edge case: Very high interest rate generates valid scenarios
    test('edge case: very high interest rate generates valid scenarios', () {
      final account = Wallet(
        id: 'test-wallet',
        name: 'Test KMH',
        type: 'bank',
        balance: -10000.0,
        creditLimit: 20000.0,
        interestRate: 50.0, // Very high rate
        color: '#FF0000',
        icon: 'bank',
      );
      
      final scenarios = service.generatePaymentScenarios(account: account);
      
      // Should generate at least one scenario
      expect(scenarios.isNotEmpty, isTrue);
      
      // All scenarios should have valid values
      for (final scenario in scenarios) {
        expect(scenario.durationMonths, greaterThan(0));
        expect(scenario.totalInterest, greaterThan(0));
        expect(scenario.monthlyPayment, greaterThan(0));
      }
    });
  });
}
