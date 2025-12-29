import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:money/models/credit_card_transaction.dart';
import 'package:money/services/transaction_filter_service.dart';
import 'package:money/services/credit_card_box_service.dart';
import '../property_test_utils.dart';
import 'package:uuid/uuid.dart';

/// Property-based tests for TransactionFilterService
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Initialize Hive for testing with a temporary directory
    Hive.init('./test_hive_filter');

    // Register adapters
    if (!Hive.isAdapterRegistered(15)) {
      Hive.registerAdapter(CreditCardTransactionAdapter());
    }

    // Open boxes
    await CreditCardBoxService.init();
  });

  tearDownAll(() async {
    // Close and delete boxes
    await CreditCardBoxService.close();
    await Hive.deleteFromDisk();
  });

  group('TransactionFilterService Property Tests', () {
    setUp(() async {
      // Clear data before each test
      await CreditCardBoxService.transactionsBox.clear();
    });

    /// **Feature: enhanced-credit-card-tracking, Property 33: Tek Kart Filtreleme**
    /// **Validates: Requirements 10.2**
    ///
    /// Property: For any card selection, the system should list only
    /// transactions belonging to that card.
    PropertyTest.forAll<Map<String, dynamic>>(
      description:
          'Property 33: Single card filter should return only transactions for that card',
      generator: () {
        // Generate random card IDs
        final targetCardId = const Uuid().v4();
        final otherCardIds = List.generate(
          PropertyTest.randomInt(min: 1, max: 5),
          (_) => const Uuid().v4(),
        );

        // Generate transactions for target card
        final targetTransactions = List.generate(
          PropertyTest.randomInt(min: 1, max: 10),
          (_) => CreditCardTransaction(
            id: const Uuid().v4(),
            cardId: targetCardId,
            amount: PropertyTest.randomPositiveDouble(min: 1, max: 10000),
            description: PropertyTest.randomString(),
            category: PropertyTest.randomString(),
            transactionDate: PropertyTest.randomDateTime(),
            createdAt: DateTime.now(),
            installmentCount: 1,
            installmentsPaid: 0,
            isCashAdvance: false,
          ),
        );

        // Generate transactions for other cards
        final otherTransactions = otherCardIds
            .expand(
              (cardId) => List.generate(
                PropertyTest.randomInt(min: 1, max: 10),
                (_) => CreditCardTransaction(
                  id: const Uuid().v4(),
                  cardId: cardId,
                  amount: PropertyTest.randomPositiveDouble(min: 1, max: 10000),
                  description: PropertyTest.randomString(),
                  category: PropertyTest.randomString(),
                  transactionDate: PropertyTest.randomDateTime(),
                  createdAt: DateTime.now(),
                  installmentCount: 1,
                  installmentsPaid: 0,
                  isCashAdvance: false,
                ),
              ),
            )
            .toList();

        // Combine and shuffle all transactions
        final allTransactions = [...targetTransactions, ...otherTransactions];
        allTransactions.shuffle();

        return {
          'targetCardId': targetCardId,
          'allTransactions': allTransactions,
          'expectedCount': targetTransactions.length,
        };
      },
      property: (data) async {
        final targetCardId = data['targetCardId'] as String;
        final allTransactions =
            data['allTransactions'] as List<CreditCardTransaction>;
        final expectedCount = data['expectedCount'] as int;

        // Filter by single card
        final filtered = TransactionFilterService.filterByCards(
          allTransactions,
          [targetCardId],
        );

        // Property 1: All filtered transactions should belong to the target card
        final allBelongToCard = filtered.every((t) => t.cardId == targetCardId);
        expect(
          allBelongToCard,
          isTrue,
          reason: 'All filtered transactions should belong to target card',
        );

        // Property 2: The count should match expected count
        expect(
          filtered.length,
          equals(expectedCount),
          reason: 'Filtered count should match expected count',
        );

        // Property 3: No transactions from other cards should be included
        final noOtherCards = filtered.every((t) => t.cardId == targetCardId);
        expect(
          noOtherCards,
          isTrue,
          reason: 'No transactions from other cards should be included',
        );

        return true;
      },
      iterations: 100,
    );

    /// **Feature: enhanced-credit-card-tracking, Property 34: Çoklu Kart Filtreleme**
    /// **Validates: Requirements 10.3**
    ///
    /// Property: For any multiple card selection, the system should list
    /// transactions belonging to the selected cards.
    PropertyTest.forAll<Map<String, dynamic>>(
      description:
          'Property 34: Multiple card filter should return transactions for selected cards',
      generator: () {
        // Generate random card IDs
        final selectedCardIds = List.generate(
          PropertyTest.randomInt(min: 2, max: 5),
          (_) => const Uuid().v4(),
        );
        final unselectedCardIds = List.generate(
          PropertyTest.randomInt(min: 1, max: 3),
          (_) => const Uuid().v4(),
        );

        // Generate transactions for selected cards
        final selectedTransactions = selectedCardIds
            .expand(
              (cardId) => List.generate(
                PropertyTest.randomInt(min: 1, max: 10),
                (_) => CreditCardTransaction(
                  id: const Uuid().v4(),
                  cardId: cardId,
                  amount: PropertyTest.randomPositiveDouble(min: 1, max: 10000),
                  description: PropertyTest.randomString(),
                  category: PropertyTest.randomString(),
                  transactionDate: PropertyTest.randomDateTime(),
                  createdAt: DateTime.now(),
                  installmentCount: 1,
                  installmentsPaid: 0,
                  isCashAdvance: false,
                ),
              ),
            )
            .toList();

        // Generate transactions for unselected cards
        final unselectedTransactions = unselectedCardIds
            .expand(
              (cardId) => List.generate(
                PropertyTest.randomInt(min: 1, max: 10),
                (_) => CreditCardTransaction(
                  id: const Uuid().v4(),
                  cardId: cardId,
                  amount: PropertyTest.randomPositiveDouble(min: 1, max: 10000),
                  description: PropertyTest.randomString(),
                  category: PropertyTest.randomString(),
                  transactionDate: PropertyTest.randomDateTime(),
                  createdAt: DateTime.now(),
                  installmentCount: 1,
                  installmentsPaid: 0,
                  isCashAdvance: false,
                ),
              ),
            )
            .toList();

        // Combine and shuffle all transactions
        final allTransactions = [
          ...selectedTransactions,
          ...unselectedTransactions,
        ];
        allTransactions.shuffle();

        return {
          'selectedCardIds': selectedCardIds,
          'allTransactions': allTransactions,
          'expectedCount': selectedTransactions.length,
        };
      },
      property: (data) async {
        final selectedCardIds = data['selectedCardIds'] as List<String>;
        final allTransactions =
            data['allTransactions'] as List<CreditCardTransaction>;
        final expectedCount = data['expectedCount'] as int;

        // Filter by multiple cards
        final filtered = TransactionFilterService.filterByCards(
          allTransactions,
          selectedCardIds,
        );

        // Property 1: All filtered transactions should belong to selected cards
        final allBelongToSelectedCards = filtered.every(
          (t) => selectedCardIds.contains(t.cardId),
        );
        expect(
          allBelongToSelectedCards,
          isTrue,
          reason: 'All filtered transactions should belong to selected cards',
        );

        // Property 2: The count should match expected count
        expect(
          filtered.length,
          equals(expectedCount),
          reason: 'Filtered count should match expected count',
        );

        // Property 3: No transactions from unselected cards should be included
        final noUnselectedCards = filtered.every(
          (t) => selectedCardIds.contains(t.cardId),
        );
        expect(
          noUnselectedCards,
          isTrue,
          reason: 'No transactions from unselected cards should be included',
        );

        return true;
      },
      iterations: 100,
    );

    /// **Feature: enhanced-credit-card-tracking, Property 35: Filtrelenmiş Toplam Hesaplama**
    /// **Validates: Requirements 10.4**
    ///
    /// Property: For any filter application, the system should correctly
    /// calculate the filtered total amount.
    PropertyTest.forAll<Map<String, dynamic>>(
      description:
          'Property 35: Filtered total should correctly sum transaction amounts',
      generator: () {
        // Generate random transactions
        final transactions = List.generate(
          PropertyTest.randomInt(min: 5, max: 20),
          (_) => CreditCardTransaction(
            id: const Uuid().v4(),
            cardId: const Uuid().v4(),
            amount: PropertyTest.randomPositiveDouble(min: 1, max: 10000),
            description: PropertyTest.randomString(),
            category: PropertyTest.randomString(),
            transactionDate: PropertyTest.randomDateTime(),
            createdAt: DateTime.now(),
            installmentCount: 1,
            installmentsPaid: 0,
            isCashAdvance: false,
          ),
        );

        // Calculate expected total
        final expectedTotal = transactions.fold(
          0.0,
          (sum, t) => sum + t.amount,
        );

        return {'transactions': transactions, 'expectedTotal': expectedTotal};
      },
      property: (data) async {
        final transactions =
            data['transactions'] as List<CreditCardTransaction>;
        final expectedTotal = data['expectedTotal'] as double;

        // Calculate filtered total
        final calculatedTotal = TransactionFilterService.calculateFilteredTotal(
          transactions,
        );

        // Property 1: The calculated total should match the expected total
        // Use a small epsilon for floating point comparison
        final difference = (calculatedTotal - expectedTotal).abs();
        expect(
          difference,
          lessThan(0.0001),
          reason:
              'Calculated total should match expected total (diff: $difference)',
        );

        // Property 2: Total should be non-negative (since all amounts are positive)
        expect(
          calculatedTotal,
          greaterThanOrEqualTo(0),
          reason: 'Total should be non-negative',
        );

        // Property 3: If transactions list is empty, total should be 0
        final emptyTotal = TransactionFilterService.calculateFilteredTotal([]);
        expect(
          emptyTotal,
          equals(0.0),
          reason: 'Empty list should have total of 0',
        );

        return true;
      },
      iterations: 100,
    );

    /// **Feature: enhanced-credit-card-tracking, Property 36: Filtre Temizleme**
    /// **Validates: Requirements 10.5**
    ///
    /// Property: For any filter clearing, the system should list all
    /// card transactions.
    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 36: Clear filter should return all transactions',
      generator: () {
        // Generate random transactions with various card IDs
        final transactions = List.generate(
          PropertyTest.randomInt(min: 5, max: 20),
          (_) => CreditCardTransaction(
            id: const Uuid().v4(),
            cardId: const Uuid().v4(),
            amount: PropertyTest.randomPositiveDouble(min: 1, max: 10000),
            description: PropertyTest.randomString(),
            category: PropertyTest.randomString(),
            transactionDate: PropertyTest.randomDateTime(),
            createdAt: DateTime.now(),
            installmentCount: 1,
            installmentsPaid: 0,
            isCashAdvance: false,
          ),
        );

        return {
          'transactions': transactions,
          'originalCount': transactions.length,
        };
      },
      property: (data) async {
        final transactions =
            data['transactions'] as List<CreditCardTransaction>;
        final originalCount = data['originalCount'] as int;

        // Clear filter should return all transactions
        final cleared = TransactionFilterService.clearFilter(transactions);

        // Property 1: Cleared list should have same count as original
        expect(
          cleared.length,
          equals(originalCount),
          reason: 'Cleared list should have same count as original',
        );

        // Property 2: Cleared list should contain all original transactions
        final allIncluded = transactions.every((t) => cleared.contains(t));
        expect(
          allIncluded,
          isTrue,
          reason: 'Cleared list should contain all original transactions',
        );

        // Property 3: No transactions should be added
        final noExtras = cleared.every((t) => transactions.contains(t));
        expect(
          noExtras,
          isTrue,
          reason: 'Cleared list should not contain extra transactions',
        );

        // Property 4: Empty list should remain empty after clear filter
        final emptyCleared = TransactionFilterService.clearFilter([]);
        expect(
          emptyCleared.isEmpty,
          isTrue,
          reason: 'Empty list should remain empty after clear',
        );

        return true;
      },
      iterations: 100,
    );
  });
}
