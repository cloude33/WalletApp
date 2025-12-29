import 'package:hive/hive.dart';

part 'payment_simulation.g.dart';

@HiveType(typeId: 23)
class PaymentSimulation extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String cardId;

  @HiveField(2)
  double currentDebt;

  @HiveField(3)
  double proposedPayment;

  @HiveField(4)
  double remainingDebt;

  @HiveField(5)
  double interestCharged;

  @HiveField(6)
  int monthsToPayoff;

  @HiveField(7)
  double totalCost;

  @HiveField(8)
  DateTime simulationDate;

  PaymentSimulation({
    required this.id,
    required this.cardId,
    required this.currentDebt,
    required this.proposedPayment,
    required this.remainingDebt,
    required this.interestCharged,
    required this.monthsToPayoff,
    required this.totalCost,
    required this.simulationDate,
  });
  String? validate() {
    if (cardId.trim().isEmpty) {
      return 'Kart ID boş olamaz';
    }
    if (currentDebt < 0) {
      return 'Mevcut borç negatif olamaz';
    }
    if (proposedPayment < 0) {
      return 'Önerilen ödeme negatif olamaz';
    }
    if (remainingDebt < 0) {
      return 'Kalan borç negatif olamaz';
    }
    if (interestCharged < 0) {
      return 'Faiz negatif olamaz';
    }
    if (monthsToPayoff < 0) {
      return 'Ödeme süresi negatif olamaz';
    }
    if (totalCost < 0) {
      return 'Toplam maliyet negatif olamaz';
    }
    return null;
  }

  PaymentSimulation copyWith({
    String? id,
    String? cardId,
    double? currentDebt,
    double? proposedPayment,
    double? remainingDebt,
    double? interestCharged,
    int? monthsToPayoff,
    double? totalCost,
    DateTime? simulationDate,
  }) {
    return PaymentSimulation(
      id: id ?? this.id,
      cardId: cardId ?? this.cardId,
      currentDebt: currentDebt ?? this.currentDebt,
      proposedPayment: proposedPayment ?? this.proposedPayment,
      remainingDebt: remainingDebt ?? this.remainingDebt,
      interestCharged: interestCharged ?? this.interestCharged,
      monthsToPayoff: monthsToPayoff ?? this.monthsToPayoff,
      totalCost: totalCost ?? this.totalCost,
      simulationDate: simulationDate ?? this.simulationDate,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PaymentSimulation && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
