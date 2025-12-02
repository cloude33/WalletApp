// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bill_payment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BillPayment _$BillPaymentFromJson(Map<String, dynamic> json) => BillPayment(
      id: json['id'] as String,
      templateId: json['templateId'] as String,
      amount: (json['amount'] as num).toDouble(),
      dueDate: DateTime.parse(json['dueDate'] as String),
      periodStart: DateTime.parse(json['periodStart'] as String),
      periodEnd: DateTime.parse(json['periodEnd'] as String),
      status: $enumDecode(_$BillPaymentStatusEnumMap, json['status']),
      paidDate: json['paidDate'] == null
          ? null
          : DateTime.parse(json['paidDate'] as String),
      paidWithWalletId: json['paidWithWalletId'] as String?,
      transactionId: json['transactionId'] as String?,
      notes: json['notes'] as String?,
      createdDate: DateTime.parse(json['createdDate'] as String),
      updatedDate: DateTime.parse(json['updatedDate'] as String),
    );

Map<String, dynamic> _$BillPaymentToJson(BillPayment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'templateId': instance.templateId,
      'amount': instance.amount,
      'dueDate': instance.dueDate.toIso8601String(),
      'periodStart': instance.periodStart.toIso8601String(),
      'periodEnd': instance.periodEnd.toIso8601String(),
      'status': _$BillPaymentStatusEnumMap[instance.status]!,
      'paidDate': instance.paidDate?.toIso8601String(),
      'paidWithWalletId': instance.paidWithWalletId,
      'transactionId': instance.transactionId,
      'notes': instance.notes,
      'createdDate': instance.createdDate.toIso8601String(),
      'updatedDate': instance.updatedDate.toIso8601String(),
    };

const _$BillPaymentStatusEnumMap = {
  BillPaymentStatus.pending: 'pending',
  BillPaymentStatus.paid: 'paid',
  BillPaymentStatus.overdue: 'overdue',
};
