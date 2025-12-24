// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bill_template.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BillTemplate _$BillTemplateFromJson(Map<String, dynamic> json) => BillTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      provider: json['provider'] as String?,
      category: $enumDecode(_$BillTemplateCategoryEnumMap, json['category']),
      accountNumber: json['accountNumber'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      description: json['description'] as String?,
      walletId: json['walletId'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      createdDate: DateTime.parse(json['createdDate'] as String),
      updatedDate: DateTime.parse(json['updatedDate'] as String),
    );

Map<String, dynamic> _$BillTemplateToJson(BillTemplate instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'provider': instance.provider,
      'category': _$BillTemplateCategoryEnumMap[instance.category]!,
      'accountNumber': instance.accountNumber,
      'phoneNumber': instance.phoneNumber,
      'description': instance.description,
      'walletId': instance.walletId,
      'isActive': instance.isActive,
      'createdDate': instance.createdDate.toIso8601String(),
      'updatedDate': instance.updatedDate.toIso8601String(),
    };

const _$BillTemplateCategoryEnumMap = {
  BillTemplateCategory.electricity: 'electricity',
  BillTemplateCategory.water: 'water',
  BillTemplateCategory.gas: 'gas',
  BillTemplateCategory.internet: 'internet',
  BillTemplateCategory.phone: 'phone',
  BillTemplateCategory.rent: 'rent',
  BillTemplateCategory.insurance: 'insurance',
  BillTemplateCategory.subscription: 'subscription',
  BillTemplateCategory.other: 'other',
};
