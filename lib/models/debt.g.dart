// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'debt.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Debt _$DebtFromJson(Map<String, dynamic> json) => Debt(
      id: json['id'] as String,
      personName: json['personName'] as String,
      phone: json['phone'] as String?,
      originalAmount: (json['originalAmount'] as num).toDouble(),
      remainingAmount: (json['remainingAmount'] as num).toDouble(),
      type: $enumDecode(_$DebtTypeEnumMap, json['type']),
      status: $enumDecode(_$DebtStatusEnumMap, json['status']),
      category: $enumDecode(_$DebtCategoryEnumMap, json['category']),
      createdDate: DateTime.parse(json['createdDate'] as String),
      dueDate: json['dueDate'] == null
          ? null
          : DateTime.parse(json['dueDate'] as String),
      description: json['description'] as String?,
      paymentIds: (json['paymentIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      reminderIds: (json['reminderIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      lastPaymentDate: json['lastPaymentDate'] == null
          ? null
          : DateTime.parse(json['lastPaymentDate'] as String),
      updatedDate: DateTime.parse(json['updatedDate'] as String),
    );

Map<String, dynamic> _$DebtToJson(Debt instance) => <String, dynamic>{
      'id': instance.id,
      'personName': instance.personName,
      'phone': instance.phone,
      'originalAmount': instance.originalAmount,
      'remainingAmount': instance.remainingAmount,
      'type': _$DebtTypeEnumMap[instance.type]!,
      'status': _$DebtStatusEnumMap[instance.status]!,
      'category': _$DebtCategoryEnumMap[instance.category]!,
      'createdDate': instance.createdDate.toIso8601String(),
      'dueDate': instance.dueDate?.toIso8601String(),
      'description': instance.description,
      'paymentIds': instance.paymentIds,
      'reminderIds': instance.reminderIds,
      'lastPaymentDate': instance.lastPaymentDate?.toIso8601String(),
      'updatedDate': instance.updatedDate.toIso8601String(),
    };

const _$DebtTypeEnumMap = {
  DebtType.lent: 'lent',
  DebtType.borrowed: 'borrowed',
};

const _$DebtStatusEnumMap = {
  DebtStatus.active: 'active',
  DebtStatus.paid: 'paid',
  DebtStatus.overdue: 'overdue',
};

const _$DebtCategoryEnumMap = {
  DebtCategory.friend: 'friend',
  DebtCategory.family: 'family',
  DebtCategory.business: 'business',
  DebtCategory.other: 'other',
};
