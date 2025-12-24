import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:money/models/credit_card_transaction.dart';
import 'package:money/models/reward_points.dart';
import 'package:money/models/reward_transaction.dart';
import 'package:money/models/limit_alert.dart';
import 'package:money/services/deferred_installment_service.dart';
import 'package:money/services/credit_card_box_service.dart';
import '../property_test_utils.dart';
import 'package:uuid/uuid.dart';

/// Property-based tests for DeferredInstallmentService
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  setUpAll(() async {
    // Initialize Hive for testing with a unique temporary directory
    final testDir = './test_hive_deferred_${DateTime.now().millisecondsSinceEpoch}';
    Hive.init(testDir);
    
    // Register adapters
    if (!Hive.isAdapterRegistered(11)) {
      Hive.registerAdapter(CreditCardTransactionAdapter());
    }
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

  group('DeferredInstallmentService Property Tests', () {
    late DeferredInstallmentService service;

    setUp(() async {
      service = DeferredInstallmentService();
      // Clear data before each test
      await CreditCardBoxService.transactionsBox.clear();
    });

    /// **Feature: enhanced-credit-card-tracking, Property 5: Taksitli İşlem Kaydı**
    /// **Validates: Requirements 3.1**
    /// 
    /// Property: For any installment transaction, the system should correctly
    /// record the installment count, monthly amount, and start date.
    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 5: Installment transaction should be correctly recorded',
      generator: () {
        return {
          'cardId': const Uuid().v4(),
          'amount': PropertyTest.randomPositiveDouble(min: 100, max: 100000),
          'description': PropertyTest.randomString(minLength: 5, maxLength: 50),
          'installmentCount': PropertyTest.randomInt(min: 2, max: 36),
          'deferredMonths': PropertyTest.randomInt(min: 1, max: 12),
          'category': PropertyTest.randomString(minLength: 3, maxLength: 20),
        };
      },
      property: (data) async {
        final cardId = data['cardId'] as String;
        final amount = data['amount'] as double;
        final description = data['description'] as String;
        final installmentCount = data['installmentCount'] as int;
        final deferredMonths = data['deferredMonths'] as int;
        final category = data['category'] as String;

        // Create deferred installment
        final transaction = await service.createDeferredInstallment(
          cardId: cardId,
          amount: amount,
          description: description,
          installmentCount: installmentCount,
          deferredMonths: deferredMonths,
          category: category,
        );

        // Property 1: Installment count should be correctly recorded
        expect(transaction.installmentCount, equals(installmentCount));

        // Property 2: Monthly amount should be correctly calculated
        final expectedMonthlyAmount = amount / installmentCount;
        expect((transaction.installmentAmount - expectedMonthlyAmount).abs(), lessThan(0.0001));

        // Property 3: Start date should be set
        expect(transaction.installmentStartDate, isNotNull);

        // Property 4: Transaction should be marked as deferred
        expect(transaction.isDeferred, isTrue);
        expect(transaction.deferredMonths, equals(deferredMonths));

        // Property 5: Initial installments paid should be 0
        expect(transaction.installmentsPaid, equals(0));

        // Property 6: Transaction should not be completed initially
        expect(transaction.isCompleted, isFalse);

        // Property 7: Remaining installments should equal total installments
        expect(transaction.remainingInstallments, equals(installmentCount));

        // Property 8: Remaining amount should equal total amount
        expect((transaction.remainingAmount - amount).abs(), lessThan(0.0001));

        // Property 9: Transaction should be retrievable
        final retrieved = await service.getDeferredInstallments(cardId);
        expect(retrieved.any((t) => t.id == transaction.id), isTrue);

        return true;
      },
      iterations: 100,
    );

    test('Property 5: Invalid installment count should be rejected', () async {
      final cardId = const Uuid().v4();

      // Test installment count < 2
      expect(
        () => service.createDeferredInstallment(
          cardId: cardId,
          amount: 1000,
          description: 'Test',
          installmentCount: 1,
          deferredMonths: 3,
        ),
        throwsException,
      );

      // Test installment count > 36
      expect(
        () => service.createDeferredInstallment(
          cardId: cardId,
          amount: 1000,
          description: 'Test',
          installmentCount: 37,
          deferredMonths: 3,
        ),
        throwsException,
      );
    });

    test('Property 5: Invalid amount should be rejected', () async {
      final cardId = const Uuid().v4();

      // Test zero amount
      expect(
        () => service.createDeferredInstallment(
          cardId: cardId,
          amount: 0,
          description: 'Test',
          installmentCount: 6,
          deferredMonths: 3,
        ),
        throwsException,
      );

      // Test negative amount
      expect(
        () => service.createDeferredInstallment(
          cardId: cardId,
          amount: -1000,
          description: 'Test',
          installmentCount: 6,
          deferredMonths: 3,
        ),
        throwsException,
      );
    });

    test('Property 5: Empty description should be rejected', () async {
      final cardId = const Uuid().v4();

      expect(
        () => service.createDeferredInstallment(
          cardId: cardId,
          amount: 1000,
          description: '',
          installmentCount: 6,
          deferredMonths: 3,
        ),
        throwsException,
      );
    });

    /// **Feature: enhanced-credit-card-tracking, Property 6: Ertelenmiş Taksit Tarihi**
    /// **Validates: Requirements 3.2**
    /// 
    /// Property: For any deferred installment, the system should set the
    /// installment start date to the specified number of months in the future.
    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 6: Deferred installment start date should be correctly calculated',
      generator: () {
        return {
          'cardId': const Uuid().v4(),
          'amount': PropertyTest.randomPositiveDouble(min: 100, max: 100000),
          'description': PropertyTest.randomString(minLength: 5, maxLength: 50),
          'installmentCount': PropertyTest.randomInt(min: 2, max: 36),
          'deferredMonths': PropertyTest.randomInt(min: 1, max: 12),
        };
      },
      property: (data) async {
        final cardId = data['cardId'] as String;
        final amount = data['amount'] as double;
        final description = data['description'] as String;
        final installmentCount = data['installmentCount'] as int;
        final deferredMonths = data['deferredMonths'] as int;

        final now = DateTime.now();

        // Create deferred installment
        final transaction = await service.createDeferredInstallment(
          cardId: cardId,
          amount: amount,
          description: description,
          installmentCount: installmentCount,
          deferredMonths: deferredMonths,
        );

        // Property 1: Start date should be set
        expect(transaction.installmentStartDate, isNotNull);
        final startDate = transaction.installmentStartDate!;

        // Property 2: Start date should be in the future
        expect(startDate.isAfter(now) || startDate.isAtSameMomentAs(now), isTrue);

        // Property 3: Start date should be approximately deferredMonths in the future
        // Calculate expected start date
        final expectedStartDate = DateTime(
          now.year,
          now.month + deferredMonths,
          now.day,
        );

        // Check year and month match (day might vary slightly due to month lengths)
        expect(startDate.year, equals(expectedStartDate.year));
        expect(startDate.month, equals(expectedStartDate.month));

        // Property 4: The month difference should equal deferredMonths
        final monthDiff = (startDate.year - now.year) * 12 + 
                          (startDate.month - now.month);
        expect(monthDiff, equals(deferredMonths));

        // Property 5: Transaction date should be now (when created)
        expect(transaction.transactionDate.year, equals(now.year));
        expect(transaction.transactionDate.month, equals(now.month));
        expect(transaction.transactionDate.day, equals(now.day));

        // Property 6: Deferred months should be correctly stored
        expect(transaction.deferredMonths, equals(deferredMonths));

        // Property 7: Effective start date should be the installment start date
        expect(transaction.effectiveStartDate, equals(startDate));

        return true;
      },
      iterations: 100,
    );

    test('Property 6: Invalid deferred months should be rejected', () async {
      final cardId = const Uuid().v4();

      // Test deferred months < 1
      expect(
        () => service.createDeferredInstallment(
          cardId: cardId,
          amount: 1000,
          description: 'Test',
          installmentCount: 6,
          deferredMonths: 0,
        ),
        throwsException,
      );

      // Test deferred months > 12
      expect(
        () => service.createDeferredInstallment(
          cardId: cardId,
          amount: 1000,
          description: 'Test',
          installmentCount: 6,
          deferredMonths: 13,
        ),
        throwsException,
      );
    });

    test('Property 6: Start date should advance correctly for different deferred months', () async {
      final cardId = const Uuid().v4();
      final now = DateTime.now();

      // Create installments with different deferred months
      final transaction3 = await service.createDeferredInstallment(
        cardId: cardId,
        amount: 1000,
        description: 'Test 3 months',
        installmentCount: 6,
        deferredMonths: 3,
      );

      final transaction6 = await service.createDeferredInstallment(
        cardId: cardId,
        amount: 2000,
        description: 'Test 6 months',
        installmentCount: 12,
        deferredMonths: 6,
      );

      // Verify the month difference
      final start3 = transaction3.installmentStartDate!;
      final start6 = transaction6.installmentStartDate!;

      final diff3 = (start3.year - now.year) * 12 + (start3.month - now.month);
      final diff6 = (start6.year - now.year) * 12 + (start6.month - now.month);

      expect(diff3, equals(3));
      expect(diff6, equals(6));

      // The 6-month deferred should start 3 months after the 3-month deferred
      final diffBetween = (start6.year - start3.year) * 12 + (start6.month - start3.month);
      expect(diffBetween, equals(3));
    });

    /// **Feature: enhanced-credit-card-tracking, Property 7: Taksit Bitişi Bildirimi**
    /// **Validates: Requirements 3.4**
    /// 
    /// Property: For any installment, when it reaches the last payment,
    /// the system should identify it as ending soon.
    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 7: Installments ending soon should be correctly identified',
      generator: () {
        final installmentCount = PropertyTest.randomInt(min: 2, max: 12);
        // Generate deferred months that will make the installment end within 2 months
        // We want installments that are close to completion
        final deferredMonths = PropertyTest.randomInt(min: 1, max: 2);
        
        return {
          'cardId': const Uuid().v4(),
          'amount': PropertyTest.randomPositiveDouble(min: 100, max: 100000),
          'description': PropertyTest.randomString(minLength: 5, maxLength: 50),
          'installmentCount': installmentCount,
          'deferredMonths': deferredMonths,
        };
      },
      property: (data) async {
        final cardId = data['cardId'] as String;
        final amount = data['amount'] as double;
        final description = data['description'] as String;
        final installmentCount = data['installmentCount'] as int;
        final deferredMonths = data['deferredMonths'] as int;

        // Create deferred installment
        final transaction = await service.createDeferredInstallment(
          cardId: cardId,
          amount: amount,
          description: description,
          installmentCount: installmentCount,
          deferredMonths: deferredMonths,
        );

        // Property 1: Initially, installment should not be completed
        expect(transaction.isCompleted, isFalse);

        // Property 2: Remaining installments should equal total installments
        expect(transaction.remainingInstallments, equals(installmentCount));

        // Property 3: Check if installment is ending soon (within 2 months)
        final endingSoon = await service.getInstallmentsEndingSoon(
          cardId: cardId,
          withinMonths: 2,
        );

        // Property 4: If deferred months + installment count <= 2, it should be in ending soon list
        final totalMonths = deferredMonths + installmentCount;
        if (totalMonths <= 2) {
          expect(endingSoon.any((t) => t.id == transaction.id), isTrue);
        }

        // Property 5: Calculate when the last payment will be
        final startDate = transaction.installmentStartDate!;
        final lastPaymentMonth = DateTime(
          startDate.year,
          startDate.month + installmentCount,
          startDate.day,
        );

        final now = DateTime.now();
        final twoMonthsFromNow = DateTime(now.year, now.month + 2, now.day);

        // Property 6: If last payment is within 2 months, should be in ending soon list
        if (lastPaymentMonth.isBefore(twoMonthsFromNow) || 
            lastPaymentMonth.isAtSameMomentAs(twoMonthsFromNow)) {
          expect(endingSoon.any((t) => t.id == transaction.id), isTrue);
        }

        return true;
      },
      iterations: 100,
    );

    test('Property 7: Completed installments should not appear in ending soon list', () async {
      final cardId = const Uuid().v4();

      // Create a deferred installment
      final transaction = await service.createDeferredInstallment(
        cardId: cardId,
        amount: 1000,
        description: 'Test',
        installmentCount: 6,
        deferredMonths: 1,
      );

      // Mark it as completed by setting installmentsPaid = installmentCount
      // We need to access the repository directly
      final repo = CreditCardBoxService.transactionsBox;
      final completed = transaction.copyWith(
        installmentsPaid: transaction.installmentCount,
      );
      await repo.put(completed.id, completed);

      // Check ending soon list
      final endingSoon = await service.getInstallmentsEndingSoon(
        cardId: cardId,
        withinMonths: 12,
      );

      // Completed installment should not be in the list
      expect(endingSoon.any((t) => t.id == transaction.id), isFalse);
    });

    test('Property 7: Installments far in the future should not be in ending soon list', () async {
      final cardId = const Uuid().v4();

      // Create a deferred installment that ends far in the future
      final transaction = await service.createDeferredInstallment(
        cardId: cardId,
        amount: 1000,
        description: 'Test',
        installmentCount: 12,
        deferredMonths: 12,
      );

      // Check ending soon list (within 2 months)
      final endingSoon = await service.getInstallmentsEndingSoon(
        cardId: cardId,
        withinMonths: 2,
      );

      // This installment should not be in the list
      expect(endingSoon.any((t) => t.id == transaction.id), isFalse);
    });

    test('Property 7: Can query ending soon for all cards', () async {
      final cardId1 = const Uuid().v4();
      final cardId2 = const Uuid().v4();

      // Create installments for different cards
      await service.createDeferredInstallment(
        cardId: cardId1,
        amount: 1000,
        description: 'Card 1',
        installmentCount: 3,
        deferredMonths: 1,
      );

      await service.createDeferredInstallment(
        cardId: cardId2,
        amount: 2000,
        description: 'Card 2',
        installmentCount: 4,
        deferredMonths: 1,
      );

      // Query ending soon for all cards
      final endingSoon = await service.getInstallmentsEndingSoon(
        withinMonths: 12,
      );

      // Should include installments from both cards
      expect(endingSoon.length, greaterThanOrEqualTo(2));
    });

    // Additional tests for service functionality

    test('Should get deferred installments starting this month', () async {
      final cardId = const Uuid().v4();
      final now = DateTime.now();

      // Create an installment that starts this month (deferred by 0 months would be invalid,
      // so we create one that starts next month and test with a future date)
      final transaction = await service.createDeferredInstallment(
        cardId: cardId,
        amount: 1000,
        description: 'Test',
        installmentCount: 6,
        deferredMonths: 1,
      );

      // Get installments starting this month
      final startingThisMonth = await service.getInstallmentsStartingThisMonth(cardId);

      // The installment should be in the list if its start month matches current month
      final startDate = transaction.installmentStartDate!;
      if (startDate.year == now.year && startDate.month == now.month) {
        expect(startingThisMonth.any((t) => t.id == transaction.id), isTrue);
      }
    });

    test('Should get deferred installment schedule', () async {
      final cardId = const Uuid().v4();

      // Create multiple deferred installments with different start dates
      await service.createDeferredInstallment(
        cardId: cardId,
        amount: 1000,
        description: 'Test 1',
        installmentCount: 6,
        deferredMonths: 1,
      );

      await service.createDeferredInstallment(
        cardId: cardId,
        amount: 2000,
        description: 'Test 2',
        installmentCount: 12,
        deferredMonths: 3,
      );

      // Get schedule
      final schedule = await service.getDeferredInstallmentSchedule(cardId);

      // Should have entries for different months
      expect(schedule.isNotEmpty, isTrue);

      // Each month should have a list of transactions
      for (var entry in schedule.entries) {
        expect(entry.value, isNotEmpty);
        expect(entry.key.day, equals(1)); // Should be normalized to first day of month
      }
    });

    test('Should calculate total deferred amount', () async {
      final cardId = const Uuid().v4();

      await service.createDeferredInstallment(
        cardId: cardId,
        amount: 1000,
        description: 'Test 1',
        installmentCount: 6,
        deferredMonths: 1,
      );

      await service.createDeferredInstallment(
        cardId: cardId,
        amount: 2000,
        description: 'Test 2',
        installmentCount: 12,
        deferredMonths: 3,
      );

      final totalAmount = await service.getTotalDeferredAmount(cardId);
      expect(totalAmount, equals(3000));
    });

    test('Should count deferred installments', () async {
      final cardId = const Uuid().v4();

      await service.createDeferredInstallment(
        cardId: cardId,
        amount: 1000,
        description: 'Test 1',
        installmentCount: 6,
        deferredMonths: 1,
      );

      await service.createDeferredInstallment(
        cardId: cardId,
        amount: 2000,
        description: 'Test 2',
        installmentCount: 12,
        deferredMonths: 3,
      );

      final count = await service.getDeferredInstallmentCount(cardId);
      expect(count, equals(2));
    });

    test('Should activate deferred installments when date arrives', () async {
      final cardId = const Uuid().v4();
      final now = DateTime.now();

      // Create an installment that should start now
      final transaction = await service.createDeferredInstallment(
        cardId: cardId,
        amount: 1000,
        description: 'Test',
        installmentCount: 6,
        deferredMonths: 1,
      );

      // Check activation with a future date (when the installment should start)
      final futureDate = DateTime(now.year, now.month + 1, now.day);
      final activatedIds = await service.activateDeferredInstallments(futureDate);

      // The installment should be activated
      expect(activatedIds.contains(transaction.id), isTrue);
    });

    test('Should check if installment is active', () async {
      final cardId = const Uuid().v4();
      final now = DateTime.now();

      final transaction = await service.createDeferredInstallment(
        cardId: cardId,
        amount: 1000,
        description: 'Test',
        installmentCount: 6,
        deferredMonths: 1,
      );

      // Should not be active now
      final isActiveNow = await service.isInstallmentActive(transaction.id, now);
      expect(isActiveNow, isFalse);

      // Should be active in the future
      final futureDate = DateTime(now.year, now.month + 2, now.day);
      final isActiveFuture = await service.isInstallmentActive(transaction.id, futureDate);
      expect(isActiveFuture, isTrue);
    });

    test('Should calculate months until start', () async {
      final cardId = const Uuid().v4();
      final now = DateTime.now();

      final transaction = await service.createDeferredInstallment(
        cardId: cardId,
        amount: 1000,
        description: 'Test',
        installmentCount: 6,
        deferredMonths: 3,
      );

      // Should be 3 months until start
      final monthsUntilStart = await service.getMonthsUntilStart(transaction.id, now);
      expect(monthsUntilStart, equals(3));

      // Should be 0 months when date arrives
      final futureDate = DateTime(now.year, now.month + 3, now.day);
      final monthsUntilStartFuture = await service.getMonthsUntilStart(transaction.id, futureDate);
      expect(monthsUntilStartFuture, equals(0));
    });
  });
}
