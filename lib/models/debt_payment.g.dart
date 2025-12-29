// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'debt_payment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DebtPayment _$DebtPaymentFromJson(Map<String, dynamic> json) => DebtPayment(
      id: json['id'] as String,
      debtId: json['debtId'] as String,
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      type: $enumDecode(_$PaymentTypeEnumMap, json['type']),
      note: json['note'] as String?,
      createdDate: DateTime.parse(json['createdDate'] as String),
      updatedDate: DateTime.parse(json['updatedDate'] as String),
      isDeleted: json['isDeleted'] as bool? ?? false,
    );

Map<String, dynamic> _$DebtPaymentToJson(DebtPayment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'debtId': instance.debtId,
      'amount': instance.amount,
      'date': instance.date.toIso8601String(),
      'type': _$PaymentTypeEnumMap[instance.type]!,
      'note': instance.note,
      'createdDate': instance.createdDate.toIso8601String(),
      'updatedDate': instance.updatedDate.toIso8601String(),
      'isDeleted': instance.isDeleted,
    };

const _$PaymentTypeEnumMap = {
  PaymentType.partial: 'partial',
  PaymentType.full: 'full',
  PaymentType.adjustment: 'adjustment',
};
