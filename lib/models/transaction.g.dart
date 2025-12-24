// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Transaction _$TransactionFromJson(Map<String, dynamic> json) => Transaction(
      id: json['id'] as String,
      type: json['type'] as String,
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] as String,
      category: json['category'] as String,
      walletId: json['walletId'] as String,
      date: DateTime.parse(json['date'] as String),
      memo: json['memo'] as String?,
      images:
          (json['images'] as List<dynamic>?)?.map((e) => e as String).toList(),
      installments: (json['installments'] as num?)?.toInt(),
      currentInstallment: (json['currentInstallment'] as num?)?.toInt(),
      parentTransactionId: json['parentTransactionId'] as String?,
      recurringTransactionId: json['recurringTransactionId'] as String?,
      isIncome: json['isIncome'] as bool? ?? false,
    );

Map<String, dynamic> _$TransactionToJson(Transaction instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'amount': instance.amount,
      'description': instance.description,
      'category': instance.category,
      'walletId': instance.walletId,
      'date': instance.date.toIso8601String(),
      'memo': instance.memo,
      'images': instance.images,
      'installments': instance.installments,
      'currentInstallment': instance.currentInstallment,
      'parentTransactionId': instance.parentTransactionId,
      'recurringTransactionId': instance.recurringTransactionId,
      'isIncome': instance.isIncome,
    };
