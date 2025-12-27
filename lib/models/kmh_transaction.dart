import 'package:hive/hive.dart';
import 'kmh_transaction_type.dart';

part 'kmh_transaction.g.dart';
@HiveType(typeId: 30)
class KmhTransaction extends HiveObject {
  @HiveField(0)
  String id;
  @HiveField(1)
  String walletId;
  @HiveField(2)
  KmhTransactionType type;
  @HiveField(3)
  double amount;
  @HiveField(4)
  DateTime date;
  @HiveField(5)
  String description;
  @HiveField(6)
  double balanceAfter;
  @HiveField(7)
  double? interestAmount;
  @HiveField(8)
  String? linkedTransactionId;
  KmhTransaction({
    required this.id,
    required this.walletId,
    required this.type,
    required this.amount,
    required this.date,
    required this.description,
    required this.balanceAfter,
    this.interestAmount,
    this.linkedTransactionId,
  });
  String? validate() {
    if (walletId.trim().isEmpty) {
      return 'Wallet ID boş olamaz';
    }
    if (amount <= 0) {
      return 'Tutar sıfırdan büyük olmalı';
    }
    if (description.trim().isEmpty) {
      return 'Açıklama boş olamaz';
    }
    return null;
  }
  KmhTransaction copyWith({
    String? id,
    String? walletId,
    KmhTransactionType? type,
    double? amount,
    DateTime? date,
    String? description,
    double? balanceAfter,
    double? interestAmount,
    String? linkedTransactionId,
  }) {
    return KmhTransaction(
      id: id ?? this.id,
      walletId: walletId ?? this.walletId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      description: description ?? this.description,
      balanceAfter: balanceAfter ?? this.balanceAfter,
      interestAmount: interestAmount ?? this.interestAmount,
      linkedTransactionId: linkedTransactionId ?? this.linkedTransactionId,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is KmhTransaction && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'walletId': walletId,
      'type': type.name,
      'amount': amount,
      'date': date.toIso8601String(),
      'description': description,
      'balanceAfter': balanceAfter,
      'interestAmount': interestAmount,
      'linkedTransactionId': linkedTransactionId,
    };
  }
  factory KmhTransaction.fromJson(Map<String, dynamic> json) {
    return KmhTransaction(
      id: json['id'] as String,
      walletId: json['walletId'] as String,
      type: KmhTransactionType.values.firstWhere(
        (e) => e.name == json['type'],
      ),
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      description: json['description'] as String,
      balanceAfter: (json['balanceAfter'] as num).toDouble(),
      interestAmount: json['interestAmount'] != null
          ? (json['interestAmount'] as num).toDouble()
          : null,
      linkedTransactionId: json['linkedTransactionId'] as String?,
    );
  }
}
