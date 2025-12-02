import 'package:json_annotation/json_annotation.dart';

part 'bill_payment.g.dart';

/// Fatura ödeme durumu
enum BillPaymentStatus {
  pending, // Bekliyor
  paid, // Ödendi
  overdue, // Vadesi geçti
}

/// Fatura ödemesi - Her ay için eklenir
@JsonSerializable()
class BillPayment {
  final String id;
  final String templateId; // Hangi şablon için
  final double amount; // Fatura tutarı
  final DateTime dueDate; // Son ödeme tarihi
  final DateTime periodStart; // Fatura dönemi başlangıcı (örn: 1 Aralık 2025)
  final DateTime periodEnd; // Fatura dönemi bitişi (örn: 31 Aralık 2025)
  final BillPaymentStatus status;
  final DateTime? paidDate; // Ödeme tarihi
  final String? paidWithWalletId; // Hangi cüzdan/kartla ödendi
  final String? transactionId; // İlişkili transaction ID
  final String? notes; // Notlar
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
  bool get isOverdue =>
      status != BillPaymentStatus.paid && DateTime.now().isAfter(dueDate);
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
      'Aralık'
    ];
    return '${months[periodStart.month - 1]} ${periodStart.year}';
  }
}
