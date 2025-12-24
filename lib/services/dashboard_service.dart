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
  Future<Map<String, dynamic>> getDashboardSummary({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = _cache.get<Map<String, dynamic>>(
        CacheKeys.dashboardSummary,
      );
      if (cached != null) {
        return cached;
      }
    }
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
    _cache.set(CacheKeys.dashboardSummary, summary);

    return summary;
  }
  void clearCache() {
    CacheKeys.clearDashboardCache();
  }
  Future<double> getTotalDebtAllCards({bool forceRefresh = false}) async {
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
    _cache.set(CacheKeys.totalDebt, totalDebt);

    return totalDebt;
  }
  Future<double> getTotalLimitAllCards() async {
    final cards = await _cardRepo.findActive();
    return cards.fold<double>(0, (sum, card) => sum + card.creditLimit);
  }
  Future<double> getTotalAvailableCreditAllCards() async {
    final totalLimit = await getTotalLimitAllCards();
    final totalDebt = await getTotalDebtAllCards();
    return totalLimit - totalDebt;
  }
  Future<double> getOverallUtilizationPercentage() async {
    final totalLimit = await getTotalLimitAllCards();
    if (totalLimit <= 0) {
      return 0;
    }

    final totalDebt = await getTotalDebtAllCards();
    return (totalDebt / totalLimit) * 100;
  }
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
  Future<Map<String, double>> getLimitUtilizationByCard() async {
    final cards = await _cardRepo.findActive();
    final utilization = <String, double>{};

    for (var card in cards) {
      final utilizationPercent = await _cardService.getCreditUtilization(card.id);
      utilization[card.cardName] = utilizationPercent;
    }

    return utilization;
  }
  Future<List<Map<String, dynamic>>> getUpcomingPayments(int days) async {
    final cards = await _cardRepo.findActive();
    final upcomingPayments = <Map<String, dynamic>>[];
    final now = DateTime.now();
    final endDate = now.add(Duration(days: days));

    for (var card in cards) {
      final statements = await _statementRepo.findByCardId(card.id);
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
    upcomingPayments.sort(
      (a, b) => (a['dueDate'] as DateTime).compareTo(b['dueDate'] as DateTime),
    );

    return upcomingPayments;
  }
  Future<double> getTotalDueNextWeek() async {
    final upcomingPayments = await getUpcomingPayments(7);
    return upcomingPayments.fold<double>(
      0,
      (sum, payment) => sum + (payment['minimumPayment'] as double),
    );
  }
  Future<double> getTotalDueNextMonth() async {
    final upcomingPayments = await getUpcomingPayments(30);
    return upcomingPayments.fold<double>(
      0,
      (sum, payment) => sum + (payment['minimumPayment'] as double),
    );
  }
}
