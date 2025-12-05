import '../repositories/credit_card_repository.dart';
import '../repositories/credit_card_transaction_repository.dart';
import '../repositories/credit_card_statement_repository.dart';

/// Service for card-based reporting and analytics
class CardReportingService {
  final CreditCardRepository _cardRepo = CreditCardRepository();
  final CreditCardTransactionRepository _transactionRepo =
      CreditCardTransactionRepository();
  final CreditCardStatementRepository _statementRepo =
      CreditCardStatementRepository();

  // ==================== CARD-BASED REPORTING ====================

  /// Get monthly spending trend for a specific card
  /// Returns a map of month -> total spending
  Future<Map<String, dynamic>> getMonthlySpendingTrend(
    String cardId,
    int months,
  ) async {
    final card = await _cardRepo.findById(cardId);
    if (card == null) {
      throw Exception('Kart bulunamadı');
    }

    final now = DateTime.now();
    final trendData = <DateTime, double>{};

    // Initialize all months with 0
    for (int i = 0; i < months; i++) {
      final month = DateTime(now.year, now.month - i, 1);
      trendData[month] = 0;
    }

    // Get all transactions for the card
    final transactions = await _transactionRepo.findByCardId(cardId);

    // Calculate spending for each month
    for (var transaction in transactions) {
      final transactionMonth = DateTime(
        transaction.transactionDate.year,
        transaction.transactionDate.month,
        1,
      );

      if (trendData.containsKey(transactionMonth)) {
        trendData[transactionMonth] =
            (trendData[transactionMonth] ?? 0) + transaction.amount;
      }
    }

    return {
      'cardId': cardId,
      'cardName': '${card.bankName} ${card.cardName}',
      'months': months,
      'trendData': trendData,
    };
  }

  /// Compare card usage across all cards
  /// Returns spending statistics for each card
  Future<Map<String, dynamic>> compareCardUsage() async {
    final cards = await _cardRepo.findActive();
    final cardUsageData = <String, Map<String, dynamic>>{};

    for (var card in cards) {
      final transactions = await _transactionRepo.findByCardId(card.id);
      final totalSpending = transactions.fold<double>(
        0,
        (sum, t) => sum + t.amount,
      );
      final transactionCount = transactions.length;
      final averageTransaction =
          transactionCount > 0 ? totalSpending / transactionCount : 0;

      cardUsageData[card.id] = {
        'cardName': '${card.bankName} ${card.cardName}',
        'totalSpending': totalSpending,
        'transactionCount': transactionCount,
        'averageTransaction': averageTransaction,
        'creditLimit': card.creditLimit,
        'utilizationRate': card.creditLimit > 0
            ? (totalSpending / card.creditLimit) * 100
            : 0,
      };
    }

    return {
      'cards': cardUsageData,
      'totalCards': cards.length,
    };
  }

  /// Get category breakdown by card
  /// Shows how much each card spent in a specific category
  Future<Map<String, dynamic>> getCategoryBreakdownByCard(
    String categoryId,
  ) async {
    final cards = await _cardRepo.findActive();
    final categoryData = <String, Map<String, dynamic>>{};

    for (var card in cards) {
      final transactions = await _transactionRepo.findByCategory(
        card.id,
        categoryId,
      );
      final totalSpending = transactions.fold<double>(
        0,
        (sum, t) => sum + t.amount,
      );

      if (totalSpending > 0) {
        categoryData[card.id] = {
          'cardName': '${card.bankName} ${card.cardName}',
          'totalSpending': totalSpending,
          'transactionCount': transactions.length,
        };
      }
    }

    return {
      'categoryId': categoryId,
      'cardBreakdown': categoryData,
    };
  }

  /// Get total interest paid yearly for a specific card
  Future<double> getTotalInterestPaidYearly(String cardId, int year) async {
    final card = await _cardRepo.findById(cardId);
    if (card == null) {
      throw Exception('Kart bulunamadı');
    }

    // Get all statements for the year
    final statements = await _statementRepo.findByCardId(cardId);
    final yearStatements = statements.where(
      (s) => s.periodEnd.year == year,
    );

    // Sum up interest charges from statements
    double totalInterest = 0;
    for (var statement in yearStatements) {
      totalInterest += statement.interestCharged;
    }

    return totalInterest;
  }

  // ==================== COMPARATIVE ANALYSES ====================

  /// Get the most used card based on transaction count and spending
  Future<Map<String, dynamic>> getMostUsedCard() async {
    final cards = await _cardRepo.findActive();

    if (cards.isEmpty) {
      return {
        'hasCard': false,
      };
    }

    String? mostUsedCardId;
    double maxSpending = 0;
    int maxTransactions = 0;

    for (var card in cards) {
      final transactions = await _transactionRepo.findByCardId(card.id);
      // Use total amount, not remaining amount, for spending comparison
      final totalSpending = transactions.fold<double>(
        0,
        (sum, t) => sum + t.amount,
      );

      if (totalSpending > maxSpending) {
        maxSpending = totalSpending;
        maxTransactions = transactions.length;
        mostUsedCardId = card.id;
      }
    }

    if (mostUsedCardId == null) {
      return {
        'hasCard': false,
      };
    }

    final mostUsedCard = await _cardRepo.findById(mostUsedCardId);

    return {
      'hasCard': true,
      'cardId': mostUsedCardId,
      'cardName': '${mostUsedCard!.bankName} ${mostUsedCard.cardName}',
      'totalSpending': maxSpending,
      'transactionCount': maxTransactions,
    };
  }

