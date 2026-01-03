class KmhInterestCalculator {
  
  /// Calculates total daily cost including taxes (KKDF + BSMV)
  /// Formula: (Principal * MonthlyRate * Days) / 3000 * (1 + TaxRates)
  double calculateDailyInterest({
    required double balance,
    required double monthlyRate,
    double kkdfRate = 0.15, // Default/Fallback
    double bsmvRate = 0.15, // Default/Fallback
  }) {
    if (balance >= 0) return 0.0;
    
    // Gross Interest = (Balance * Rate) / 3000
    // 3000 comes from: Rate/100 (percentage) / 30 (days in month)
    final grossInterest = (balance.abs() * monthlyRate) / 3000;
    
    final tax = grossInterest * (kkdfRate + bsmvRate);
    return grossInterest + tax;
  }

  /// Estimates monthly interest cost including taxes
  double estimateMonthlyInterest({
    required double balance,
    required double monthlyRate,
    int days = 30,
    double kkdfRate = 0.15,
    double bsmvRate = 0.15,
  }) {
    if (balance >= 0) return 0.0;
    
    final grossInterest = (balance.abs() * monthlyRate * days) / 3000;
    final tax = grossInterest * (kkdfRate + bsmvRate);
    
    return grossInterest + tax;
  }

  /// Estimates annual interest cost including taxes
  double estimateAnnualInterest({
    required double balance,
    required double monthlyRate,
    double kkdfRate = 0.15,
    double bsmvRate = 0.15,
  }) {
    if (balance >= 0) return 0.0;
    return estimateMonthlyInterest(
      balance: balance,
      monthlyRate: monthlyRate,
      days: 365,
      kkdfRate: kkdfRate,
      bsmvRate: bsmvRate,
    );
  }

  PayoffCalculation calculatePayoffTime({
    required double currentDebt,
    required double monthlyPayment,
    required double monthlyRate,
    double kkdfRate = 0.15,
    double bsmvRate = 0.15,
  }) {
    if (currentDebt <= 0) {
      return PayoffCalculation(
        months: 0,
        totalInterest: 0.0,
        totalPaid: 0.0,
        isPossible: true,
      );
    }
    
    if (monthlyPayment <= 0) {
      return PayoffCalculation(
        months: -1,
        totalInterest: 0.0,
        totalPaid: 0.0,
        isPossible: false,
      );
    }

    // Check if payment covers at least the interest
    final monthlyInterest = estimateMonthlyInterest(
      balance: -currentDebt,
      monthlyRate: monthlyRate,
      days: 30,
      kkdfRate: kkdfRate,
      bsmvRate: bsmvRate,
    );

    if (monthlyPayment <= monthlyInterest) {
      return PayoffCalculation(
        months: -1,
        totalInterest: 0.0,
        totalPaid: 0.0,
        isPossible: false,
      );
    }

    double remainingDebt = currentDebt;
    double totalInterest = 0.0;
    int months = 0;
    const maxMonths = 1200;
    
    while (remainingDebt > 0.01 && months < maxMonths) {
      final interest = estimateMonthlyInterest(
        balance: -remainingDebt,
        monthlyRate: monthlyRate,
        days: 30,
        kkdfRate: kkdfRate,
        bsmvRate: bsmvRate,
      );

      remainingDebt += interest;
      totalInterest += interest;

      if (monthlyPayment >= remainingDebt) {
        remainingDebt = 0;
      } else {
        remainingDebt -= monthlyPayment;
      }
      
      months++;
    }

    if (months >= maxMonths) {
      return PayoffCalculation(
        months: -1,
        totalInterest: 0.0,
        totalPaid: 0.0,
        isPossible: false,
      );
    }
    
    final totalPaid = currentDebt + totalInterest;
    
    return PayoffCalculation(
      months: months,
      totalInterest: totalInterest,
      totalPaid: totalPaid,
      isPossible: true,
    );
  }
}
class PayoffCalculation {
  final int months;
  final double totalInterest;
  final double totalPaid;
  final bool isPossible;
  
  PayoffCalculation({
    required this.months,
    required this.totalInterest,
    required this.totalPaid,
    required this.isPossible,
  });
  
  @override
  String toString() {
    if (!isPossible) {
      return 'PayoffCalculation(isPossible: false, months: $months)';
    }
    return 'PayoffCalculation(months: $months, totalInterest: $totalInterest, totalPaid: $totalPaid)';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PayoffCalculation &&
        other.months == months &&
        other.totalInterest == totalInterest &&
        other.totalPaid == totalPaid &&
        other.isPossible == isPossible;
  }
  
  @override
  int get hashCode => Object.hash(months, totalInterest, totalPaid, isPossible);
}
