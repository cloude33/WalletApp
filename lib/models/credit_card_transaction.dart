import 'package:hive/hive.dart';

part 'credit_card_transaction.g.dart';

@HiveType(typeId: 11)
class CreditCardTransaction extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String cardId;

  @HiveField(2)
  double amount;

  @HiveField(3)
  String description;

  @HiveField(4)
  DateTime transactionDate;

  @HiveField(5)
  String category;

  @HiveField(6)
  int installmentCount; // 1 = peşin, 2+ = taksitli

  @HiveField(7)
  int installmentsPaid; // Kaç taksit ödendi

  @HiveField(8)
  DateTime createdAt;

  CreditCardTransaction({
    required this.id,
    required this.cardId,
    required this.amount,
    required this.description,
    required this.transactionDate,
    required this.category,
    required this.installmentCount,
    this.installmentsPaid = 0,
    required this.createdAt,
  });

  // Computed properties
  double get installmentAmount => amount / installmentCount;
  
  double get remainingAmount => 
      installmentAmount * (installmentCount - installmentsPaid);
  
  bool get isCompleted => installmentsPaid >= installmentCount;
  
  int get remainingInstallments => installmentCount - installmentsPaid;
  
  bool get isCashPurchase => installmentCount == 1;

  // Validation
  String? validate() {
    if (cardId.trim().isEmpty) {
      return 'Kart ID boş olamaz';
    }
    if (amount <= 0) {
      return 'Tutar sıfırdan büyük olmalı';
    }
    if (description.trim().isEmpty) {
      return 'Açıklama boş olamaz';
    }
    if (category.trim().isEmpty) {
      return 'Kategori boş olamaz';
    }
    if (installmentCount < 1 || installmentCount > 36) {
      return 'Taksit sayısı 1-36 arasında olmalı';
    }
    if (installmentsPaid < 0) {
      return 'Ödenen taksit sayısı negatif olamaz';
    }
    if (installmentsPaid > installmentCount) {
      return 'Ödenen taksit sayısı toplam taksit sayısından fazla olamaz';
    }
    return null;
  }

  CreditCardTransaction copyWith({
    String? id,
    String? cardId,
    double? amount,
    String? description,
    DateTime? transactionDate,
    String? category,
    int? installmentCount,
    int? installmentsPaid,
    DateTime? createdAt,
  }) {
    return CreditCardTransaction(
      id: id ?? this.id,
      cardId: cardId ?? this.cardId,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      transactionDate: transactionDate ?? this.transactionDate,
      category: category ?? this.category,
      installmentCount: installmentCount ?? this.installmentCount,
      installmentsPaid: installmentsPaid ?? this.installmentsPaid,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CreditCardTransaction && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