  /// Get card utilization comparison across all cards
  Future<Map<String, dynamic>> getCardUtilizationComparison() async {
    final cards = await _cardRepo.findActive();
    final utilizationData = <String, Map<String, dynamic>>{};

    for (var card in cards) {
      final transactions = await _transactionRepo.findByCardId(card.id);
      final currentDebt = transactions.fold<double>(
        0,
        (sum, t) => sum + t.remainingAmount,
      );

      final utilizationPercentage = card.creditLimit > 0
          ? (currentDebt / card.creditLimit) * 100
          : 0;

      utilizationData[card.id] = {
        'cardName': '${card.bankName} ${card.cardName}',
        'creditLimit': card.creditLimit,
        'currentDebt': currentDebt,
        'availableCredit': card.creditLimit - currentDebt,
        'utilizationPercentage': utilizationPercentage,
      };
    }

    return {
      'cards': utilizationData,
      'totalCards': cards.length,
    };
  }

  /// Get card efficiency report
  /// Compares rewards earned vs interest paid
  Future<Map<String, dynamic>> getCardEfficiencyReport() async {
    final cards = await _cardRepo.findActive();
    final efficiencyData = <String, Map<String, dynamic>>{};

    for (var card in cards) {
      // Get total spending
      final transactions = await _transactionRepo.findByCardId(card.id);
      final totalSpending = transactions.fold<double>(
        0,
        (sum, t) => sum + t.amount,
      );

      // Get total interest paid (from statements)
      final statements = await _statementRepo.findByCardId(card.id);
      final totalInterest = statements.fold<double>(
        0,
        (sum, s) => sum + s.interestCharged,
      );

      // Calculate efficiency score (lower is better)
      final efficiencyScore = totalSpending > 0
          ? (totalInterest / totalSpending) * 100
          : 0;

      efficiencyData[card.id] = {
        'cardName': '${card.bankName} ${card.cardName}',
        'totalSpending': totalSpending,
        'totalInterest': totalInterest,
        'efficiencyScore': efficiencyScore,
      };
    }

    return {
      'cards': efficiencyData,
      'totalCards': cards.length,
    };
  }

  // ==================== TREND ANALYSES ====================

  /// Get spending trend for all cards
  Future<List<Map<String, dynamic>>> getSpendingTrendAllCards(
    int months,
  ) async {
    final cards = await _cardRepo.findActive();
    final allCardsTrend = <Map<String, dynamic>>[];

    for (var card in cards) {
      final trend = await getMonthlySpendingTrend(card.id, months);
      allCardsTrend.add(trend);
    }

    return allCardsTrend;
  }

  /// Get yearly card summary
  Future<Map<String, dynamic>> getYearlyCardSummary(
    String cardId,
    int year,
  ) async {
    final card = await _cardRepo.findById(cardId);
    if (card == null) {
      throw Exception('Kart bulunamadı');
    }

    // Get all transactions for the year
    final allTransactions = await _transactionRepo.findByCardId(cardId);
    final yearTransactions = allTransactions.where(
      (t) => t.transactionDate.year == year,
    );

    final totalSpending = yearTransactions.fold<double>(
      0,
      (sum, t) => sum + t.amount,
    );

    // Get interest paid
    final totalInterest = await getTotalInterestPaidYearly(cardId, year);

    // Get category breakdown
    final categoryBreakdown = <String, double>{};
    for (var transaction in yearTransactions) {
      categoryBreakdown[transaction.category] =
          (categoryBreakdown[transaction.category] ?? 0) + transaction.amount;
    }

    // Sort categories by spending
    final sortedCategories = categoryBreakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return {
      'cardId': cardId,
      'cardName': '${card.bankName} ${card.cardName}',
      'year': year,
      'totalSpending': totalSpending,
      'totalInterest': totalInterest,
      'transactionCount': yearTransactions.length,
      'categoryBreakdown': Map.fromEntries(sortedCategories),
      'averageMonthlySpending': totalSpending / 12,
    };
  }

  /// Get cards sorted by spending amount
  Future<List<Map<String, dynamic>>> getCardsSortedBySpending() async {
    final cards = await _cardRepo.findActive();
    final cardSpendingList = <Map<String, dynamic>>[];

    for (var card in cards) {
      final transactions = await _transactionRepo.findByCardId(card.id);
      final totalSpending = transactions.fold<double>(
        0,
        (sum, t) => sum + t.amount,
      );

      cardSpendingList.add({
        'cardId': card.id,
        'cardName': '${card.bankName} ${card.cardName}',
        'totalSpending': totalSpending,
        'transactionCount': transactions.length,
      });
    }

    // Sort by spending amount (descending)
    cardSpendingList.sort(
      (a, b) => (b['totalSpending'] as double).compareTo(
        a['totalSpending'] as double,
      ),
    );

    return cardSpendingList;
  }
}
