import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:parion/models/credit_card.dart';
import 'package:parion/models/credit_card_statement.dart';
import 'package:parion/models/credit_card_transaction.dart';
import 'package:parion/models/credit_card_payment.dart';
import 'package:parion/services/credit_card_service.dart';
import 'package:parion/services/credit_card_box_service.dart';
import 'package:parion/repositories/credit_card_repository.dart';
import 'package:parion/repositories/credit_card_statement_repository.dart';
import 'package:parion/repositories/credit_card_transaction_repository.dart';
import '../property_test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  setUpAll(() async {
    // Initialize Hive for testing with a temporary directory
    Hive.init('./test_hive_cc_service');
    
    // Register adapters
    Hive.registerAdapter(CreditCardAdapter());
    Hive.registerAdapter(CreditCardTransactionAdapter());
    Hive.registerAdapter(CreditCardStatementAdapter());
    Hive.registerAdapter(CreditCardPaymentAdapter());
    
    // Initialize CreditCardBoxService which opens boxes
    await CreditCardBoxService.init();
  });

  tearDownAll(() async {
    await CreditCardBoxService.close();
    await Hive.deleteFromDisk();
  });

  setUp(() async {
    // Clear all boxes before each test
    await CreditCardBoxService.creditCardsBox.clear();
    await CreditCardBoxService.transactionsBox.clear();
    await CreditCardBoxService.statementsBox.clear();
    await CreditCardBoxService.paymentsBox.clear();
  });

  CreditCard generateRandomCard() {
    return CreditCard(
      id: PropertyTest.randomString(),
      cardName: PropertyTest.randomString(),
      bankName: PropertyTest.randomString(),
      last4Digits: '1234',
      creditLimit: PropertyTest.randomPositiveDouble(min: 5000, max: 50000),
      statementDay: PropertyTest.randomInt(min: 1, max: 28),
      dueDateOffset: PropertyTest.randomInt(min: 10, max: 20),
      monthlyInterestRate: PropertyTest.randomPositiveDouble(min: 1, max: 5),
      lateInterestRate: PropertyTest.randomPositiveDouble(min: 1, max: 5),
      cardColor: 0xFF2196F3,
      initialDebt: 0,
      createdAt: DateTime.now(),
    );
  }

  group('CreditCardService Property Tests', () {
    test('Property 29: Dönem Borcu Hesaplama - Feature: enhanced-credit-card-tracking, Property 29', () async {
      // **Feature: enhanced-credit-card-tracking, Property 29: Dönem Borcu Hesaplama**
      // **Validates: Requirements 9.2**
      // For any statement cut date, the system should calculate and record the period debt

      final cardRepo = CreditCardRepository();
      final statementRepo = CreditCardStatementRepository();

      for (int i = 0; i < 100; i++) {
        // Clear data for each iteration
        await CreditCardBoxService.creditCardsBox.clear();
        await CreditCardBoxService.statementsBox.clear();

        // Generate random card
        final card = generateRandomCard();
        await cardRepo.save(card);

        // Generate random statement with period debt
        final periodDebt = PropertyTest.randomPositiveDouble(min: 100, max: 5000);
        final statement = CreditCardStatement(
          id: PropertyTest.randomString(),
          cardId: card.id,
          periodStart: DateTime.now().subtract(const Duration(days: 30)),
          periodEnd: DateTime.now(),
          dueDate: DateTime.now().add(const Duration(days: 15)),
          newPurchases: periodDebt,
          totalDebt: periodDebt,
          minimumPayment: periodDebt * 0.33,
          remainingDebt: periodDebt,
          createdAt: DateTime.now(),
        );

        await statementRepo.save(statement);

        // Verify the period debt is recorded correctly
        final savedStatement = await statementRepo.findById(statement.id);
        expect(savedStatement, isNotNull);
        expect(savedStatement!.newPurchases, equals(periodDebt));
        expect(savedStatement.totalDebt, greaterThanOrEqualTo(periodDebt));
      }
    });

    test('Property 30: Harcama Dönem Borcu Ekleme - Feature: enhanced-credit-card-tracking, Property 30', () async {
      // **Feature: enhanced-credit-card-tracking, Property 30: Harcama Dönem Borcu Ekleme**
      // **Validates: Requirements 9.3**
      // For any new expense, the new period debt should be calculated by adding the expense to the old period debt

      final service = CreditCardService();
      final cardRepo = CreditCardRepository();
      final transactionRepo = CreditCardTransactionRepository();

      for (int i = 0; i < 100; i++) {
        // Clear data for each iteration
        await CreditCardBoxService.creditCardsBox.clear();
        await CreditCardBoxService.transactionsBox.clear();

        // Generate random card
        final card = generateRandomCard();
        await cardRepo.save(card);

        // Get initial debt (should be 0 or initialDebt)
        final initialDebt = await service.getCurrentDebt(card.id);

        // Generate random transaction
        final transactionAmount = PropertyTest.randomPositiveDouble(min: 10, max: 1000);
        final transaction = CreditCardTransaction(
          id: PropertyTest.randomString(),
          cardId: card.id,
          amount: transactionAmount,
          description: PropertyTest.randomString(),
          transactionDate: DateTime.now(),
          category: 'Test',
          installmentCount: 1,
          installmentsPaid: 0,
          isCashAdvance: false,
          createdAt: DateTime.now(),
        );

        await transactionRepo.save(transaction);

        // Get new debt after transaction
        final newDebt = await service.getCurrentDebt(card.id);

        // Verify: new debt = old debt + transaction amount
        expect(newDebt, closeTo(initialDebt + transactionAmount, 0.01));
      }
    });

    test('Property 31: Eski Dönem Borcu Ödeme Önceliği - Feature: enhanced-credit-card-tracking, Property 31', () async {
      // **Feature: enhanced-credit-card-tracking, Property 31: Eski Dönem Borcu Ödeme Önceliği**
      // **Validates: Requirements 9.4**
      // For any payment, the system should apply payment to old period debts first

      final service = CreditCardService();
      final cardRepo = CreditCardRepository();
      final statementRepo = CreditCardStatementRepository();

      for (int i = 0; i < 100; i++) {
        // Clear data for each iteration
        await CreditCardBoxService.creditCardsBox.clear();
        await CreditCardBoxService.statementsBox.clear();
        await CreditCardBoxService.paymentsBox.clear();

        // Generate random card
        final card = generateRandomCard();
        await cardRepo.save(card);

        // Create two statements: old and new
        final oldStatementDebt = PropertyTest.randomPositiveDouble(min: 100, max: 2000);
        final oldStatement = CreditCardStatement(
          id: PropertyTest.randomString(),
          cardId: card.id,
          periodStart: DateTime.now().subtract(const Duration(days: 60)),
          periodEnd: DateTime.now().subtract(const Duration(days: 30)),
          dueDate: DateTime.now().subtract(const Duration(days: 15)),
          newPurchases: oldStatementDebt,
          totalDebt: oldStatementDebt,
          minimumPayment: oldStatementDebt * 0.33,
          remainingDebt: oldStatementDebt,
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
        );

        final newStatementDebt = PropertyTest.randomPositiveDouble(min: 100, max: 2000);
        final newStatement = CreditCardStatement(
          id: PropertyTest.randomString(),
          cardId: card.id,
          periodStart: DateTime.now().subtract(const Duration(days: 30)),
          periodEnd: DateTime.now(),
          dueDate: DateTime.now().add(const Duration(days: 15)),
          previousBalance: oldStatementDebt,
          newPurchases: newStatementDebt,
          totalDebt: oldStatementDebt + newStatementDebt,
          minimumPayment: (oldStatementDebt + newStatementDebt) * 0.33,
          remainingDebt: oldStatementDebt + newStatementDebt,
          createdAt: DateTime.now(),
        );

        await statementRepo.save(oldStatement);
        await statementRepo.save(newStatement);

        // Make a partial payment (less than old statement debt)
        final paymentAmount = oldStatementDebt * 0.5;
        final payment = CreditCardPayment(
          id: PropertyTest.randomString(),
          cardId: card.id,
          statementId: oldStatement.id,
          amount: paymentAmount,
          paymentDate: DateTime.now(),
          paymentMethod: 'other',
          createdAt: DateTime.now(),
        );

        await service.recordPayment(payment);

        // Verify old statement debt was reduced first
        final updatedOldStatement = await statementRepo.findById(oldStatement.id);
        expect(updatedOldStatement, isNotNull);
        expect(updatedOldStatement!.remainingDebt, closeTo(oldStatementDebt - paymentAmount, 0.01));

        // Verify new statement debt remains unchanged
        final updatedNewStatement = await statementRepo.findById(newStatement.id);
        expect(updatedNewStatement, isNotNull);
        expect(updatedNewStatement!.remainingDebt, closeTo(oldStatementDebt + newStatementDebt, 0.01));
      }
    });

    test('Property 32: Toplam Borç Hesaplama - Feature: enhanced-credit-card-tracking, Property 32', () async {
      // **Feature: enhanced-credit-card-tracking, Property 32: Toplam Borç Hesaplama**
      // **Validates: Requirements 9.5**
      // For any card, the total debt should be the sum of all period debts

      final service = CreditCardService();
      final cardRepo = CreditCardRepository();
      final statementRepo = CreditCardStatementRepository();

      for (int i = 0; i < 100; i++) {
        // Clear data for each iteration
        await CreditCardBoxService.creditCardsBox.clear();
        await CreditCardBoxService.statementsBox.clear();

        // Generate random card
        final card = generateRandomCard();
        await cardRepo.save(card);

        // Generate random number of statements (1-5)
        final statementCount = PropertyTest.randomInt(min: 1, max: 5);
        double expectedTotalDebt = 0;

        for (int j = 0; j < statementCount; j++) {
          final statementDebt = PropertyTest.randomPositiveDouble(min: 50, max: 1000);
          expectedTotalDebt += statementDebt;

          final statement = CreditCardStatement(
            id: PropertyTest.randomString(),
            cardId: card.id,
            periodStart: DateTime.now().subtract(Duration(days: 30 * (j + 1))),
            periodEnd: DateTime.now().subtract(Duration(days: 30 * j)),
            dueDate: DateTime.now().subtract(Duration(days: 30 * j - 15)),
            newPurchases: statementDebt,
            totalDebt: statementDebt,
            minimumPayment: statementDebt * 0.33,
            remainingDebt: statementDebt,
            createdAt: DateTime.now().subtract(Duration(days: 30 * j)),
          );

          await statementRepo.save(statement);
        }

        // Get total debt from service
        final actualTotalDebt = await service.getCurrentDebt(card.id);

        // Verify: total debt = sum of all statement debts
        expect(actualTotalDebt, closeTo(expectedTotalDebt, 0.01));
      }
    });
  });
}
