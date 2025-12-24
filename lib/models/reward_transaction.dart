import 'package:hive/hive.dart';

part 'reward_transaction.g.dart';

@HiveType(typeId: 21)
class RewardTransaction extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String cardId;

  @HiveField(2)
  String? transactionId;

  @HiveField(3)
  double pointsEarned;

  @HiveField(4)
  double pointsSpent;

  @HiveField(5)
  String description;

  @HiveField(6)
  DateTime transactionDate;

  @HiveField(7)
  DateTime createdAt;

  RewardTransaction({
    required this.id,
    required this.cardId,
    this.transactionId,
    required this.pointsEarned,
    required this.pointsSpent,
    required this.description,
    required this.transactionDate,
    required this.createdAt,
  });
  double get netPoints => pointsEarned - pointsSpent;

  bool get isEarning => pointsEarned > 0;

  bool get isSpending => pointsSpent > 0;
  String? validate() {
    if (cardId.trim().isEmpty) {
      return 'Kart ID boş olamaz';
    }
    if (pointsEarned < 0) {
      return 'Kazanılan puan negatif olamaz';
    }
    if (pointsSpent < 0) {
      return 'Harcanan puan negatif olamaz';
    }
    if (pointsEarned == 0 && pointsSpent == 0) {
      return 'Kazanılan veya harcanan puan sıfırdan büyük olmalı';
    }
    if (description.trim().isEmpty) {
      return 'Açıklama boş olamaz';
    }
    return null;
  }

  RewardTransaction copyWith({
    String? id,
    String? cardId,
    String? transactionId,
    double? pointsEarned,
    double? pointsSpent,
    String? description,
    DateTime? transactionDate,
    DateTime? createdAt,
  }) {
    return RewardTransaction(
      id: id ?? this.id,
      cardId: cardId ?? this.cardId,
      transactionId: transactionId ?? this.transactionId,
      pointsEarned: pointsEarned ?? this.pointsEarned,
      pointsSpent: pointsSpent ?? this.pointsSpent,
      description: description ?? this.description,
      transactionDate: transactionDate ?? this.transactionDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RewardTransaction && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
