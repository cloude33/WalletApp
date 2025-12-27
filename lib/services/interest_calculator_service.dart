import '../repositories/credit_card_statement_repository.dart';

class InterestCalculatorService {
  final CreditCardStatementRepository _statementRepo =
      CreditCardStatementRepository();
  double calculateMonthlyInterest(double principal, double monthlyRate) {
    if (principal <= 0 || monthlyRate < 0) {
      return 0;
    }
    return principal * (monthlyRate / 100);
  }
  double calculateDailyInterest(
    double principal,
    double monthlyRate,
    int days,
  ) {
    if (principal <= 0 || monthlyRate < 0 || days <= 0) {
      return 0;
    }

    final dailyRate = monthlyRate / 30;
    return principal * (dailyRate / 100) * days;
  }
  double calculateLateInterest(
    double principal,
    double lateRate,
    int daysLate,
  ) {
    if (principal <= 0 || lateRate < 0 || daysLate <= 0) {
      return 0;
    }

    return calculateDailyInterest(principal, lateRate, daysLate);
  }
  double calculateCarryOverInterest({
    required double previousBalance,
    required double monthlyRate,
    required bool isOverdue,
    required int daysOverdue,
    double? lateRate,
  }) {
    if (previousBalance <= 0) {
      return 0;
    }
    if (isOverdue && daysOverdue > 0 && lateRate != null) {
      return calculateLateInterest(previousBalance, lateRate, daysOverdue);
    }
    return calculateMonthlyInterest(previousBalance, monthlyRate);
  }
  double calculateCompoundInterest({
    required double principal,
    required double monthlyRate,
    required int months,
  }) {
    if (principal <= 0 || monthlyRate < 0 || months <= 0) {
      return 0;
    }
    final rate = monthlyRate / 100;
    final compoundAmount = principal * pow(1 + rate, months);
    return compoundAmount - principal;
  }
  double calculateAPR(double monthlyRate) {
    if (monthlyRate < 0) {
      return 0;
    }
    final rate = monthlyRate / 100;
    return (pow(1 + rate, 12) - 1) * 100;
  }
  Future<double> getTotalInterestPaid(String cardId) async {
    final statements = await _statementRepo.findByCardId(cardId);
    return statements.fold<double>(0, (sum, s) => sum + s.interestCharged);
  }
  Future<double> getTotalInterestPaidAllCards() async {
    final allStatements = await _statementRepo.findAll();
    return allStatements.fold<double>(0, (sum, s) => sum + s.interestCharged);
  }
  Future<Map<String, double>> getMonthlyInterestBreakdown(
    String cardId,
    int months,
  ) async {
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month - months, 1);

    final statements = await _statementRepo.findByDateRange(
      cardId,
      startDate,
      now,
    );

    final breakdown = <String, double>{};

    for (var statement in statements) {
      final monthKey =
          '${statement.periodEnd.year}-${statement.periodEnd.month.toString().padLeft(2, '0')}';
      breakdown[monthKey] = statement.interestCharged;
    }

