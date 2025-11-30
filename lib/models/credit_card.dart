import 'package:hive/hive.dart';
import 'package:flutter/material.dart';

part 'credit_card.g.dart';

@HiveType(typeId: 10)
class CreditCard extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String bankName;

  @HiveField(2)
  String cardName; // Bonus, Axess, World, Maximum, etc.

  @HiveField(3)
  String last4Digits;

  @HiveField(4)
  double creditLimit;

  @HiveField(5)
  int statementDay; // 1-31 arası, her ayın kaçında ekstre kesilir

  @HiveField(6)
  int dueDateOffset; // Ekstre kesiminden kaç gün sonra son ödeme

  @HiveField(7)
  double monthlyInterestRate; // Aylık faiz oranı (örn: 3.5)

  @HiveField(8)
  double lateInterestRate; // Gecikme faizi oranı (örn: 4.5)

  @HiveField(9)
  int cardColor; // Color.value

  @HiveField(10)
  DateTime createdAt;

  @HiveField(11)
  bool isActive;

  CreditCard({
    required this.id,
    required this.bankName,
    required this.cardName,
    required this.last4Digits,
    required this.creditLimit,
    required this.statementDay,
    required this.dueDateOffset,
    required this.monthlyInterestRate,
    required this.lateInterestRate,
    required this.cardColor,
    required this.createdAt,
    this.isActive = true,
  });

  // Computed properties
  Color get color => Color(cardColor);

  // Validation
  String? validate() {
    if (bankName.trim().isEmpty) {
      return 'Banka adı boş olamaz';
    }
    if (cardName.trim().isEmpty) {
      return 'Kart adı boş olamaz';
    }
    if (last4Digits.length != 4) {
      return 'Son 4 hane geçersiz';
    }
    if (creditLimit <= 0) {
      return 'Kredi limiti sıfırdan büyük olmalı';
    }
    if (statementDay < 1 || statementDay > 31) {
      return 'Ekstre kesim günü 1-31 arasında olmalı';
    }
    if (dueDateOffset < 0) {
      return 'Son ödeme günü offset negatif olamaz';
    }
    if (monthlyInterestRate < 0) {
      return 'Faiz oranı negatif olamaz';
    }
    if (lateInterestRate < 0) {
      return 'Gecikme faizi oranı negatif olamaz';
    }
    return null;
  }

  CreditCard copyWith({
    String? id,
    String? bankName,
    String? cardName,
    String? last4Digits,
    double? creditLimit,
    int? statementDay,
    int? dueDateOffset,
    double? monthlyInterestRate,
    double? lateInterestRate,
    int? cardColor,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return CreditCard(
      id: id ?? this.id,
      bankName: bankName ?? this.bankName,
      cardName: cardName ?? this.cardName,
      last4Digits: last4Digits ?? this.last4Digits,
      creditLimit: creditLimit ?? this.creditLimit,
      statementDay: statementDay ?? this.statementDay,
      dueDateOffset: dueDateOffset ?? this.dueDateOffset,
      monthlyInterestRate: monthlyInterestRate ?? this.monthlyInterestRate,
      lateInterestRate: lateInterestRate ?? this.lateInterestRate,
      cardColor: cardColor ?? this.cardColor,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CreditCard && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
