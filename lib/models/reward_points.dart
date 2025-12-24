import 'package:hive/hive.dart';

part 'reward_points.g.dart';

@HiveType(typeId: 20)
class RewardPoints extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String cardId;

  @HiveField(2)
  String rewardType;

  @HiveField(3)
  double pointsBalance;

  @HiveField(4)
  double conversionRate;

  @HiveField(5)
  DateTime lastUpdated;

  @HiveField(6)
  DateTime createdAt;

  RewardPoints({
    required this.id,
    required this.cardId,
    required this.rewardType,
    required this.pointsBalance,
    required this.conversionRate,
    required this.lastUpdated,
    required this.createdAt,
  });
  double get valueInCurrency => pointsBalance * conversionRate;
  String? validate() {
    if (cardId.trim().isEmpty) {
      return 'Kart ID boş olamaz';
    }
    if (rewardType.trim().isEmpty) {
      return 'Puan türü boş olamaz';
    }
    final validTypes = ['bonus', 'worldpuan', 'miles', 'cashback'];
    if (!validTypes.contains(rewardType.toLowerCase())) {
      return 'Geçersiz puan türü';
    }
    if (pointsBalance < 0) {
      return 'Puan bakiyesi negatif olamaz';
    }
    if (conversionRate <= 0) {
      return 'Dönüşüm oranı sıfırdan büyük olmalı';
    }
    return null;
  }

  RewardPoints copyWith({
    String? id,
    String? cardId,
    String? rewardType,
    double? pointsBalance,
    double? conversionRate,
    DateTime? lastUpdated,
    DateTime? createdAt,
  }) {
    return RewardPoints(
      id: id ?? this.id,
      cardId: cardId ?? this.cardId,
      rewardType: rewardType ?? this.rewardType,
      pointsBalance: pointsBalance ?? this.pointsBalance,
      conversionRate: conversionRate ?? this.conversionRate,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RewardPoints && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
