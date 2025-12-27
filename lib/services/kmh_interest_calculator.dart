class KmhInterestCalculator {
  double calculateDailyInterest({
    required double balance,
    required double annualRate,
  }) {
    if (balance >= 0) return 0.0;
    final dailyRate = annualRate / 365 / 100;
    return balance.abs() * dailyRate;
  }
  double estimateMonthlyInterest({
    required double balance,
    required double annualRate,
    int days = 30,
  }) {
    if (balance >= 0) return 0.0;
    final dailyInterest = calculateDailyInterest(
      balance: balance,
      annualRate: annualRate,
    );
    return dailyInterest * days;
  }
  double estimateAnnualInterest({
    required double balance,
    required double annualRate,
  }) {
    if (balance >= 0) return 0.0;
    return balance.abs() * (annualRate / 100);
  }
  PayoffCalculation calculatePayoffTime({
    required double currentDebt,
    required double monthlyPayment,
    required double annualRate,
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
    final monthlyInterest = estimateMonthlyInterest(
      balance: -currentDebt,
      annualRate: annualRate,
      days: 30,
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
        annualRate: annualRate,
        days: 30,
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
