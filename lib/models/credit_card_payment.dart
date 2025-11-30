import 'package:hive/hive.dart';

part 'credit_card_payment.g.dart';

@HiveType(typeId: 13)
class CreditCardPayment extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String cardId;

  @HiveField(2)
  String statementId;

  @HiveField(3)
  double amount;

  @HiveField(4)
  DateTime paymentDate;

  @HiveField(5)
  String paymentMethod; // 'bank_transfer', 'atm', 'auto_payment', 'other'

  @HiveField(6)
  String note;

  @HiveField(7)
  DateTime createdAt;

  CreditCardPayment({
    required this.id,
    required this.cardId,
    required this.statementId,
    required this.amount,
    required this.paymentDate,
    this.paymentMethod = 'other',
    this.note = '',
    required this.createdAt,
  });

  String get paymentMethodText {
    switch (paymentMethod) {
      case 'bank_transfer':
        return 'Banka Havalesi';
      case 'atm':
        return 'ATM';
      case 'auto_payment':
        return 'Otomatik Ödeme';
      case 'other':
      default:
        return 'Diğer';
    }
  }

  // Validation
  String? validate() {
    if (cardId.trim().isEmpty) {
      return 'Kart ID boş olamaz';
    }
    if (statementId.trim().isEmpty) {
      return 'Ekstre ID boş olamaz';
    }
    if (amount <= 0) {
      return 'Ödeme tutarı sıfırdan büyük olmalı';
    }
    if (paymentMethod.trim().isEmpty) {
      return 'Ödeme yöntemi boş olamaz';
    }
    return null;
  }

  CreditCardPayment copyWith({
    String? id,
    String? cardId,
    String? statementId,
    double? amount,
    DateTime? paymentDate,
    String? paymentMethod,
    String? note,
    DateTime? createdAt,
  }) {
    return CreditCardPayment(
      id: id ?? this.id,
      cardId: cardId ?? this.cardId,
      statementId: statementId ?? this.statementId,
      amount: amount ?? this.amount,
      paymentDate: paymentDate ?? this.paymentDate,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CreditCardPayment && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
