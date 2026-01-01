import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:parion/models/wallet.dart';
import 'package:parion/models/payment_plan.dart';
import 'package:parion/services/payment_planner_service.dart';
import 'package:parion/services/kmh_interest_calculator.dart';
import 'package:parion/repositories/payment_plan_repository.dart';
import '../property_test_utils.dart';

/// Property-based tests for Payment Plan Round-Trip
/// 
/// These tests verify Property 27: Payment Plan Round-Trip
/// Validates: Requirement 7.5
void main() {
  group('Payment Plan Round-Trip Property Tests', () {
    late PaymentPlannerService service;
    late PaymentPlanRepository repository;
    late KmhInterestCalculator calculator;
    late Directory testDir;

    setUpAll(() async {
      // Register Hive adapters if not already registered
      if (!Hive.isAdapterRegistered(31)) {
        Hive.registerAdapter(PaymentPlanAdapter());
      }
    });

    setUp(() async {
      // Create a unique temporary directory for each test
      testDir = await Directory.systemTemp.createTemp('payment_roundtrip_test_');
      
      // Initialize Hive with the test directory
      Hive.init(testDir.path);
      
      // Create fresh instances
      calculator = KmhInterestCalculator();
      repository = PaymentPlanRepository();
      service = PaymentPlannerService(
        calculator: calculator,
        repository: repository,
      );
      
      // Initialize repository
      await repository.init();
    });

    tearDown(() async {
      // Close repository and Hive
      await repository.close();
      await Hive.close();
      
      // Clean up test directory
      if (await testDir.exists()) {
        await testDir.delete(recursive: true);
      }
    });

    // Feature: kmh-account-management, Property 27: Ödeme Planı Round-Trip
    // Validates: Requirement 7.5
    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'property: saved payment plan can be retrieved with same information',
      generator: () {
        // Generate random debt and payment parameters
        final debt = PropertyTest.randomPositiveDouble(min: 5000.0, max: 40000.0);
        final annualRate = PropertyTest.randomPositiveDouble(min: 15.0, max: 40.0);
        
        // Calculate monthly interest to ensure payment is sufficient
        final calculator = KmhInterestCalculator();
        final monthlyInterest = calculator.estimateMonthlyInterest(
          balance: -debt,
          annualRate: annualRate,
          days: 30,
        );
        
        // Generate payment that is sufficient (more than monthly interest)
        final multiplier = 1.5 + PropertyTest.randomPositiveDouble(min: 0.0, max: 2.5);
        final monthlyPayment = monthlyInterest * multiplier;
        
        // Generate reminder schedule
        final reminderSchedules = ['monthly', 'weekly', 'biweekly'];
        final reminderSchedule = reminderSchedules[PropertyTest.randomInt(min: 0, max: 2)];
        
        return {
          'debt': debt,
          'monthlyPayment': monthlyPayment,
          'annualRate': annualRate,
          'reminderSchedule': reminderSchedule,
        };
      },
      property: (data) async {
        final debt = data['debt'] as double;
        final monthlyPayment = data['monthlyPayment'] as double;
        final annualRate = data['annualRate'] as double;
        final reminderSchedule = data['reminderSchedule'] as String;
        
        // Create a test KMH account
        final walletId = 'test-wallet-${PropertyTest.randomString(minLength: 5, maxLength: 10)}';
        final account = Wallet(
          id: walletId,
          name: 'Test KMH',
          type: 'bank',
          balance: -debt,
          creditLimit: debt * 2,
          interestRate: annualRate,
          color: '#FF0000',
          icon: 'bank',
        );
        
        // Create payment plan with reminder
        final originalPlan = service.createPaymentPlanWithReminder(
          account: account,
          monthlyPayment: monthlyPayment,
          reminderSchedule: reminderSchedule,
        );
        
        // Plan should be created
        if (originalPlan == null) {
          return false;
        }
        
        // Save the payment plan
        await service.savePaymentPlan(originalPlan);
        
        // Retrieve the payment plan
        final retrievedPlan = await service.getActivePlan(walletId);
        
        // Plan should be retrieved
        if (retrievedPlan == null) {
          return false;
        }
        
        // Property: All fields should match
        const tolerance = 0.01; // Tolerance for floating point comparison
        
        // Check ID
        if (retrievedPlan.id != originalPlan.id) return false;
        
        // Check wallet ID
        if (retrievedPlan.walletId != originalPlan.walletId) return false;
        
        // Check initial debt
        if ((retrievedPlan.initialDebt - originalPlan.initialDebt).abs() > tolerance) {
          return false;
        }
        
        // Check monthly payment
        if ((retrievedPlan.monthlyPayment - originalPlan.monthlyPayment).abs() > tolerance) {
          return false;
        }
        
        // Check annual rate
        if ((retrievedPlan.annualRate - originalPlan.annualRate).abs() > tolerance) {
          return false;
        }
        
        // Check duration
        if (retrievedPlan.durationMonths != originalPlan.durationMonths) {
          return false;
        }
        
        // Check total interest
        if ((retrievedPlan.totalInterest - originalPlan.totalInterest).abs() > tolerance) {
          return false;
        }
        
        // Check total payment
        if ((retrievedPlan.totalPayment - originalPlan.totalPayment).abs() > tolerance) {
          return false;
        }
        
        // Check active status
        if (retrievedPlan.isActive != originalPlan.isActive) {
          return false;
        }
        
        // Check reminder schedule
        if (retrievedPlan.reminderSchedule != originalPlan.reminderSchedule) {
          return false;
        }
        
        // Check created date (should be within 1 second)
        final dateDiff = retrievedPlan.createdAt.difference(originalPlan.createdAt).inSeconds.abs();
        if (dateDiff > 1) {
          return false;
        }
        
        return true;
      },
      iterations: 100,
    );

    // Property: Multiple plans can be saved and retrieved independently
    PropertyTest.forAll<List<Map<String, dynamic>>>(
      description: 'property: multiple payment plans maintain independence',
      generator: () {
        // Generate 2-4 different plans
        final numPlans = PropertyTest.randomInt(min: 2, max: 4);
        final plans = <Map<String, dynamic>>[];
        
        for (int i = 0; i < numPlans; i++) {
          final debt = PropertyTest.randomPositiveDouble(min: 5000.0, max: 30000.0);
          final annualRate = PropertyTest.randomPositiveDouble(min: 18.0, max: 35.0);
          
          final calculator = KmhInterestCalculator();
          final monthlyInterest = calculator.estimateMonthlyInterest(
            balance: -debt,
            annualRate: annualRate,
            days: 30,
          );
          
          final multiplier = 1.5 + PropertyTest.randomPositiveDouble(min: 0.0, max: 2.0);
          final monthlyPayment = monthlyInterest * multiplier;
          
          plans.add({
            'debt': debt,
            'monthlyPayment': monthlyPayment,
            'annualRate': annualRate,
            'walletId': 'wallet-$i',
          });
        }
        
        return plans;
      },
      property: (planDataList) async {
        final savedPlans = <PaymentPlan>[];
        
        // Create and save all plans
        for (final planData in planDataList) {
          final debt = planData['debt'] as double;
          final monthlyPayment = planData['monthlyPayment'] as double;
          final annualRate = planData['annualRate'] as double;
          final walletId = planData['walletId'] as String;
          
          final account = Wallet(
            id: walletId,
            name: 'Test KMH $walletId',
            type: 'bank',
            balance: -debt,
            creditLimit: debt * 2,
            interestRate: annualRate,
            color: '#FF0000',
            icon: 'bank',
          );
          
          final plan = service.createPaymentPlanWithReminder(
            account: account,
            monthlyPayment: monthlyPayment,
          );
          
          if (plan == null) return false;
          
          await service.savePaymentPlan(plan);
          savedPlans.add(plan);
        }
        
        // Retrieve and verify each plan independently
        for (int i = 0; i < savedPlans.length; i++) {
          final originalPlan = savedPlans[i];
          final retrievedPlan = await service.getActivePlan(originalPlan.walletId);
          
          if (retrievedPlan == null) return false;
          
          // Verify this plan matches the original
          const tolerance = 0.01;
          
          if (retrievedPlan.id != originalPlan.id) return false;
          if (retrievedPlan.walletId != originalPlan.walletId) return false;
          if ((retrievedPlan.initialDebt - originalPlan.initialDebt).abs() > tolerance) {
            return false;
          }
          if ((retrievedPlan.monthlyPayment - originalPlan.monthlyPayment).abs() > tolerance) {
            return false;
          }
        }
        
        return true;
      },
      iterations: 50,
    );

    // Property: Updated plan maintains changes after round-trip
    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'property: updated payment plan persists changes',
      generator: () {
        final debt = PropertyTest.randomPositiveDouble(min: 8000.0, max: 35000.0);
        final annualRate = PropertyTest.randomPositiveDouble(min: 16.0, max: 38.0);
        
        final calculator = KmhInterestCalculator();
        final monthlyInterest = calculator.estimateMonthlyInterest(
          balance: -debt,
          annualRate: annualRate,
          days: 30,
        );
        
        final multiplier = 1.5 + PropertyTest.randomPositiveDouble(min: 0.0, max: 2.0);
        final monthlyPayment = monthlyInterest * multiplier;
        
        return {
          'debt': debt,
          'monthlyPayment': monthlyPayment,
          'annualRate': annualRate,
        };
      },
      property: (data) async {
        final debt = data['debt'] as double;
        final monthlyPayment = data['monthlyPayment'] as double;
        final annualRate = data['annualRate'] as double;
        
        final walletId = 'test-wallet-${PropertyTest.randomString(minLength: 5, maxLength: 10)}';
        final account = Wallet(
          id: walletId,
          name: 'Test KMH',
          type: 'bank',
          balance: -debt,
          creditLimit: debt * 2,
          interestRate: annualRate,
          color: '#FF0000',
          icon: 'bank',
        );
        
        // Create and save original plan
        final originalPlan = service.createPaymentPlanWithReminder(
          account: account,
          monthlyPayment: monthlyPayment,
        );
        
        if (originalPlan == null) return false;
        
        await service.savePaymentPlan(originalPlan);
        
        // Update the plan (change active status and reminder schedule)
        // We need to modify the original plan object since it's in the box
        originalPlan.isActive = false;
        originalPlan.reminderSchedule = 'weekly';
        
        await service.updatePlan(originalPlan);
        
        // Retrieve the plan
        final retrievedPlans = await service.getPlansByWallet(walletId);
        
        if (retrievedPlans.isEmpty) return false;
        
        final retrievedPlan = retrievedPlans.first;
        
        // Property: Changes should be persisted
        if (retrievedPlan.isActive != false) return false;
        if (retrievedPlan.reminderSchedule != 'weekly') return false;
        
        // Other fields should remain unchanged
        const tolerance = 0.01;
        if ((retrievedPlan.initialDebt - originalPlan.initialDebt).abs() > tolerance) {
          return false;
        }
        if ((retrievedPlan.monthlyPayment - originalPlan.monthlyPayment).abs() > tolerance) {
          return false;
        }
        
        return true;
      },
      iterations: 100,
    );

    // Property: Deleted plan cannot be retrieved
    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'property: deleted payment plan is not retrievable',
      generator: () {
        final debt = PropertyTest.randomPositiveDouble(min: 7000.0, max: 30000.0);
        final annualRate = PropertyTest.randomPositiveDouble(min: 17.0, max: 36.0);
        
        final calculator = KmhInterestCalculator();
        final monthlyInterest = calculator.estimateMonthlyInterest(
          balance: -debt,
          annualRate: annualRate,
          days: 30,
        );
        
        final multiplier = 1.5 + PropertyTest.randomPositiveDouble(min: 0.0, max: 2.0);
        final monthlyPayment = monthlyInterest * multiplier;
        
        return {
          'debt': debt,
          'monthlyPayment': monthlyPayment,
          'annualRate': annualRate,
        };
      },
      property: (data) async {
        final debt = data['debt'] as double;
        final monthlyPayment = data['monthlyPayment'] as double;
        final annualRate = data['annualRate'] as double;
        
        final walletId = 'test-wallet-${PropertyTest.randomString(minLength: 5, maxLength: 10)}';
        final account = Wallet(
          id: walletId,
          name: 'Test KMH',
          type: 'bank',
          balance: -debt,
          creditLimit: debt * 2,
          interestRate: annualRate,
          color: '#FF0000',
          icon: 'bank',
        );
        
        // Create and save plan
        final plan = service.createPaymentPlanWithReminder(
          account: account,
          monthlyPayment: monthlyPayment,
        );
        
        if (plan == null) return false;
        
        await service.savePaymentPlan(plan);
        
        // Verify it exists
        final beforeDelete = await service.getActivePlan(walletId);
        if (beforeDelete == null) return false;
        
        // Delete the plan
        await service.deletePlan(plan.id);
        
        // Property: Plan should not be retrievable after deletion
        final afterDelete = await service.getActivePlan(walletId);
        return afterDelete == null;
      },
      iterations: 100,
    );

    // Edge case: Plan with null reminder schedule
    test('edge case: plan with null reminder schedule round-trips correctly', () async {
      final account = Wallet(
        id: 'test-wallet',
        name: 'Test KMH',
        type: 'bank',
        balance: -10000.0,
        creditLimit: 20000.0,
        interestRate: 24.0,
        color: '#FF0000',
        icon: 'bank',
      );
      
      final plan = service.calculatePaymentPlan(
        account: account,
        monthlyPayment: 2000.0,
      );
      
      expect(plan, isNotNull);
      
      // Save plan (without reminder)
      await service.savePaymentPlan(plan!.copyWith(isActive: true));
      
      // Retrieve plan
      final retrieved = await service.getActivePlan('test-wallet');
      
      expect(retrieved, isNotNull);
      expect(retrieved!.id, equals(plan.id));
      expect(retrieved.reminderSchedule, isNull);
    });

    // Edge case: Plan with very small debt
    test('edge case: plan with very small debt round-trips correctly', () async {
      final account = Wallet(
        id: 'test-wallet-small',
        name: 'Test KMH',
        type: 'bank',
        balance: -100.0,
        creditLimit: 10000.0,
        interestRate: 24.0,
        color: '#FF0000',
        icon: 'bank',
      );
      
      final plan = service.createPaymentPlanWithReminder(
        account: account,
        monthlyPayment: 50.0,
      );
      
      expect(plan, isNotNull);
      
      await service.savePaymentPlan(plan!);
      
      final retrieved = await service.getActivePlan('test-wallet-small');
      
      expect(retrieved, isNotNull);
      expect(retrieved!.initialDebt, closeTo(100.0, 0.01));
      expect(retrieved.monthlyPayment, closeTo(50.0, 0.01));
    });

    // Edge case: Plan with very high interest rate
    test('edge case: plan with very high interest rate round-trips correctly', () async {
      final account = Wallet(
        id: 'test-wallet-high',
        name: 'Test KMH',
        type: 'bank',
        balance: -15000.0,
        creditLimit: 30000.0,
        interestRate: 50.0, // Very high rate
        color: '#FF0000',
        icon: 'bank',
      );
      
      final plan = service.createPaymentPlanWithReminder(
        account: account,
        monthlyPayment: 3000.0,
      );
      
      expect(plan, isNotNull);
      
      await service.savePaymentPlan(plan!);
      
      final retrieved = await service.getActivePlan('test-wallet-high');
      
      expect(retrieved, isNotNull);
      expect(retrieved!.annualRate, closeTo(50.0, 0.01));
      expect(retrieved.totalInterest, greaterThan(0));
    });

    // Edge case: Multiple plans for same wallet (only one active)
    test('edge case: only one plan can be active per wallet', () async {
      final account = Wallet(
        id: 'test-wallet-multi',
        name: 'Test KMH',
        type: 'bank',
        balance: -12000.0,
        creditLimit: 25000.0,
        interestRate: 24.0,
        color: '#FF0000',
        icon: 'bank',
      );
      
      // Create and save first plan
      final plan1 = service.createPaymentPlanWithReminder(
        account: account,
        monthlyPayment: 1500.0,
      );
      expect(plan1, isNotNull);
      await service.savePaymentPlan(plan1!);
      
      // Create and save second plan (should deactivate first)
      final plan2 = service.createPaymentPlanWithReminder(
        account: account,
        monthlyPayment: 2000.0,
      );
      expect(plan2, isNotNull);
      await service.savePaymentPlan(plan2!);
      
      // Only second plan should be active
      final activePlan = await service.getActivePlan('test-wallet-multi');
      expect(activePlan, isNotNull);
      expect(activePlan!.id, equals(plan2.id));
      
      // Both plans should exist
      final allPlans = await service.getPlansByWallet('test-wallet-multi');
      expect(allPlans.length, equals(2));
      
      // Only one should be active
      final activePlans = allPlans.where((p) => p.isActive).toList();
      expect(activePlans.length, equals(1));
      expect(activePlans.first.id, equals(plan2.id));
    });
  });
}
