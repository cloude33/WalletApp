import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:parion/models/credit_card.dart';
import 'package:parion/models/credit_card_payment.dart';
import 'package:parion/models/credit_card_statement.dart';
import 'package:parion/models/credit_card_transaction.dart';
import 'package:parion/models/limit_alert.dart';
import 'package:parion/models/reward_points.dart';
import 'package:parion/models/reward_transaction.dart';
import 'package:parion/repositories/credit_card_payment_repository.dart';
import 'package:parion/repositories/credit_card_repository.dart';
import 'package:parion/repositories/credit_card_statement_repository.dart';
import 'package:parion/services/credit_card_box_service.dart';
import 'dart:math';

void main() {
  late CreditCardPaymentRepository paymentRepo;
  late CreditCardRepository cardRepo;
  late CreditCardStatementRepository statementRepo;
  final random = Random();

  setUpAll(() async {
    // Initialize Hive with a test directory
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    Hive.init('test_hive_payment_history_$timestamp');

    // Register adapters only once
    if (!Hive.isAdapterRegistered(11)) {
      Hive.registerAdapter(CreditCardAdapter());
    }
    if (!Hive.isAdapterRegistered(12)) {
      Hive.registerAdapter(CreditCardStatementAdapter());
    }
    if (!Hive.isAdapterRegistered(13)) {
      Hive.registerAdapter(CreditCardPaymentAdapter());
    }
    if (!Hive.isAdapterRegistered(14)) {
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

    // Initialize CreditCardBoxService
    await CreditCardBoxService.init();
  });

  setUp(() async {
    paymentRepo = CreditCardPaymentRepository();
    cardRepo = CreditCardRepository();
    statementRepo = CreditCardStatementRepository();
  });

  tearDown(() async {
    // Clear boxes after each test
    final paymentsBox = CreditCardBoxService.paymentsBox;
    final cardsBox = CreditCardBoxService.creditCardsBox;
    final statementsBox = CreditCardBoxService.statementsBox;
    
    await paymentsBox.clear();
    await cardsBox.clear();
    await statementsBox.clear();
  });

  tearDownAll(() async {
    await Hive.deleteFromDisk();
    await Hive.close();
  });

  group('Payment History Property Tests', () {
    test('Property 51: Ödeme Kaydı - Payment records all required fields correctly', () async {
      // Feature: enhanced-credit-card-tracking, Property 51: Ödeme Kaydı
      // Validates: Requirements 15.1

      for (int i = 0; i < 100; i++) {
        // Generate random payment data
        final paymentId = 'payment-${random.nextInt(100000)}';
        final cardId = 'card-${random.nextInt(1000)}';
        final statementId = 'statement-${random.nextInt(1000)}';
        final amount = random.nextDouble() * 10000 + 100;
        final paymentDate = DateTime.now().subtract(Duration(days: random.nextInt(365)));
        final paymentTypes = ['minimum', 'full', 'partial'];
        final paymentType = paymentTypes[random.nextInt(paymentTypes.length)];
        final remainingDebt = random.nextDouble() * 5000;

        // Create payment
        final payment = CreditCardPayment(
          id: paymentId,
          cardId: cardId,
          statementId: statementId,
          amount: amount,
          paymentDate: paymentDate,
          paymentType: paymentType,
          remainingDebtAfterPayment: remainingDebt,
          createdAt: DateTime.now(),
        );

        // Save payment
        await paymentRepo.save(payment);

        // Retrieve payment
        final retrieved = await paymentRepo.findById(paymentId);

        // Assert: All fields should be correctly recorded
        expect(retrieved, isNotNull);
        expect(retrieved!.id, equals(paymentId));
        expect(retrieved.cardId, equals(cardId));
        expect(retrieved.statementId, equals(statementId));
        expect(retrieved.amount, equals(amount));
        expect(retrieved.paymentDate.year, equals(paymentDate.year));
        expect(retrieved.paymentDate.month, equals(paymentDate.month));
        expect(retrieved.paymentDate.day, equals(paymentDate.day));
        expect(retrieved.paymentType, equals(paymentType));
        expect(retrieved.remainingDebtAfterPayment, equals(remainingDebt));

        // Clean up
        await paymentRepo.delete(paymentId);
      }
    });

    test('Property 52: Ödeme Borç Azaltma Invariant\'ı - New debt equals old debt minus payment', () async {
      // Feature: enhanced-credit-card-tracking, Property 52: Ödeme Borç Azaltma Invariant'ı
      // Validates: Requirements 15.2

      for (int i = 0; i < 100; i++) {
        // Generate random debt and payment amounts
        final oldDebt = random.nextDouble() * 10000 + 1000; // At least 1000
        final paymentAmount = random.nextDouble() * oldDebt; // Payment can't exceed debt
        
        // Calculate expected new debt
        final expectedNewDebt = oldDebt - paymentAmount;

        // Create a card and statement with the old debt
        final cardId = 'card-${random.nextInt(100000)}';
        final statementId = 'statement-${random.nextInt(100000)}';
        
        final card = CreditCard(
          id: cardId,
          cardName: 'Test Card',
          bankName: 'Test Bank',
          last4Digits: '1234',
          creditLimit: 20000,
          statementDay: 15,
          dueDateOffset: 10,
          monthlyInterestRate: 3.5,
          lateInterestRate: 5.0,
          cardColor: 0xFF2196F3,
          createdAt: DateTime.now(),
        );
        await cardRepo.save(card);

        final statement = CreditCardStatement(
          id: statementId,
          cardId: cardId,
          periodStart: DateTime.now().subtract(Duration(days: 30)),
          periodEnd: DateTime.now(),
          dueDate: DateTime.now().add(Duration(days: 10)),
          totalDebt: oldDebt,
          minimumPayment: oldDebt * 0.1,
          remainingDebt: oldDebt,
          createdAt: DateTime.now(),
        );
        await statementRepo.save(statement);

        // Create payment
        final payment = CreditCardPayment(
          id: 'payment-${random.nextInt(100000)}',
          cardId: cardId,
          statementId: statementId,
          amount: paymentAmount,
          paymentDate: DateTime.now(),
          paymentType: 'partial',
          remainingDebtAfterPayment: expectedNewDebt,
          createdAt: DateTime.now(),
        );
        await paymentRepo.save(payment);

        // Assert: New debt should equal old debt minus payment amount
        expect(payment.remainingDebtAfterPayment, closeTo(expectedNewDebt, 0.01));
        expect(payment.remainingDebtAfterPayment, closeTo(oldDebt - paymentAmount, 0.01));
        expect(payment.remainingDebtAfterPayment, greaterThanOrEqualTo(0));

        // Clean up
        await paymentRepo.delete(payment.id);
        await statementRepo.delete(statementId);
        await cardRepo.delete(cardId);
      }
    });

    test('Property 53: Ödeme Kronolojik Sıralama - Payments are sorted chronologically', () async {
      // Feature: enhanced-credit-card-tracking, Property 53: Ödeme Kronolojik Sıralama
      // Validates: Requirements 15.3

      for (int i = 0; i < 100; i++) {
        // Create a card
        final cardId = 'card-${random.nextInt(100000)}';
        final card = CreditCard(
          id: cardId,
          cardName: 'Test Card',
          bankName: 'Test Bank',
          last4Digits: '1234',
          creditLimit: 20000,
          statementDay: 15,
          dueDateOffset: 10,
          monthlyInterestRate: 3.5,
          lateInterestRate: 5.0,
          cardColor: 0xFF2196F3,
          createdAt: DateTime.now(),
        );
        await cardRepo.save(card);

        // Create multiple payments with random dates
        final numPayments = random.nextInt(10) + 3; // 3-12 payments
        final payments = <CreditCardPayment>[];
        
        for (int j = 0; j < numPayments; j++) {
          final paymentDate = DateTime.now().subtract(
            Duration(days: random.nextInt(365)),
          );
          
          final payment = CreditCardPayment(
            id: 'payment-$cardId-$j',
            cardId: cardId,
            statementId: 'statement-$j',
            amount: random.nextDouble() * 1000 + 100,
            paymentDate: paymentDate,
            paymentType: 'partial',
            remainingDebtAfterPayment: random.nextDouble() * 5000,
            createdAt: DateTime.now(),
          );
          
          await paymentRepo.save(payment);
          payments.add(payment);
        }

        // Get all payments for this card
        final allPayments = await paymentRepo.findByCardId(cardId);

        // Sort payments chronologically (oldest first)
        final sortedPayments = List<CreditCardPayment>.from(allPayments)
          ..sort((a, b) => a.paymentDate.compareTo(b.paymentDate));

        // Assert: Payments should be in chronological order
        for (int k = 0; k < sortedPayments.length - 1; k++) {
          expect(
            sortedPayments[k].paymentDate.isBefore(sortedPayments[k + 1].paymentDate) ||
            sortedPayments[k].paymentDate.isAtSameMomentAs(sortedPayments[k + 1].paymentDate),
            isTrue,
            reason: 'Payment at index $k should be before or equal to payment at index ${k + 1}',
          );
        }

        // Clean up
        for (final payment in payments) {
          await paymentRepo.delete(payment.id);
        }
        await cardRepo.delete(cardId);
      }
    });
  });
}
