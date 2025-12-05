import '../repositories/credit_card_repository.dart';
import '../repositories/credit_card_statement_repository.dart';
import '../utils/cache_manager.dart';
import 'credit_card_service.dart';

class DashboardService {
  final CreditCardRepository _cardRepo = CreditCardRepository();
  final CreditCardStatementRepository _statementRepo =
      CreditCardStatementRepository();
  final CreditCardService _cardService = CreditCardService();
  final CacheManager _cache = CacheManager();

  /// Get dashboard summary with all key metrics
  /// Uses caching to improve performance
  Future<Map<String, dynamic>> getDashboardSummary({
    bool forceRefresh = false,
  }) async {
    // Check cache first
    if (!forceRefresh) {
      final cached = _cache.get<Map<String, dynamic>>(
        CacheKeys.dashboardSummary,
      );
      if (cached != null) {
        return cached;
      }
    }

    // Calculate fresh data
    final totalDebt = await getTotalDebtAllCards();
    final totalLimit = await getTotalLimitAllCards();
    final totalAvailableCredit = await getTotalAvailableCreditAllCards();
    final utilizationPercentage = await getOverallUtilizationPercentage();
    final debtDistribution = await getDebtDistributionByCard();
    final limitUtilization = await getLimitUtilizationByCard();
    final upcomingPayments = await getUpcomingPayments(30);

    final summary = {
      'totalDebt': totalDebt,
      'totalLimit': totalLimit,
      'totalAvailableCredit': totalAvailableCredit,
      'utilizationPercentage': utilizationPercentage,
      'debtDistribution': debtDistribution,
      'limitUtilization': limitUtilization,
      'upcomingPayments': upcomingPayments,
    };

    // Cache the result
    _cache.set(CacheKeys.dashboardSummary, summary);

    return summary;
  }

  /// Clear dashboard cache (call after data changes)
  void clearCache() {
    CacheKeys.clearDashboardCache();
  }

  /// Get total debt across all cards
  /// Uses caching to improve performance
  Future<double> getTotalDebtAllCards({bool forceRefresh = false}) async {
    // Check cache first
    if (!forceRefresh) {
      final cached = _cache.get<double>(CacheKeys.totalDebt);
      if (cached != null) {
        return cached;
      }
    }

    final cards = await _cardRepo.findActive();
    double totalDebt = 0;

    for (var card in cards) {
      final debt = await _cardService.getCurrentDebt(card.id);
      totalDebt += debt;
    }

    // Cache the result
    _cache.set(CacheKeys.totalDebt, totalDebt);

    return totalDebt;
  }

  /// Get total credit limit across all cards
  Future<double> getTotalLimitAllCards() async {
    final cards = await _cardRepo.findActive();
    return cards.fold<double>(0, (sum, card) => sum + card.creditLimit);
  }

  /// Get total available credit across all cards
  Future<double> getTotalAvailableCreditAllCards() async {
    final totalLimit = await getTotalLimitAllCards();
    final totalDebt = await getTotalDebtAllCards();
    return totalLimit - totalDebt;
  }

  /// Get overall credit utilization percentage across all cards
  Future<double> getOverallUtilizationPercentage() async {
    final totalLimit = await getTotalLimitAllCards();
    if (totalLimit <= 0) {
      return 0;
    }

    final totalDebt = await getTotalDebtAllCards();
    return (totalDebt / totalLimit) * 100;
  }

  /// Get debt distribution by card (for pie chart)
  Future<Map<String, double>> getDebtDistributionByCard() async {
    final cards = await _cardRepo.findActive();
    final distribution = <String, double>{};

    for (var card in cards) {
      final debt = await _cardService.getCurrentDebt(card.id);
      if (debt > 0) {
        distribution[card.cardName] = debt;
      }
    }

    return distribution;
  }

  /// Get limit utilization by card (for comparison chart)
  Future<Map<String, double>> getLimitUtilizationByCard() async {
    final cards = await _cardRepo.findActive();
    final utilization = <String, double>{};

    for (var card in cards) {
      final utilizationPercent = await _cardService.getCreditUtilization(card.id);
      utilization[card.cardName] = utilizationPercent;
    }

    return utilization;
  }

  /// Get upcoming payments within specified days
  Future<List<Map<String, dynamic>>> getUpcomingPayments(int days) async {
    final cards = await _cardRepo.findActive();
    final upcomingPayments = <Map<String, dynamic>>[];
    final now = DateTime.now();
    final endDate = now.add(Duration(days: days));

    for (var card in cards) {
      final statements = await _statementRepo.findByCardId(card.id);

      // Find unpaid statements with due date within the specified period
      final upcomingStatements = statements.where(
        (s) =>
            !s.isPaidFully &&
            s.dueDate.isAfter(now.subtract(const Duration(seconds: 1))) &&
            s.dueDate.isBefore(endDate.add(const Duration(days: 1))),
      );

      for (var statement in upcomingStatements) {
        upcomingPayments.add({
          'cardId': card.id,
          'cardName': card.cardName,
          'statementId': statement.id,
          'dueDate': statement.dueDate,
          'minimumPayment': statement.minimumPayment,
          'totalAmount': statement.remainingDebt,
          'daysUntilDue': statement.dueDate.difference(now).inDays,
        });
      }
    }

    // Sort by due date
    upcomingPayments.sort(
      (a, b) => (a['dueDate'] as DateTime).compareTo(b['dueDate'] as DateTime),
    );

    return upcomingPayments;
  }

  /// Get total amount due in the next week
  Future<double> getTotalDueNextWeek() async {
    final upcomingPayments = await getUpcomingPayments(7);
    return upcomingPayments.fold<double>(
      0,
      (sum, payment) => sum + (payment['minimumPayment'] as double),
    );
  }

  /// Get total amount due in the next month
  Future<double> getTotalDueNextMonth() async {
    final upcomingPayments = await getUpcomingPayments(30);
    return upcomingPayments.fold<double>(
      0,
      (sum, payment) => sum + (payment['minimumPayment'] as double),
    );
  }
}
