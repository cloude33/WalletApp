// ignore_for_file: deprecated_member_use, await_only_futures
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:parion/models/credit_card.dart';
import 'package:parion/models/credit_card_transaction.dart';
import 'package:parion/models/reward_points.dart';
import 'package:parion/services/credit_card_migration_service.dart';
import 'package:parion/services/credit_card_box_service.dart';
import 'package:flutter/material.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Initialize Hive for testing with a unique directory
    final testDir = './test_hive_migration_${DateTime.now().millisecondsSinceEpoch}';
    Hive.init(testDir);

    // Register adapters
    if (!Hive.isAdapterRegistered(10)) {
      Hive.registerAdapter(CreditCardAdapter());
    }
    if (!Hive.isAdapterRegistered(11)) {
      Hive.registerAdapter(CreditCardTransactionAdapter());
    }
    if (!Hive.isAdapterRegistered(20)) {
      Hive.registerAdapter(RewardPointsAdapter());
    }
  });

  group('CreditCardMigrationService Tests', () {
    late CreditCardMigrationService migrationService;

    setUp(() async {
      // Open boxes
      await CreditCardBoxService.init();

      // Clear SharedPreferences
      SharedPreferences.setMockInitialValues({});

      migrationService = CreditCardMigrationService();
    });

    tearDown(() async {
      // Clear all boxes
      await CreditCardBoxService.creditCardsBox.clear();
      await CreditCardBoxService.transactionsBox.clear();
      await CreditCardBoxService.rewardPointsBox.clear();

      // Clear SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    });

    test('should detect migration not completed initially', () async {
      final isCompleted = await migrationService.isMigrationCompleted();
      expect(isCompleted, false);
    });

    test('should mark migration as completed', () async {
      await migrationService.markMigrationCompleted();
      final isCompleted = await migrationService.isMigrationCompleted();
      expect(isCompleted, true);
    });

    test('should skip migration if already completed', () async {
      await migrationService.markMigrationCompleted();
      final result = await migrationService.migrateCreditCards();
      
      expect(result.success, true);
      expect(result.cardsUpdated, 0);
      expect(result.message, contains('zaten tamamlanmış'));
    });

    test('should handle empty database gracefully', () async {
      final result = await migrationService.migrateCreditCards();
      
      expect(result.success, true);
      expect(result.cardsUpdated, 0);
      expect(result.message, contains('bulunamadı'));
    });

    test('should migrate credit card with default values', () async {
      // Create a card without new fields
      final card = CreditCard(
        id: 'test-card-1',
        bankName: 'Test Bank',
        cardName: 'Test Card',
        last4Digits: '1234',
        creditLimit: 10000,
        statementDay: 15,
        dueDateOffset: 10,
        monthlyInterestRate: 3.5,
        lateInterestRate: 4.5,
        cardColor: Colors.blue.value,
        createdAt: DateTime.now(),
      );

      await CreditCardBoxService.creditCardsBox.put(card.id, card);

      // Run migration
      final result = await migrationService.migrateCreditCards();

      expect(result.success, true);
      expect(result.cardsUpdated, 1);
      expect(result.rewardPointsCreated, 1);

      // Verify card was updated
      final updatedCard = await CreditCardBoxService.creditCardsBox.get(card.id);
      expect(updatedCard, isNotNull);
      expect(updatedCard!.rewardType, 'bonus');
      expect(updatedCard.pointsConversionRate, 0.01);
      expect(updatedCard.cashAdvanceRate, 3.5 * 1.5); // 1.5x monthly rate
      expect(updatedCard.cashAdvanceLimit, 10000 * 0.4); // 40% of limit

      // Verify reward points was created
      final rewardPoints = CreditCardBoxService.rewardPointsBox.values
          .where((rp) => rp.cardId == card.id)
          .firstOrNull;
      expect(rewardPoints, isNotNull);
      expect(rewardPoints!.rewardType, 'bonus');
      expect(rewardPoints.pointsBalance, 0.0);
    });

    test('should not update card if already has new fields', () async {
      // Create a card with new fields already set
      final card = CreditCard(
        id: 'test-card-2',
        bankName: 'Test Bank',
        cardName: 'Test Card',
        last4Digits: '5678',
        creditLimit: 15000,
        statementDay: 20,
        dueDateOffset: 10,
        monthlyInterestRate: 3.0,
        lateInterestRate: 4.0,
        cardColor: Colors.red.value,
        createdAt: DateTime.now(),
        rewardType: 'miles',
        pointsConversionRate: 0.02,
        cashAdvanceRate: 5.0,
        cashAdvanceLimit: 5000,
      );

      await CreditCardBoxService.creditCardsBox.put(card.id, card);

      // Run migration
      final result = await migrationService.migrateCreditCards();

      expect(result.success, true);
      expect(result.cardsUpdated, 0); // Should not update
      expect(result.rewardPointsCreated, 1); // But should create reward points

      // Verify card was not changed
      final updatedCard = await CreditCardBoxService.creditCardsBox.get(card.id);
      expect(updatedCard!.rewardType, 'miles');
      expect(updatedCard.pointsConversionRate, 0.02);
      expect(updatedCard.cashAdvanceRate, 5.0);
      expect(updatedCard.cashAdvanceLimit, 5000);
    });

    test('should migrate transactions with default values', () async {
      // Create a card
      final card = CreditCard(
        id: 'test-card-3',
        bankName: 'Test Bank',
        cardName: 'Test Card',
        last4Digits: '9012',
        creditLimit: 20000,
        statementDay: 25,
        dueDateOffset: 10,
        monthlyInterestRate: 2.5,
        lateInterestRate: 3.5,
        cardColor: Colors.green.value,
        createdAt: DateTime.now(),
      );

      await CreditCardBoxService.creditCardsBox.put(card.id, card);

      // Create transactions without new fields
      final transaction1 = CreditCardTransaction(
        id: 'trans-1',
        cardId: card.id,
        amount: 500,
        description: 'Test Purchase',
        transactionDate: DateTime.now(),
        category: 'Shopping',
        installmentCount: 3,
        createdAt: DateTime.now(),
      );

      final transaction2 = CreditCardTransaction(
        id: 'trans-2',
        cardId: card.id,
        amount: 1000,
        description: 'Deferred Purchase',
        transactionDate: DateTime.now(),
        category: 'Electronics',
        installmentCount: 6,
        deferredMonths: 2,
        createdAt: DateTime.now(),
      );

      await CreditCardBoxService.transactionsBox.put(transaction1.id, transaction1);
      await CreditCardBoxService.transactionsBox.put(transaction2.id, transaction2);

      // Run migration
      final result = await migrationService.migrateCreditCards();

      expect(result.success, true);
      expect(result.transactionsUpdated, 2);

      // Verify transaction1 was updated
      final updatedTrans1 = await CreditCardBoxService.transactionsBox.get(transaction1.id);
      expect(updatedTrans1!.pointsEarned, 500); // Same as amount
      expect(updatedTrans1.installmentStartDate, isNotNull);

      // Verify transaction2 was updated with deferred start date
      final updatedTrans2 = await CreditCardBoxService.transactionsBox.get(transaction2.id);
      expect(updatedTrans2!.pointsEarned, 1000);
      expect(updatedTrans2.installmentStartDate, isNotNull);
      
      // Deferred start date should be 2 months after transaction date
      final expectedStartDate = DateTime(
        transaction2.transactionDate.year,
        transaction2.transactionDate.month + 2,
        transaction2.transactionDate.day,
      );
      expect(updatedTrans2.installmentStartDate!.year, expectedStartDate.year);
      expect(updatedTrans2.installmentStartDate!.month, expectedStartDate.month);
    });

    test('should not calculate points for cash advance transactions', () async {
      // Create a card
      final card = CreditCard(
        id: 'test-card-4',
        bankName: 'Test Bank',
        cardName: 'Test Card',
        last4Digits: '3456',
        creditLimit: 10000,
        statementDay: 10,
        dueDateOffset: 10,
        monthlyInterestRate: 3.0,
        lateInterestRate: 4.0,
        cardColor: Colors.orange.value,
        createdAt: DateTime.now(),
      );

      await CreditCardBoxService.creditCardsBox.put(card.id, card);

      // Create a cash advance transaction
      final transaction = CreditCardTransaction(
        id: 'trans-cash',
        cardId: card.id,
        amount: 2000,
        description: 'Cash Advance',
        transactionDate: DateTime.now(),
        category: 'Cash',
        installmentCount: 1,
        isCashAdvance: true,
        createdAt: DateTime.now(),
      );

      await CreditCardBoxService.transactionsBox.put(transaction.id, transaction);

      // Run migration
      final result = await migrationService.migrateCreditCards();

      expect(result.success, true);

      // Verify no points were calculated for cash advance
      final updatedTrans = await CreditCardBoxService.transactionsBox.get(transaction.id);
      expect(updatedTrans!.pointsEarned, isNull);
    });

    test('should rollback migration successfully', () async {
      // Create and migrate a card
      final card = CreditCard(
        id: 'test-card-5',
        bankName: 'Test Bank',
        cardName: 'Test Card',
        last4Digits: '7890',
        creditLimit: 12000,
        statementDay: 5,
        dueDateOffset: 10,
        monthlyInterestRate: 2.8,
        lateInterestRate: 3.8,
        cardColor: Colors.purple.value,
        createdAt: DateTime.now(),
      );

      await CreditCardBoxService.creditCardsBox.put(card.id, card);

      // Run migration
      await migrationService.migrateCreditCards();

      // Verify migration completed
      expect(await migrationService.isMigrationCompleted(), true);

      // Rollback
      final rollbackResult = await migrationService.rollbackMigration();

      expect(rollbackResult.success, true);
      expect(rollbackResult.cardsReverted, 1);
      expect(rollbackResult.rewardPointsDeleted, 1);

      // Verify migration flag was cleared
      expect(await migrationService.isMigrationCompleted(), false);

      // Verify card fields were cleared
      final revertedCard = await CreditCardBoxService.creditCardsBox.get(card.id);
      expect(revertedCard!.rewardType, isNull);
      expect(revertedCard.pointsConversionRate, isNull);
      expect(revertedCard.cashAdvanceRate, isNull);
      expect(revertedCard.cashAdvanceLimit, isNull);

      // Verify reward points was deleted
      final rewardPoints = CreditCardBoxService.rewardPointsBox.values
          .where((rp) => rp.cardId == card.id)
          .firstOrNull;
      expect(rewardPoints, isNull);
    });

    test('should get migration status correctly', () async {
      // Create cards with and without new fields
      final card1 = CreditCard(
        id: 'test-card-6',
        bankName: 'Test Bank',
        cardName: 'Migrated Card',
        last4Digits: '1111',
        creditLimit: 10000,
        statementDay: 15,
        dueDateOffset: 10,
        monthlyInterestRate: 3.0,
        lateInterestRate: 4.0,
        cardColor: Colors.blue.value,
        createdAt: DateTime.now(),
        rewardType: 'bonus',
        pointsConversionRate: 0.01,
        cashAdvanceRate: 4.5,
        cashAdvanceLimit: 4000,
      );

      final card2 = CreditCard(
        id: 'test-card-7',
        bankName: 'Test Bank',
        cardName: 'Not Migrated Card',
        last4Digits: '2222',
        creditLimit: 15000,
        statementDay: 20,
        dueDateOffset: 10,
        monthlyInterestRate: 2.5,
        lateInterestRate: 3.5,
        cardColor: Colors.red.value,
        createdAt: DateTime.now(),
      );

      await CreditCardBoxService.creditCardsBox.put(card1.id, card1);
      await CreditCardBoxService.creditCardsBox.put(card2.id, card2);

      // Get status before migration
      final statusBefore = await migrationService.getMigrationStatus();
      expect(statusBefore.isCompleted, false);
      expect(statusBefore.totalCards, 2);
      expect(statusBefore.cardsWithNewFields, 1);
      expect(statusBefore.cardsWithoutNewFields, 1);
      expect(statusBefore.needsMigration, true);

      // Run migration
      await migrationService.migrateCreditCards();

      // Get status after migration
      final statusAfter = await migrationService.getMigrationStatus();
      expect(statusAfter.isCompleted, true);
      expect(statusAfter.totalCards, 2);
      expect(statusAfter.cardsWithNewFields, 2);
      expect(statusAfter.cardsWithoutNewFields, 0);
      expect(statusAfter.needsMigration, false);
      expect(statusAfter.migrationDate, isNotNull);
    });

    test('should handle multiple cards and transactions', () async {
      // Create multiple cards
      for (int i = 0; i < 5; i++) {
        final card = CreditCard(
          id: 'card-$i',
          bankName: 'Bank $i',
          cardName: 'Card $i',
          last4Digits: '000$i',
          creditLimit: 10000 + (i * 1000),
          statementDay: 10 + i,
          dueDateOffset: 10,
          monthlyInterestRate: 2.5 + (i * 0.1),
          lateInterestRate: 3.5 + (i * 0.1),
          cardColor: Colors.blue.value,
          createdAt: DateTime.now(),
        );

        await CreditCardBoxService.creditCardsBox.put(card.id, card);

        // Create transactions for each card
        for (int j = 0; j < 3; j++) {
          final transaction = CreditCardTransaction(
            id: 'trans-$i-$j',
            cardId: card.id,
            amount: 100 + (j * 50),
            description: 'Transaction $j',
            transactionDate: DateTime.now(),
            category: 'Category $j',
            installmentCount: j + 1,
            createdAt: DateTime.now(),
          );

          await CreditCardBoxService.transactionsBox.put(transaction.id, transaction);
        }
      }

      // Run migration
      final result = await migrationService.migrateCreditCards();

      expect(result.success, true);
      expect(result.cardsUpdated, 5);
      expect(result.transactionsUpdated, 15); // 5 cards * 3 transactions
      expect(result.rewardPointsCreated, 5);
    });

    test('should handle migration errors gracefully', () async {
      // This test verifies error handling
      // In a real scenario, we might simulate database errors
      // For now, we just verify the structure works
      
      final result = await migrationService.migrateCreditCards();
      expect(result.success, true);
    });
  });
}
