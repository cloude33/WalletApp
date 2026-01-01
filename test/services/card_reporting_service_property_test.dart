import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:parion/models/credit_card.dart';
import 'package:parion/models/credit_card_transaction.dart';
import 'package:parion/models/credit_card_statement.dart';
import 'package:parion/services/card_reporting_service.dart';
import 'package:parion/services/credit_card_box_service.dart';
import '../property_test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Initialize Hive for testing with a temporary directory
    Hive.init('./test_hive_reporting');

    // Register adapters
    if (!Hive.isAdapterRegistered(10)) {
      Hive.registerAdapter(CreditCardAdapter());
    }
    if (!Hive.isAdapterRegistered(11)) {
      Hive.registerAdapter(CreditCardTransactionAdapter());
    }
    if (!Hive.isAdapterRegistered(12)) {
      Hive.registerAdapter(CreditCardStatementAdapter());
    }

    // Open boxes
    await CreditCardBoxService.init();
  });

  tearDownAll(() async {
    // Close and delete boxes
    await CreditCardBoxService.close();
    await Hive.deleteFromDisk();
  });

  group('CardReportingService Property Tests', () {
    late CardReportingService service;

    setUp(() async {
      service = CardReportingService();
      // Clear data before each test
      await CreditCardBoxService.creditCardsBox.clear();
      await CreditCardBoxService.transactionsBox.clear();
      await CreditCardBoxService.statementsBox.clear();
    });

    /// **Feature: enhanced-credit-card-tracking, Property 37: En Çok Harcama Yapılan Kart**
    /// **Validates: Requirements 11.2**
    PropertyTest.forAll<Map<String, dynamic>>(
      description:
          'Property 37: For any set of cards with transactions, the most used card should be correctly identified',
      generator: () {
        // Generate 2-5 cards with varying transaction amounts
        final cardCount = PropertyTest.randomInt(min: 2, max: 5);
        final cards = <CreditCard>[];
        final transactionsByCard = <String, List<CreditCardTransaction>>{};

        for (int i = 0; i < cardCount; i++) {
          final card = CreditCard(
            id: 'card_$i',
            bankName: 'Bank $i',
            cardName: 'Card $i',
            last4Digits: '${1000 + i}',
            creditLimit: PropertyTest.randomPositiveDouble(
              min: 10000,
              max: 50000,
            ),
            statementDay: PropertyTest.randomInt(min: 1, max: 28),
            dueDateOffset: PropertyTest.randomInt(min: 10, max: 20),
            monthlyInterestRate: PropertyTest.randomPositiveDouble(
              min: 1.0,
              max: 5.0,
            ),
            lateInterestRate: PropertyTest.randomPositiveDouble(
              min: 2.0,
              max: 6.0,
            ),
            cardColor: 0xFF000000 + PropertyTest.randomInt(max: 0xFFFFFF),
            createdAt: DateTime.now(),
          );
          cards.add(card);

          // Generate random number of transactions for each card
          final transactionCount = PropertyTest.randomInt(min: 1, max: 20);
          final transactions = <CreditCardTransaction>[];

          for (int j = 0; j < transactionCount; j++) {
            final transaction = CreditCardTransaction(
              id: 'trans_${i}_$j',
              cardId: card.id,
              amount: PropertyTest.randomPositiveDouble(min: 10, max: 1000),
              description: 'Transaction $j',
              transactionDate: PropertyTest.randomDateTime(),
              category: 'e${PropertyTest.randomInt(min: 1, max: 10)}',
              installmentCount: 1,
              createdAt: DateTime.now(),
            );
            transactions.add(transaction);
          }

          transactionsByCard[card.id] = transactions;
        }

        return {
          'cards': cards,
          'transactionsByCard': transactionsByCard,
        };
      },
      property: (data) async {
        // Clear boxes before each iteration
        await CreditCardBoxService.creditCardsBox.clear();
        await CreditCardBoxService.transactionsBox.clear();

        final cards = data['cards'] as List<CreditCard>;
        final transactionsByCard =
            data['transactionsByCard'] as Map<String, List<CreditCardTransaction>>;

        // Save cards and transactions
        for (var card in cards) {
          await CreditCardBoxService.creditCardsBox.put(card.id, card);
        }

        for (var entry in transactionsByCard.entries) {
          for (var transaction in entry.value) {
            await CreditCardBoxService.transactionsBox.put(
              transaction.id,
              transaction,
            );
          }
        }

        // Calculate expected most used card
        String? expectedMostUsedCardId;
        double maxSpending = 0;

        for (var entry in transactionsByCard.entries) {
          final totalSpending = entry.value.fold<double>(
            0,
            (sum, t) => sum + t.amount,
          );

          if (totalSpending > maxSpending) {
            maxSpending = totalSpending;
            expectedMostUsedCardId = entry.key;
          }
        }

        // Get most used card from service
        final result = await service.getMostUsedCard();

        // Verify the property
        if (result['hasCard'] == false) {
          return false; // Should have found a card
        }

        final actualCardId = result['cardId'] as String;
        final actualSpending = result['totalSpending'] as double;

        // The card with the highest spending should be identified
        return actualCardId == expectedMostUsedCardId &&
            (actualSpending - maxSpending).abs() < 0.01;
      },
      iterations: 100,
    );

    /// **Feature: enhanced-credit-card-tracking, Property 38: Kategori Bazlı Kart Kullanımı**
    /// **Validates: Requirements 11.3**
    PropertyTest.forAll<Map<String, dynamic>>(
      description:
          'Property 38: For any category, the system should correctly calculate how much each card spent in that category',
      generator: () {
        // Generate 2-4 cards
        final cardCount = PropertyTest.randomInt(min: 2, max: 4);
        final cards = <CreditCard>[];
        final transactionsByCard = <String, List<CreditCardTransaction>>{};
        
        // Pick a random category to test
        final testCategory = 'e${PropertyTest.randomInt(min: 1, max: 10)}';

        for (int i = 0; i < cardCount; i++) {
          final card = CreditCard(
            id: 'card_$i',
            bankName: 'Bank $i',
            cardName: 'Card $i',
            last4Digits: '${1000 + i}',
            creditLimit: PropertyTest.randomPositiveDouble(
              min: 10000,
              max: 50000,
            ),
            statementDay: PropertyTest.randomInt(min: 1, max: 28),
            dueDateOffset: PropertyTest.randomInt(min: 10, max: 20),
            monthlyInterestRate: PropertyTest.randomPositiveDouble(
              min: 1.0,
              max: 5.0,
            ),
            lateInterestRate: PropertyTest.randomPositiveDouble(
              min: 2.0,
              max: 6.0,
            ),
            cardColor: 0xFF000000 + PropertyTest.randomInt(max: 0xFFFFFF),
            createdAt: DateTime.now(),
          );
          cards.add(card);

          // Generate transactions with mix of categories
          final transactionCount = PropertyTest.randomInt(min: 3, max: 10);
          final transactions = <CreditCardTransaction>[];

          for (int j = 0; j < transactionCount; j++) {
            // Some transactions in test category, some in other categories
            final useTestCategory = PropertyTest.randomBool();
            final transaction = CreditCardTransaction(
              id: 'trans_${i}_$j',
              cardId: card.id,
              amount: PropertyTest.randomPositiveDouble(min: 10, max: 1000),
              description: 'Transaction $j',
              transactionDate: PropertyTest.randomDateTime(),
              category: useTestCategory
                  ? testCategory
                  : 'e${PropertyTest.randomInt(min: 1, max: 10)}',
              installmentCount: 1,
              createdAt: DateTime.now(),
            );
            transactions.add(transaction);
          }

          transactionsByCard[card.id] = transactions;
        }

        return {
          'cards': cards,
          'transactionsByCard': transactionsByCard,
          'testCategory': testCategory,
        };
      },
      property: (data) async {
        // Clear boxes before each iteration
        await CreditCardBoxService.creditCardsBox.clear();
        await CreditCardBoxService.transactionsBox.clear();

        final cards = data['cards'] as List<CreditCard>;
        final transactionsByCard =
            data['transactionsByCard'] as Map<String, List<CreditCardTransaction>>;
        final testCategory = data['testCategory'] as String;

        // Save cards and transactions
        for (var card in cards) {
          await CreditCardBoxService.creditCardsBox.put(card.id, card);
        }

        for (var entry in transactionsByCard.entries) {
          for (var transaction in entry.value) {
            await CreditCardBoxService.transactionsBox.put(
              transaction.id,
              transaction,
            );
          }
        }

        // Calculate expected category breakdown
        final expectedBreakdown = <String, double>{};
        for (var entry in transactionsByCard.entries) {
          final categoryTransactions = entry.value.where(
            (t) => t.category == testCategory,
          );
          final totalSpending = categoryTransactions.fold<double>(
            0,
            (sum, t) => sum + t.amount,
          );

          if (totalSpending > 0) {
            expectedBreakdown[entry.key] = totalSpending;
          }
        }

        // Get category breakdown from service
        final result = await service.getCategoryBreakdownByCard(testCategory);
        final actualBreakdown =
            result['cardBreakdown'] as Map<String, Map<String, dynamic>>;

        // Verify the property: all cards with spending in this category should be present
        // and spending amounts should match
        if (expectedBreakdown.length != actualBreakdown.length) {
          return false;
        }

        for (var entry in expectedBreakdown.entries) {
          if (!actualBreakdown.containsKey(entry.key)) {
            return false;
          }

          final actualSpending =
              actualBreakdown[entry.key]!['totalSpending'] as double;
          if ((actualSpending - entry.value).abs() > 0.01) {
            return false;
          }
        }

        return true;
      },
      iterations: 100,
    );

    /// **Feature: enhanced-credit-card-tracking, Property 39: Yıllık Faiz Hesaplama**
    /// **Validates: Requirements 11.4**
    PropertyTest.forAll<Map<String, dynamic>>(
      description:
          'Property 39: For any card and year, the system should correctly calculate total interest paid',
      generator: () {
        // Generate a card
        final card = CreditCard(
          id: 'test_card',
          bankName: 'Test Bank',
          cardName: 'Test Card',
          last4Digits: '1234',
          creditLimit: PropertyTest.randomPositiveDouble(
            min: 10000,
            max: 50000,
          ),
          statementDay: PropertyTest.randomInt(min: 1, max: 28),
          dueDateOffset: PropertyTest.randomInt(min: 10, max: 20),
          monthlyInterestRate: PropertyTest.randomPositiveDouble(
            min: 1.0,
            max: 5.0,
          ),
          lateInterestRate: PropertyTest.randomPositiveDouble(
            min: 2.0,
            max: 6.0,
          ),
          cardColor: 0xFF000000 + PropertyTest.randomInt(max: 0xFFFFFF),
          createdAt: DateTime.now(),
        );

        // Generate statements for a specific year
        final testYear = 2024;
        final statementCount = PropertyTest.randomInt(min: 3, max: 12);
        final statements = <CreditCardStatement>[];

        for (int i = 0; i < statementCount; i++) {
          final month = (i % 12) + 1;
          final periodStart = DateTime(testYear, month, 1);
          final periodEnd = DateTime(testYear, month, card.statementDay);
          final dueDate = periodEnd.add(Duration(days: card.dueDateOffset));

          final interestCharged = PropertyTest.randomPositiveDouble(min: 0, max: 500);
          final totalDebt = PropertyTest.randomPositiveDouble(min: 100, max: 5000);
          
          final statement = CreditCardStatement(
            id: 'stmt_$i',
            cardId: card.id,
            periodStart: periodStart,
            periodEnd: periodEnd,
            dueDate: dueDate,
            totalDebt: totalDebt,
            minimumPayment: PropertyTest.randomPositiveDouble(min: 50, max: 500),
            interestCharged: interestCharged,
            remainingDebt: totalDebt,
            createdAt: DateTime.now(),
          );
          statements.add(statement);
        }

        return {
          'card': card,
          'statements': statements,
          'testYear': testYear,
        };
      },
      property: (data) async {
        // Clear boxes before each iteration
        await CreditCardBoxService.creditCardsBox.clear();
        await CreditCardBoxService.statementsBox.clear();

        final card = data['card'] as CreditCard;
        final statements = data['statements'] as List<CreditCardStatement>;
        final testYear = data['testYear'] as int;

        // Save card and statements
        await CreditCardBoxService.creditCardsBox.put(card.id, card);

        for (var statement in statements) {
          await CreditCardBoxService.statementsBox.put(
            statement.id,
            statement,
          );
        }

        // Calculate expected total interest
        final expectedInterest = statements.fold<double>(
          0,
          (sum, s) => sum + s.interestCharged,
        );

        // Get total interest from service
        final actualInterest = await service.getTotalInterestPaidYearly(
          card.id,
          testYear,
        );

        // Verify the property: total interest should match
        return (actualInterest - expectedInterest).abs() < 0.01;
      },
      iterations: 100,
    );

    /// **Feature: enhanced-credit-card-tracking, Property 40: Kart Sıralama**
    /// **Validates: Requirements 11.5**
    PropertyTest.forAll<Map<String, dynamic>>(
      description:
          'Property 40: For any set of cards, they should be correctly sorted by spending amount',
      generator: () {
        // Generate 3-6 cards with varying transaction amounts
        final cardCount = PropertyTest.randomInt(min: 3, max: 6);
        final cards = <CreditCard>[];
        final transactionsByCard = <String, List<CreditCardTransaction>>{};

        for (int i = 0; i < cardCount; i++) {
          final card = CreditCard(
            id: 'card_$i',
            bankName: 'Bank $i',
            cardName: 'Card $i',
            last4Digits: '${1000 + i}',
            creditLimit: PropertyTest.randomPositiveDouble(
              min: 10000,
              max: 50000,
            ),
            statementDay: PropertyTest.randomInt(min: 1, max: 28),
            dueDateOffset: PropertyTest.randomInt(min: 10, max: 20),
            monthlyInterestRate: PropertyTest.randomPositiveDouble(
              min: 1.0,
              max: 5.0,
            ),
            lateInterestRate: PropertyTest.randomPositiveDouble(
              min: 2.0,
              max: 6.0,
            ),
            cardColor: 0xFF000000 + PropertyTest.randomInt(max: 0xFFFFFF),
            createdAt: DateTime.now(),
          );
          cards.add(card);

          // Generate random number of transactions for each card
          final transactionCount = PropertyTest.randomInt(min: 1, max: 15);
          final transactions = <CreditCardTransaction>[];

          for (int j = 0; j < transactionCount; j++) {
            final transaction = CreditCardTransaction(
              id: 'trans_${i}_$j',
              cardId: card.id,
              amount: PropertyTest.randomPositiveDouble(min: 10, max: 1000),
              description: 'Transaction $j',
              transactionDate: PropertyTest.randomDateTime(),
              category: 'e${PropertyTest.randomInt(min: 1, max: 10)}',
              installmentCount: 1,
              createdAt: DateTime.now(),
            );
            transactions.add(transaction);
          }

          transactionsByCard[card.id] = transactions;
        }

        return {
          'cards': cards,
          'transactionsByCard': transactionsByCard,
        };
      },
      property: (data) async {
        // Clear boxes before each iteration
        await CreditCardBoxService.creditCardsBox.clear();
        await CreditCardBoxService.transactionsBox.clear();

        final cards = data['cards'] as List<CreditCard>;
        final transactionsByCard =
            data['transactionsByCard'] as Map<String, List<CreditCardTransaction>>;

        // Save cards and transactions
        for (var card in cards) {
          await CreditCardBoxService.creditCardsBox.put(card.id, card);
        }

        for (var entry in transactionsByCard.entries) {
          for (var transaction in entry.value) {
            await CreditCardBoxService.transactionsBox.put(
              transaction.id,
              transaction,
            );
          }
        }

        // Calculate expected sorted order
        final cardSpendingMap = <String, double>{};
        for (var entry in transactionsByCard.entries) {
          final totalSpending = entry.value.fold<double>(
            0,
            (sum, t) => sum + t.amount,
          );
          cardSpendingMap[entry.key] = totalSpending;
        }

        // Sort by spending (descending)
        final expectedOrder = cardSpendingMap.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        // Get sorted cards from service
        final sortedCards = await service.getCardsSortedBySpending();

        // Verify the property: cards should be in descending order by spending
        if (sortedCards.length != expectedOrder.length) {
          return false;
        }

        for (int i = 0; i < sortedCards.length; i++) {
          final actualCardId = sortedCards[i]['cardId'] as String;
          final actualSpending = sortedCards[i]['totalSpending'] as double;
          final expectedCardId = expectedOrder[i].key;
          final expectedSpending = expectedOrder[i].value;

          if (actualCardId != expectedCardId) {
            return false;
          }

          if ((actualSpending - expectedSpending).abs() > 0.01) {
            return false;
          }

          // Verify descending order
          if (i > 0) {
            final previousSpending =
                sortedCards[i - 1]['totalSpending'] as double;
            if (actualSpending > previousSpending) {
              return false; // Not in descending order
            }
          }
        }

        return true;
      },
      iterations: 100,
    );
  });
}
