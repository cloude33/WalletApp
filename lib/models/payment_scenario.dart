class PaymentScenario {
  final String name;
  final double monthlyPayment;
  final int durationMonths;
  final double totalInterest;
  final double totalPayment;
  final bool isRecommended;
  final String? warning;

  PaymentScenario({
    required this.name,
    required this.monthlyPayment,
    required this.durationMonths,
    required this.totalInterest,
    required this.totalPayment,
    this.isRecommended = false,
    this.warning,
  });
  double monthlySavingsComparedTo(PaymentScenario other) {
    return other.monthlyPayment - monthlyPayment;
  }
  double totalSavingsComparedTo(PaymentScenario other) {
    return other.totalPayment - totalPayment;
  }

  @override
  String toString() {
    return 'PaymentScenario(name: $name, monthlyPayment: $monthlyPayment, '
        'duration: $durationMonths months, totalInterest: $totalInterest, '
        'totalPayment: $totalPayment)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PaymentScenario &&
        other.name == name &&
        other.monthlyPayment == monthlyPayment &&
        other.durationMonths == durationMonths &&
        other.totalInterest == totalInterest &&
        other.totalPayment == totalPayment &&
        other.isRecommended == isRecommended &&
        other.warning == warning;
  }

  @override
  int get hashCode => Object.hash(
        name,
        monthlyPayment,
        durationMonths,
        totalInterest,
        totalPayment,
        isRecommended,
        warning,
      );
}
