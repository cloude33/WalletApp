import 'package:hive/hive.dart';

part 'limit_alert.g.dart';

@HiveType(typeId: 22)
class LimitAlert extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String cardId;

  @HiveField(2)
  double threshold;

  @HiveField(3)
  bool isTriggered;

  @HiveField(4)
  DateTime? triggeredAt;

  @HiveField(5)
  DateTime createdAt;

  LimitAlert({
    required this.id,
    required this.cardId,
    required this.threshold,
    required this.isTriggered,
    this.triggeredAt,
    required this.createdAt,
  });
  String? validate() {
    if (cardId.trim().isEmpty) {
      return 'Kart ID boş olamaz';
    }
    if (threshold <= 0 || threshold > 100) {
      return 'Eşik değeri 0-100 arasında olmalı';
    }
    if (isTriggered && triggeredAt == null) {
      return 'Tetiklenmiş uyarı için tetiklenme tarihi gerekli';
    }
    return null;
  }

  LimitAlert copyWith({
    String? id,
    String? cardId,
    double? threshold,
    bool? isTriggered,
    DateTime? Function()? triggeredAt,
    DateTime? createdAt,
  }) {
    return LimitAlert(
      id: id ?? this.id,
      cardId: cardId ?? this.cardId,
      threshold: threshold ?? this.threshold,
      isTriggered: isTriggered ?? this.isTriggered,
      triggeredAt: triggeredAt != null ? triggeredAt() : this.triggeredAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LimitAlert && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
