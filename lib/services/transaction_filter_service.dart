import '../models/transaction.dart';
import '../models/credit_card_transaction.dart';
class TransactionFilterService {
  static List<dynamic> filterByTime({
    required List<Transaction> transactions,
    required List<CreditCardTransaction> creditCardTransactions,
    required String timeFilter,
    DateTime? customStartDate,
    DateTime? customEndDate,
  }) {
    final now = DateTime.now();
    DateTime startDate;
    DateTime? endDate;

    switch (timeFilter) {
      case 'Günlük':
        startDate = DateTime(now.year, now.month, now.day);
        endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case 'Haftalık':
        startDate = now.subtract(const Duration(days: 7));
        endDate = now;
        break;
      case 'Aylık':
        startDate = DateTime(now.year, now.month, 1);
        endDate = now;
        break;
      case 'Yıllık':
        startDate = DateTime(now.year, 1, 1);
        endDate = now;
        break;
      case 'Özel':
        if (customStartDate != null && customEndDate != null) {
          startDate = customStartDate;
          endDate = customEndDate;
        } else {
          startDate = DateTime(now.year, now.month, 1);
          endDate = now;
        }
        break;
      default:
        startDate = DateTime(now.year, now.month, 1);
        endDate = now;
    }
    final regularFiltered = transactions.where((t) {
      if (endDate != null) {
        return t.date.isAfter(startDate.subtract(const Duration(seconds: 1))) &&
            t.date.isBefore(endDate.add(const Duration(seconds: 1)));
      } else {
        return t.date.isAfter(startDate.subtract(const Duration(seconds: 1)));
      }
    }).toList();
    final creditCardFiltered = creditCardTransactions.where((t) {
      if (endDate != null) {
        return t.transactionDate.isAfter(
              startDate.subtract(const Duration(seconds: 1)),
            ) &&
            t.transactionDate.isBefore(endDate.add(const Duration(seconds: 1)));
      } else {
        return t.transactionDate.isAfter(
          startDate.subtract(const Duration(seconds: 1)),
        );
      }
    }).toList();

    return [...regularFiltered, ...creditCardFiltered];
  }
  static List<dynamic> filterByCategory({
    required List<dynamic> transactions,
    required List<String> categories,
  }) {
    if (categories.isEmpty || categories.contains('all')) {
      return transactions;
    }

    return transactions.where((t) {
      if (t is Transaction) {
        return categories.contains(t.category);
      } else if (t is CreditCardTransaction) {
        return categories.contains(t.category);
      }
      return false;
    }).toList();
  }
  static List<dynamic> filterByWallet({
    required List<dynamic> transactions,
    required List<String> walletIds,
  }) {
    if (walletIds.isEmpty || walletIds.contains('all')) {
      return transactions;
    }

    return transactions.where((t) {
      if (t is Transaction) {
        return walletIds.contains(t.walletId);
      } else if (t is CreditCardTransaction) {
        return walletIds.contains(t.cardId);
      }
      return false;
    }).toList();
  }
  static List<dynamic> filterByType({
    required List<dynamic> transactions,
    required String type,
  }) {
    if (type == 'all') {
      return transactions;
    }

    return transactions.where((t) {
      if (t is Transaction) {
        return t.type == type;
      } else if (t is CreditCardTransaction) {
        return type == 'expense';
      }
      return false;
    }).toList();
  }
  static List<dynamic> applyFilters({
    required List<Transaction> transactions,
    required List<CreditCardTransaction> creditCardTransactions,
    required String timeFilter,
    DateTime? customStartDate,
    DateTime? customEndDate,
    List<String>? categories,
    List<String>? walletIds,
    String? transactionType,
  }) {
    var filtered = filterByTime(
      transactions: transactions,
      creditCardTransactions: creditCardTransactions,
      timeFilter: timeFilter,
      customStartDate: customStartDate,
      customEndDate: customEndDate,
    );
    if (categories != null && categories.isNotEmpty) {
      filtered = filterByCategory(
        transactions: filtered,
        categories: categories,
      );
    }
    if (walletIds != null && walletIds.isNotEmpty) {
      filtered = filterByWallet(transactions: filtered, walletIds: walletIds);
    }
    if (transactionType != null && transactionType != 'all') {
      filtered = filterByType(transactions: filtered, type: transactionType);
    }

    return filtered;
  }
  static List<dynamic> searchTransactions({
    required List<dynamic> transactions,
    required String query,
  }) {
    if (query.isEmpty) {
      return transactions;
    }

    final lowerQuery = query.toLowerCase();

    return transactions.where((t) {
      if (t is Transaction) {
        final descriptionMatch = t.description.toLowerCase().contains(
          lowerQuery,
        );
        final categoryMatch = t.category.toLowerCase().contains(lowerQuery);
        final fuzzyDescriptionMatch = _fuzzyMatch(
          t.description.toLowerCase(),
          lowerQuery,
        );
        final fuzzyCategoryMatch = _fuzzyMatch(
          t.category.toLowerCase(),
          lowerQuery,
        );

        return descriptionMatch ||
            categoryMatch ||
            fuzzyDescriptionMatch ||
            fuzzyCategoryMatch;
      } else if (t is CreditCardTransaction) {
        final descriptionMatch = t.description.toLowerCase().contains(
          lowerQuery,
        );
        final categoryMatch = t.category.toLowerCase().contains(lowerQuery);
        final fuzzyDescriptionMatch = _fuzzyMatch(
          t.description.toLowerCase(),
          lowerQuery,
        );
        final fuzzyCategoryMatch = _fuzzyMatch(
          t.category.toLowerCase(),
          lowerQuery,
        );

        return descriptionMatch ||
            categoryMatch ||
            fuzzyDescriptionMatch ||
            fuzzyCategoryMatch;
      }
      return false;
    }).toList();
  }
  static bool _fuzzyMatch(String text, String query) {
    if (query.isEmpty) return true;
    if (text.isEmpty) return false;

    int queryIndex = 0;
    int textIndex = 0;

    while (textIndex < text.length && queryIndex < query.length) {
      if (text[textIndex] == query[queryIndex]) {
        queryIndex++;
      }
      textIndex++;
    }

    return queryIndex == query.length;
  }
  static List<dynamic> clearFilters({
    required List<Transaction> transactions,
    required List<CreditCardTransaction> creditCardTransactions,
  }) {
    return [...transactions, ...creditCardTransactions];
  }
  static Map<String, DateTime?> getDateRange({
    required String timeFilter,
    DateTime? customStartDate,
    DateTime? customEndDate,
  }) {
    final now = DateTime.now();
    DateTime startDate;
    DateTime? endDate;

    switch (timeFilter) {
      case 'Günlük':
        startDate = DateTime(now.year, now.month, now.day);
        endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case 'Haftalık':
        startDate = now.subtract(const Duration(days: 7));
        endDate = now;
        break;
      case 'Aylık':
        startDate = DateTime(now.year, now.month, 1);
        endDate = now;
        break;
      case 'Yıllık':
        startDate = DateTime(now.year, 1, 1);
        endDate = now;
        break;
      case 'Özel':
        if (customStartDate != null && customEndDate != null) {
          startDate = customStartDate;
          endDate = customEndDate;
        } else {
          startDate = DateTime(now.year, now.month, 1);
          endDate = now;
        }
        break;
      default:
        startDate = DateTime(now.year, now.month, 1);
        endDate = now;
    }

    return {'startDate': startDate, 'endDate': endDate};
  }
  static List<CreditCardTransaction> filterByCards(
    List<CreditCardTransaction> transactions,
    List<String> cardIds,
  ) {
    if (cardIds.isEmpty) {
      return transactions;
    }

    return transactions.where((transaction) {
      return cardIds.contains(transaction.cardId);
    }).toList();
  }
  static double calculateFilteredTotal(
    List<CreditCardTransaction> transactions,
  ) {
    return transactions.fold(
      0.0,
      (sum, transaction) => sum + transaction.amount,
    );
  }
  static List<CreditCardTransaction> clearFilter(
    List<CreditCardTransaction> transactions,
  ) {
    return transactions;
  }
}
