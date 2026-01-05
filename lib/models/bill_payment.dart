import 'package:json_annotation/json_annotation.dart';

part 'bill_payment.g.dart';
enum BillPaymentStatus {
  pending,
  paid,
  overdue,
}
@JsonSerializable()
class BillPayment {
  final String id;
  final String templateId;
  final double amount;
  final DateTime dueDate;
  final DateTime periodStart;
  final DateTime periodEnd;
  final BillPaymentStatus status;
  final DateTime? paidDate;
  final String? paidWithWalletId;
  final String? transactionId;
  final String? notes;
  final DateTime createdDate;
  final DateTime updatedDate;

  const BillPayment({
    required this.id,
    required this.templateId,
    required this.amount,
    required this.dueDate,
    required this.periodStart,
    required this.periodEnd,
    required this.status,
    this.paidDate,
    this.paidWithWalletId,
    this.transactionId,
    this.notes,
    required this.createdDate,
    required this.updatedDate,
  });

  factory BillPayment.fromJson(Map<String, dynamic> json) =>
      _$BillPaymentFromJson(json);
  Map<String, dynamic> toJson() => _$BillPaymentToJson(this);

  BillPayment copyWith({
    String? id,
    String? templateId,
    double? amount,
    DateTime? dueDate,
    DateTime? periodStart,
    DateTime? periodEnd,
    BillPaymentStatus? status,
    DateTime? paidDate,
    String? paidWithWalletId,
    String? transactionId,
    String? notes,
    DateTime? createdDate,
    DateTime? updatedDate,
  }) {
    return BillPayment(
      id: id ?? this.id,
      templateId: templateId ?? this.templateId,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      periodStart: periodStart ?? this.periodStart,
      periodEnd: periodEnd ?? this.periodEnd,
      status: status ?? this.status,
      paidDate: paidDate ?? this.paidDate,
      paidWithWalletId: paidWithWalletId ?? this.paidWithWalletId,
      transactionId: transactionId ?? this.transactionId,
      notes: notes ?? this.notes,
      createdDate: createdDate ?? this.createdDate,
      updatedDate: updatedDate ?? this.updatedDate,
    );
  }

  bool get isPaid => status == BillPaymentStatus.paid;
  bool get isOverdue {
    if (status == BillPaymentStatus.paid) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return today.isAfter(due);
  }
  bool get isPending => status == BillPaymentStatus.pending && !isOverdue;

  int get daysUntilDue => dueDate.difference(DateTime.now()).inDays;

  String get statusDisplayName {
    switch (status) {
      case BillPaymentStatus.pending:
        return isOverdue ? 'Vadesi Geçti' : 'Bekliyor';
      case BillPaymentStatus.paid:
        return 'Ödendi';
      case BillPaymentStatus.overdue:
        return 'Vadesi Geçti';
    }
  }

  String get periodDisplayName {
    final months = [
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık',
    ];
    return '${months[periodStart.month - 1]} ${periodStart.year}';
  }
}
