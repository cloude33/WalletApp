import 'package:hive/hive.dart';

part 'payment_plan.g.dart';
@HiveType(typeId: 31)
class PaymentPlan extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String walletId;

  @HiveField(2)
  double initialDebt;

  @HiveField(3)
  double monthlyPayment;

  @HiveField(4)
  double annualRate;

  @HiveField(5)
  int durationMonths;

  @HiveField(6)
  double totalInterest;

  @HiveField(7)
  double totalPayment;

  @HiveField(8)
  DateTime createdAt;

  @HiveField(9)
  bool isActive;

  @HiveField(10)
  String? reminderSchedule;

  PaymentPlan({
    required this.id,
    required this.walletId,
    required this.initialDebt,
    required this.monthlyPayment,
    required this.annualRate,
    required this.durationMonths,
    required this.totalInterest,
    required this.totalPayment,
    required this.createdAt,
    this.isActive = true,
    this.reminderSchedule,
  });

  PaymentPlan copyWith({
    String? id,
    String? walletId,
    double? initialDebt,
    double? monthlyPayment,
    double? annualRate,
    int? durationMonths,
    double? totalInterest,
    double? totalPayment,
    DateTime? createdAt,
    bool? isActive,
    String? reminderSchedule,
  }) {
    return PaymentPlan(
      id: id ?? this.id,
      walletId: walletId ?? this.walletId,
      initialDebt: initialDebt ?? this.initialDebt,
      monthlyPayment: monthlyPayment ?? this.monthlyPayment,
      annualRate: annualRate ?? this.annualRate,
      durationMonths: durationMonths ?? this.durationMonths,
      totalInterest: totalInterest ?? this.totalInterest,
      totalPayment: totalPayment ?? this.totalPayment,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      reminderSchedule: reminderSchedule ?? this.reminderSchedule,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PaymentPlan && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
