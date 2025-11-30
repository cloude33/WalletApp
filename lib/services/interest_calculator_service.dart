import '../repositories/credit_card_statement_repository.dart';
import '../repositories/credit_card_payment_repository.dart';

class InterestCalculatorService {
  final CreditCardStatementRepository _statementRepo = CreditCardStatementRepository();
  final CreditCardPaymentRepository _paymentRepo = CreditCardPaymentRepository();

  // ==================== INTEREST CALCULATIONS ====================

  /// Calculate monthly interest
  /// Formula: principal * (monthlyRate / 100)
  double calculateMonthlyInterest(double principal, double monthlyRate) {
    if (principal <= 0 || monthlyRate < 0) {
      return 0;
    }
    return principal * (monthlyRate / 100);
  }

  /// Calculate daily interest
  /// Formula: principal * (monthlyRate / 100) / 30 * days
  /// Turkish banks typically use 30-day months for interest calculation
  double calculateDailyInterest(double principal, double monthlyRate, int days) {
    if (principal <= 0 || monthlyRate < 0 || days <= 0) {
      return 0;
    }
    
    final dailyRate = monthlyRate / 30;
    return principal * (dailyRate / 100) * days;
  }

  /// Calculate late interest (gecikme faizi)
  /// Applied when payment is overdue
  double calculateLateInterest(double principal, double lateRate, int daysLate) {
    if (principal <= 0 || lateRate < 0 || daysLate <= 0) {
      return 0;
    }
    
    return calculateDailyInterest(principal, lateRate, daysLate);
  }

  /// Calculate carry over interest (devreden borç faizi)
  /// This is the interest applied to unpaid balance from previous statement
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

    // If overdue, use late interest rate
    if (isOverdue && daysOverdue > 0 && lateRate != null) {
      return calculateLateInterest(previousBalance, lateRate, daysOverdue);
    }

    // Otherwise use normal monthly interest
    return calculateMonthlyInterest(previousBalance, monthlyRate);
  }

  /// Calculate compound interest for multiple periods
  /// Used when debt carries over multiple months
  double calculateCompoundInterest({
    required double principal,
    required double monthlyRate,
    required int months,
  }) {
    if (principal <= 0 || monthlyRate < 0 || months <= 0) {
      return 0;
    }

    // Compound interest formula: P * (1 + r)^n - P
    final rate = monthlyRate / 100;
    final compoundAmount = principal * pow(1 + rate, months);
    return compoundAmount - principal;
  }

  /// Calculate effective annual rate (APR)
  /// Converts monthly rate to annual percentage rate
  double calculateAPR(double monthlyRate) {
    if (monthlyRate < 0) {
      return 0;
    }
    
    // APR = (1 + monthly rate)^12 - 1
    final rate = monthlyRate / 100;
    return (pow(1 + rate, 12) - 1) * 100;
  }

  // ==================== INTEREST ANALYSIS ====================

  /// Get total interest paid for a card
  Future<double> getTotalInterestPaid(String cardId) async {
    final statements = await _statementRepo.findByCardId(cardId);
    return statements.fold<double>(0, (sum, s) => sum + s.interestCharged);
  }

  /// Get total interest paid across all cards
  Future<double> getTotalInterestPaidAllCards() async {
    final allStatements = await _statementRepo.findAll();
    return allStatements.fold<double>(0, (sum, s) => sum + s.interestCharged);
  }

  /// Get monthly interest breakdown for a card
  /// Returns map of month -> interest amount
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
      final monthKey = '${statement.periodEnd.year}-${statement.periodEnd.month.toString().padLeft(2, '0')}';
      breakdown[monthKey] = statement.interestCharged;
    }

    return breakdown;
  }

  /// Calculate projected interest for remaining debt
  /// Estimates how much interest will be paid if only minimum payments are made
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

      // Calculate interest for this month
      final monthlyInterest = calculateMonthlyInterest(remainingDebt, monthlyRate);
      totalInterest += monthlyInterest;

      // Add interest to debt
      remainingDebt += monthlyInterest;

      // Subtract minimum payment
      final minimumPayment = remainingDebt * minimumPaymentRate;
      remainingDebt -= minimumPayment;

      // Ensure debt doesn't go negative
      if (remainingDebt < 0) remainingDebt = 0;
    }

    return totalInterest;
  }

  /// Calculate months to pay off debt with given monthly payment
  int calculateMonthsToPayoff({
    required double currentDebt,
    required double monthlyRate,
    required double monthlyPayment,
  }) {
    if (currentDebt <= 0 || monthlyPayment <= 0) {
      return 0;
    }

    // If payment is less than monthly interest, debt will never be paid off
    final monthlyInterest = calculateMonthlyInterest(currentDebt, monthlyRate);
    if (monthlyPayment <= monthlyInterest) {
      return -1; // Indicates infinite months (debt grows)
    }

    double remainingDebt = currentDebt;
    int months = 0;
    const maxMonths = 1200; // 100 years safety limit

    while (remainingDebt > 0.01 && months < maxMonths) {
      // Add interest
      final interest = calculateMonthlyInterest(remainingDebt, monthlyRate);
      remainingDebt += interest;

      // Subtract payment
      remainingDebt -= monthlyPayment;

      months++;
    }

    return months >= maxMonths ? -1 : months;
  }

  /// Calculate total cost (principal + interest) for a payment plan
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
      return -1; // Indicates unpayable debt
    }

    return monthlyPayment * months;
  }

  /// Calculate interest savings by paying more than minimum
  Future<Map<String, dynamic>> calculateInterestSavings({
    required String cardId,
    required double currentDebt,
    required double monthlyRate,
    required double minimumPaymentRate,
    required double proposedMonthlyPayment,
  }) async {
    // Calculate with minimum payment
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

    // Calculate with proposed payment
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

    // Calculate savings
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

  /// Get interest rate comparison
  /// Compares different interest rates to show impact
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

// Helper function for power calculation
double pow(double base, int exponent) {
  if (exponent == 0) return 1;
  if (exponent == 1) return base;
  
  double result = 1;
  for (int i = 0; i < exponent; i++) {
    result *= base;
  }
  return result;
}
