import 'package:json_annotation/json_annotation.dart';

part 'debt_payment.g.dart';

enum PaymentType {
  @JsonValue('partial')
  partial,
  
  @JsonValue('full')
  full,
  
  @JsonValue('adjustment')
  adjustment,
}

@JsonSerializable()
class DebtPayment {
  final String id;
  final String debtId;
  final double amount;
  final DateTime date;
  final PaymentType type;
  final String? note;
  final DateTime createdDate;
  final DateTime updatedDate;
  final bool isDeleted;

  const DebtPayment({
    required this.id,
    required this.debtId,
    required this.amount,
    required this.date,
    required this.type,
    this.note,
    required this.createdDate,
    required this.updatedDate,
    this.isDeleted = false,
  });

  factory DebtPayment.fromJson(Map<String, dynamic> json) => _$DebtPaymentFromJson(json);
  Map<String, dynamic> toJson() => _$DebtPaymentToJson(this);

  DebtPayment copyWith({
    String? id,
    String? debtId,
    double? amount,
    DateTime? date,
    PaymentType? type,
    String? note,
    DateTime? createdDate,
    DateTime? updatedDate,
    bool? isDeleted,
  }) {
    return DebtPayment(
      id: id ?? this.id,
      debtId: debtId ?? this.debtId,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      type: type ?? this.type,
      note: note ?? this.note,
      createdDate: createdDate ?? this.createdDate,
      updatedDate: updatedDate ?? this.updatedDate,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  String? validate() {
    if (amount == 0) {
      return 'Ödeme tutarı sıfır olamaz';
    }
    if (date.isAfter(DateTime.now().add(const Duration(days: 1)))) {
      return 'Ödeme tarihi gelecekte olamaz';
    }
    return null;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DebtPayment && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