    return breakdown;
  }
  Future<double> calculateProjectedInterest({
    required String cardId,
    required double currentDebt,
    required double monthlyRate,
    required double minimumPaymentRate,
    required int months,
  }) async {
    if (currentDebt <= 0 || months <= 0) {
      return 0;
    }

    double remainingDebt = currentDebt;
    double totalInterest = 0;

    for (int i = 0; i < months; i++) {
      if (remainingDebt <= 0) break;
      final monthlyInterest = calculateMonthlyInterest(
        remainingDebt,
        monthlyRate,
      );
      totalInterest += monthlyInterest;
      remainingDebt += monthlyInterest;
      final minimumPayment = remainingDebt * minimumPaymentRate;
      remainingDebt -= minimumPayment;
      if (remainingDebt < 0) remainingDebt = 0;
    }

    return totalInterest;
  }
  int calculateMonthsToPayoff({
    required double currentDebt,
    required double monthlyRate,
    required double monthlyPayment,
  }) {
    if (currentDebt <= 0 || monthlyPayment <= 0) {
      return 0;
    }
    final monthlyInterest = calculateMonthlyInterest(currentDebt, monthlyRate);
    if (monthlyPayment <= monthlyInterest) {
      return -1;
    }

    double remainingDebt = currentDebt;
    int months = 0;
    const maxMonths = 1200;

    while (remainingDebt > 0.01 && months < maxMonths) {
      final interest = calculateMonthlyInterest(remainingDebt, monthlyRate);
      remainingDebt += interest;
      remainingDebt -= monthlyPayment;

      months++;
    }

    return months >= maxMonths ? -1 : months;
  }
  double calculateTotalCost({
    required double principal,
    required double monthlyRate,
    required double monthlyPayment,
  }) {
    final months = calculateMonthsToPayoff(
      currentDebt: principal,
      monthlyRate: monthlyRate,
      monthlyPayment: monthlyPayment,
    );

    if (months <= 0) {
      return -1;
    }

    return monthlyPayment * months;
  }
  Future<Map<String, dynamic>> calculateInterestSavings({
    required String cardId,
    required double currentDebt,
    required double monthlyRate,
    required double minimumPaymentRate,
    required double proposedMonthlyPayment,
  }) async {
    final minimumPayment = currentDebt * minimumPaymentRate;
    final monthsWithMinimum = calculateMonthsToPayoff(
      currentDebt: currentDebt,
      monthlyRate: monthlyRate,
      monthlyPayment: minimumPayment,
    );
    final totalCostWithMinimum = calculateTotalCost(
      principal: currentDebt,
      monthlyRate: monthlyRate,
      monthlyPayment: minimumPayment,
    );
    final monthsWithProposed = calculateMonthsToPayoff(
      currentDebt: currentDebt,
      monthlyRate: monthlyRate,
      monthlyPayment: proposedMonthlyPayment,
    );
    final totalCostWithProposed = calculateTotalCost(
      principal: currentDebt,
      monthlyRate: monthlyRate,
      monthlyPayment: proposedMonthlyPayment,
    );
    final interestSavings = totalCostWithMinimum - totalCostWithProposed;
    final monthsSaved = monthsWithMinimum - monthsWithProposed;

    return {
      'minimumPayment': minimumPayment,
      'monthsWithMinimum': monthsWithMinimum,
      'totalCostWithMinimum': totalCostWithMinimum,
      'interestWithMinimum': totalCostWithMinimum - currentDebt,
      'proposedPayment': proposedMonthlyPayment,
      'monthsWithProposed': monthsWithProposed,
      'totalCostWithProposed': totalCostWithProposed,
      'interestWithProposed': totalCostWithProposed - currentDebt,
      'interestSavings': interestSavings,
      'monthsSaved': monthsSaved,
    };
  }
  List<Map<String, dynamic>> compareInterestRates({
    required double principal,
    required List<double> rates,
    required double monthlyPayment,
  }) {
    final comparisons = <Map<String, dynamic>>[];

    for (var rate in rates) {
      final months = calculateMonthsToPayoff(
        currentDebt: principal,
        monthlyRate: rate,
        monthlyPayment: monthlyPayment,
      );
      final totalCost = calculateTotalCost(
        principal: principal,
        monthlyRate: rate,
        monthlyPayment: monthlyPayment,
      );
      final totalInterest = totalCost > 0 ? totalCost - principal : -1;

      comparisons.add({
        'rate': rate,
        'months': months,
        'totalCost': totalCost,
        'totalInterest': totalInterest,
        'apr': calculateAPR(rate),
      });
    }

    return comparisons;
  }
}
double pow(double base, int exponent) {
  if (exponent == 0) return 1;
  if (exponent == 1) return base;

  double result = 1;
  for (int i = 0; i < exponent; i++) {
    result *= base;
  }
  return result;
}
