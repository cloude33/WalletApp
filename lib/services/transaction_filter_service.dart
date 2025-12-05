import '../models/credit_card_transaction.dart';

/// Service for filtering credit card transactions
class TransactionFilterService {
  /// Filter transactions by a single card
  /// 
  /// Returns only transactions that belong to the specified card
  List<CreditCardTransaction> filterByCard(
    List<CreditCardTransaction> transactions,
    String cardId,
  ) {
    return transactions.where((t) => t.cardId == cardId).toList();
  }

  /// Filter transactions by multiple cards
  /// 
  /// Returns transactions that belong to any of the specified cards
  List<CreditCardTransaction> filterByCards(
    List<CreditCardTransaction> transactions,
    List<String> cardIds,
  ) {
    if (cardIds.isEmpty) {
      return transactions;
    }
    return transactions.where((t) => cardIds.contains(t.cardId)).toList();
  }

  /// Calculate total amount for filtered transactions
  /// 
  /// Returns the sum of all transaction amounts in the filtered list
  double calculateFilteredTotal(List<CreditCardTransaction> transactions) {
    return transactions.fold(0.0, (sum, t) => sum + t.amount);
  }

  /// Clear filter (return all transactions)
  /// 
  /// This is a convenience method that simply returns the original list
  List<CreditCardTransaction> clearFilter(
    List<CreditCardTransaction> transactions,
  ) {
    return transactions;
  }
}
