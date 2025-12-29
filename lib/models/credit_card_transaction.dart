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
  int installmentCount;

  @HiveField(7)
  int installmentsPaid;

  @HiveField(8)
  DateTime createdAt;

  @HiveField(9)
  List<String> images;

  @HiveField(10)
  int? deferredMonths;

  @HiveField(11)
  DateTime? installmentStartDate;

  @HiveField(12)
  bool isCashAdvance;

  @HiveField(13)
  double? pointsEarned;

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
    List<String>? images,
    this.deferredMonths,
    this.installmentStartDate,
    this.isCashAdvance = false,
    this.pointsEarned,
  }) : images = images ?? [];
  double get installmentAmount => amount / installmentCount;

  double get remainingAmount =>
      installmentAmount * (installmentCount - installmentsPaid);

  bool get isCompleted => installmentsPaid >= installmentCount;

  int get remainingInstallments => installmentCount - installmentsPaid;

  bool get isCashPurchase => installmentCount == 1;

  bool get isDeferred => deferredMonths != null && deferredMonths! > 0;

  DateTime get effectiveStartDate => installmentStartDate ?? transactionDate;
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
    List<String>? images,
    int? deferredMonths,
    DateTime? installmentStartDate,
    bool? isCashAdvance,
    double? pointsEarned,
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
      images: images ?? this.images,
      deferredMonths: deferredMonths ?? this.deferredMonths,
      installmentStartDate: installmentStartDate ?? this.installmentStartDate,
      isCashAdvance: isCashAdvance ?? this.isCashAdvance,
      pointsEarned: pointsEarned ?? this.pointsEarned,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cardId': cardId,
      'amount': amount,
      'description': description,
      'transactionDate': transactionDate.toIso8601String(),
      'category': category,
      'installmentCount': installmentCount,
      'installmentsPaid': installmentsPaid,
      'createdAt': createdAt.toIso8601String(),
      'images': images,
      'deferredMonths': deferredMonths,
      'installmentStartDate': installmentStartDate?.toIso8601String(),
      'isCashAdvance': isCashAdvance,
      'pointsEarned': pointsEarned,
    };
  }

  factory CreditCardTransaction.fromJson(Map<String, dynamic> json) {
    return CreditCardTransaction(
      id: json['id'] as String,
      cardId: json['cardId'] as String,
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] as String,
      transactionDate: DateTime.parse(json['transactionDate'] as String),
      category: json['category'] as String,
      installmentCount: json['installmentCount'] as int,
      installmentsPaid: json['installmentsPaid'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      images: (json['images'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      deferredMonths: json['deferredMonths'] as int?,
      installmentStartDate: json['installmentStartDate'] != null
          ? DateTime.parse(json['installmentStartDate'] as String)
          : null,
      isCashAdvance: json['isCashAdvance'] as bool? ?? false,
      pointsEarned: (json['pointsEarned'] as num?)?.toDouble(),
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
