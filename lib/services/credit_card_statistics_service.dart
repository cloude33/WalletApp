import '../repositories/credit_card_transaction_repository.dart';
import '../repositories/credit_card_statement_repository.dart';
import '../repositories/credit_card_repository.dart';

class CreditCardStatisticsService {
  final CreditCardTransactionRepository _transactionRepo =
      CreditCardTransactionRepository();
  final CreditCardStatementRepository _statementRepo =
      CreditCardStatementRepository();
  final CreditCardRepository _cardRepo = CreditCardRepository();
  Future<double> getMonthlyAverageSpending(
    String cardId, {
    int months = 12,
  }) async {
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month - months, 1);

    final transactions = await _transactionRepo.findByDateRange(
      cardId,
      startDate,
      now,
    );

    if (transactions.isEmpty) return 0;

    final totalSpending = transactions.fold<double>(
      0,
      (sum, t) => sum + t.amount,
    );
    return totalSpending / months;
  }
  Future<Map<String, double>> getCategorySpendingBreakdown(
    String cardId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final now = DateTime.now();
    final start = startDate ?? DateTime(now.year, now.month - 12, 1);
    final end = endDate ?? now;

    final transactions = await _transactionRepo.findByDateRange(
      cardId,
      start,
      end,
    );
    final breakdown = <String, double>{};

    for (var transaction in transactions) {
      final category = transaction.category;
      breakdown[category] = (breakdown[category] ?? 0) + transaction.amount;
    }

    return breakdown;
  }
  Future<Map<String, dynamic>> getCashVsInstallmentRatio(String cardId) async {
    final transactions = await _transactionRepo.findByCardId(cardId);

    final cashTransactions = transactions.where((t) => t.installmentCount == 1);
    final installmentTransactions = transactions.where(
      (t) => t.installmentCount > 1,
    );

    final cashCount = cashTransactions.length;
    final installmentCount = installmentTransactions.length;
    final totalCount = transactions.length;

    final cashPercentage = totalCount > 0 ? (cashCount / totalCount) * 100 : 0;
    final installmentPercentage = totalCount > 0
        ? (installmentCount / totalCount) * 100
        : 0;

    final cashTotal = cashTransactions.fold<double>(
      0,
      (sum, t) => sum + t.amount,
    );
    final installmentTotal = installmentTransactions.fold<double>(
      0,
      (sum, t) => sum + t.amount,
    );
    final grandTotal = cashTotal + installmentTotal;

    return {
      'cashCount': cashCount,
      'cashPercentage': cashPercentage,
      'cashTotal': cashTotal,
      'installmentCount': installmentCount,
      'installmentPercentage': installmentPercentage,
      'installmentTotal': installmentTotal,
      'totalCount': totalCount,
      'grandTotal': grandTotal,
    };
  }
  Future<Map<String, dynamic>> getFullVsPartialPaymentRatio(
    String cardId,
  ) async {
    final statements = await _statementRepo.findByCardId(cardId);

    if (statements.isEmpty) {
      return {
        'fullPaymentCount': 0,
        'fullPaymentPercentage': 0.0,
        'partialPaymentCount': 0,
        'partialPaymentPercentage': 0.0,
        'unpaidCount': 0,
        'unpaidPercentage': 0.0,
        'totalCount': 0,
      };
    }

    final fullPayments = statements.where(
      (s) => s.isPaidFully && s.paidAmount > 0,
    );
    final partialPayments = statements.where((s) => s.isPartiallyPaid);
    final unpaid = statements.where((s) => s.paidAmount == 0);

    final fullCount = fullPayments.length;
    final partialCount = partialPayments.length;
    final unpaidCount = unpaid.length;
    final totalCount = statements.length;

    final fullPercentage = (fullCount / totalCount) * 100;
    final partialPercentage = (partialCount / totalCount) * 100;
    final unpaidPercentage = (unpaidCount / totalCount) * 100;

    return {
      'fullPaymentCount': fullCount,
      'fullPaymentPercentage': fullPercentage,
      'partialPaymentCount': partialCount,
      'partialPaymentPercentage': partialPercentage,
      'unpaidCount': unpaidCount,
      'unpaidPercentage': unpaidPercentage,
      'totalCount': totalCount,
    };
  }
  Future<Map<String, double>> getMonthlySpendingTrend(
    String cardId, {
    int months = 12,
  }) async {
    final now = DateTime.now();
    final trend = <String, double>{};

    for (int i = months - 1; i >= 0; i--) {
      final monthDate = DateTime(now.year, now.month - i, 1);
      final monthStart = DateTime(monthDate.year, monthDate.month, 1);
      final monthEnd = DateTime(monthDate.year, monthDate.month + 1, 0);

      final transactions = await _transactionRepo.findByDateRange(
        cardId,
        monthStart,
        monthEnd,
      );

      final monthKey =
          '${monthDate.year}-${monthDate.month.toString().padLeft(2, '0')}';
      final monthTotal = transactions.fold<double>(
        0,
        (sum, t) => sum + t.amount,
      );

      trend[monthKey] = monthTotal;
    }

    return trend;
  }
  Future<Map<String, dynamic>> getComprehensiveStatistics(String cardId) async {
    final monthlyAverage = await getMonthlyAverageSpending(cardId);
    final categoryBreakdown = await getCategorySpendingBreakdown(cardId);
    final cashVsInstallment = await getCashVsInstallmentRatio(cardId);
    final fullVsPartial = await getFullVsPartialPaymentRatio(cardId);
    final monthlyTrend = await getMonthlySpendingTrend(cardId);
    final sortedCategories = categoryBreakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topCategories = sortedCategories.take(5).toList();
    final totalSpending = categoryBreakdown.values.fold<double>(
      0,
      (sum, v) => sum + v,
    );

    return {
      'monthlyAverageSpending': monthlyAverage,
      'totalSpending': totalSpending,
      'categoryBreakdown': categoryBreakdown,
      'topCategories': topCategories,
      'cashVsInstallment': cashVsInstallment,
      'fullVsPartialPayment': fullVsPartial,
      'monthlyTrend': monthlyTrend,
    };
  }
  Future<Map<String, dynamic>> getAllCardsStatistics() async {
    final cards = await _cardRepo.findActive();

    double totalMonthlyAverage = 0;
    final allCategoryBreakdown = <String, double>{};
    int totalCashCount = 0;
    int totalInstallmentCount = 0;
    double totalCashAmount = 0;
    double totalInstallmentAmount = 0;
    int totalFullPayments = 0;
    int totalPartialPayments = 0;
    int totalStatements = 0;

    for (var card in cards) {
      final monthlyAvg = await getMonthlyAverageSpending(card.id);
      totalMonthlyAverage += monthlyAvg;
      final categories = await getCategorySpendingBreakdown(card.id);
      for (var entry in categories.entries) {
        allCategoryBreakdown[entry.key] =
            (allCategoryBreakdown[entry.key] ?? 0) + entry.value;
      }
      final cashVsInstallment = await getCashVsInstallmentRatio(card.id);
      totalCashCount += cashVsInstallment['cashCount'] as int;
      totalInstallmentCount += cashVsInstallment['installmentCount'] as int;
      totalCashAmount += cashVsInstallment['cashTotal'] as double;
      totalInstallmentAmount += cashVsInstallment['installmentTotal'] as double;
      final fullVsPartial = await getFullVsPartialPaymentRatio(card.id);
      totalFullPayments += fullVsPartial['fullPaymentCount'] as int;
      totalPartialPayments += fullVsPartial['partialPaymentCount'] as int;
      totalStatements += fullVsPartial['totalCount'] as int;
    }
    final totalTransactions = totalCashCount + totalInstallmentCount;
    final cashPercentage = totalTransactions > 0
        ? (totalCashCount / totalTransactions) * 100
        : 0;
    final installmentPercentage = totalTransactions > 0
        ? (totalInstallmentCount / totalTransactions) * 100
        : 0;

    final fullPaymentPercentage = totalStatements > 0
        ? (totalFullPayments / totalStatements) * 100
        : 0;
    final partialPaymentPercentage = totalStatements > 0
        ? (totalPartialPayments / totalStatements) * 100
        : 0;
    final sortedCategories = allCategoryBreakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topCategories = sortedCategories.take(5).toList();

    return {
      'totalMonthlyAverage': totalMonthlyAverage,
      'totalSpending': totalCashAmount + totalInstallmentAmount,
      'categoryBreakdown': allCategoryBreakdown,
      'topCategories': topCategories,
      'cashVsInstallment': {
        'cashCount': totalCashCount,
        'cashPercentage': cashPercentage,
        'cashTotal': totalCashAmount,
        'installmentCount': totalInstallmentCount,
        'installmentPercentage': installmentPercentage,
        'installmentTotal': totalInstallmentAmount,
        'totalCount': totalTransactions,
        'grandTotal': totalCashAmount + totalInstallmentAmount,
      },
      'fullVsPartialPayment': {
        'fullPaymentCount': totalFullPayments,
        'fullPaymentPercentage': fullPaymentPercentage,
        'partialPaymentCount': totalPartialPayments,
        'partialPaymentPercentage': partialPaymentPercentage,
        'totalCount': totalStatements,
      },
    };
  }
  Future<List<Map<String, dynamic>>> compareCardSpending() async {
    final cards = await _cardRepo.findActive();
    final comparison = <Map<String, dynamic>>[];

    for (var card in cards) {
      final monthlyAverage = await getMonthlyAverageSpending(card.id);
      final transactions = await _transactionRepo.findByCardId(card.id);
      final totalSpending = transactions.fold<double>(
        0,
        (sum, t) => sum + t.amount,
      );

      comparison.add({
        'card': card,
        'monthlyAverage': monthlyAverage,
        'totalSpending': totalSpending,
        'transactionCount': transactions.length,
      });
    }
    comparison.sort(
      (a, b) => (b['totalSpending'] as double).compareTo(
        a['totalSpending'] as double,
      ),
    );

    return comparison;
  }
  Future<Map<String, double>> getSpendingByPeriod(
    String cardId,
    String period, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final now = DateTime.now();
    final start = startDate ?? DateTime(now.year, now.month - 1, 1);
    final end = endDate ?? now;

    final transactions = await _transactionRepo.findByDateRange(
      cardId,
      start,
      end,
    );
    final spending = <String, double>{};

    for (var transaction in transactions) {
      String key;

      switch (period) {
        case 'daily':
          key =
              '${transaction.transactionDate.year}-'
              '${transaction.transactionDate.month.toString().padLeft(2, '0')}-'
              '${transaction.transactionDate.day.toString().padLeft(2, '0')}';
          break;
        case 'weekly':
          final weekNumber =
              ((transaction.transactionDate.day - 1) / 7).floor() + 1;
          key =
              '${transaction.transactionDate.year}-'
              '${transaction.transactionDate.month.toString().padLeft(2, '0')}-W$weekNumber';
          break;
        case 'monthly':
        default:
          key =
              '${transaction.transactionDate.year}-'
              '${transaction.transactionDate.month.toString().padLeft(2, '0')}';
          break;
      }

      spending[key] = (spending[key] ?? 0) + transaction.amount;
    }

    return spending;
  }
}
