import 'package:hive/hive.dart';

part 'credit_card_statement.g.dart';

@HiveType(typeId: 12)
class CreditCardStatement extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String cardId;

  @HiveField(2)
  DateTime periodStart;

  @HiveField(3)
  DateTime periodEnd; // Ekstre kesim tarihi

  @HiveField(4)
  DateTime dueDate; // Son ödeme tarihi

  @HiveField(5)
  double previousBalance; // Önceki aydan devreden

  @HiveField(6)
  double interestCharged; // Uygulanan faiz

  @HiveField(7)
  double newPurchases; // Bu dönemdeki yeni harcamalar

  @HiveField(8)
  double installmentPayments; // Bu dönemdeki taksit ödemeleri

  @HiveField(9)
  double totalDebt; // Toplam borç

  @HiveField(10)
  double minimumPayment; // Asgari ödeme tutarı

  @HiveField(11)
  double paidAmount; // Ödenen tutar

  @HiveField(12)
  double remainingDebt; // Kalan borç

  @HiveField(13)
  DateTime? paymentDate;

  @HiveField(14)
  String status; // 'pending', 'partial', 'paid', 'overdue'

  @HiveField(15)
  DateTime createdAt;

  CreditCardStatement({
    required this.id,
    required this.cardId,
    required this.periodStart,
    required this.periodEnd,
    required this.dueDate,
    this.previousBalance = 0,
    this.interestCharged = 0,
    this.newPurchases = 0,
    this.installmentPayments = 0,
    required this.totalDebt,
    required this.minimumPayment,
    this.paidAmount = 0,
    required this.remainingDebt,
    this.paymentDate,
    this.status = 'pending',
    required this.createdAt,
  });

  // Computed properties
  bool get isPaidFully => remainingDebt <= 0.01; // Small tolerance for floating point
  
  bool get isOverdue => 
      DateTime.now().isAfter(dueDate) && !isPaidFully;
  
  bool get isPartiallyPaid => paidAmount > 0 && !isPaidFully;
  
  int get daysUntilDue => dueDate.difference(DateTime.now()).inDays;
  
  int get daysOverdue => 
      isOverdue ? DateTime.now().difference(dueDate).inDays : 0;

  String get statusText {
    switch (status) {
      case 'paid':
        return 'Ödendi';
      case 'partial':
        return 'Kısmi Ödendi';
      case 'overdue':
        return 'Gecikmiş';
      case 'pending':
      default:
        return 'Bekliyor';
    }
  }

  // Validation
  String? validate() {
    if (cardId.trim().isEmpty) {
      return 'Kart ID boş olamaz';
    }
    if (periodEnd.isBefore(periodStart)) {
      return 'Ekstre bitiş tarihi başlangıç tarihinden önce olamaz';
    }
    if (dueDate.isBefore(periodEnd)) {
      return 'Son ödeme tarihi ekstre kesim tarihinden önce olamaz';
    }
    if (previousBalance < 0) {
      return 'Önceki bakiye negatif olamaz';
    }
    if (interestCharged < 0) {
      return 'Faiz negatif olamaz';
    }
    if (newPurchases < 0) {
      return 'Yeni harcamalar negatif olamaz';
    }
    if (installmentPayments < 0) {
      return 'Taksit ödemeleri negatif olamaz';
    }
    if (totalDebt < 0) {
      return 'Toplam borç negatif olamaz';
    }
    if (minimumPayment < 0) {
      return 'Asgari ödeme negatif olamaz';
    }
    if (paidAmount < 0) {
      return 'Ödenen tutar negatif olamaz';
    }
    if (remainingDebt < 0) {
      return 'Kalan borç negatif olamaz';
    }
    return null;
  }

  CreditCardStatement copyWith({
    String? id,
    String? cardId,
    DateTime? periodStart,
    DateTime? periodEnd,
    DateTime? dueDate,
    double? previousBalance,
    double? interestCharged,
    double? newPurchases,
    double? installmentPayments,
    double? totalDebt,
    double? minimumPayment,
    double? paidAmount,
    double? remainingDebt,
    DateTime? paymentDate,
    String? status,
    DateTime? createdAt,
  }) {
    return CreditCardStatement(
      id: id ?? this.id,
      cardId: cardId ?? this.cardId,
      periodStart: periodStart ?? this.periodStart,
      periodEnd: periodEnd ?? this.periodEnd,
      dueDate: dueDate ?? this.dueDate,
      previousBalance: previousBalance ?? this.previousBalance,
      interestCharged: interestCharged ?? this.interestCharged,
      newPurchases: newPurchases ?? this.newPurchases,
      installmentPayments: installmentPayments ?? this.installmentPayments,
      totalDebt: totalDebt ?? this.totalDebt,
      minimumPayment: minimumPayment ?? this.minimumPayment,
      paidAmount: paidAmount ?? this.paidAmount,
      remainingDebt: remainingDebt ?? this.remainingDebt,
      paymentDate: paymentDate ?? this.paymentDate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CreditCardStatement && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
