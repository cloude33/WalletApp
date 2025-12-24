// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Wallet _$WalletFromJson(Map<String, dynamic> json) => Wallet(
      id: json['id'] as String,
      name: json['name'] as String,
      balance: (json['balance'] as num).toDouble(),
      type: json['type'] as String,
      color: json['color'] as String,
      icon: json['icon'] as String,
      cutOffDay: (json['cutOffDay'] as num?)?.toInt() ?? 0,
      paymentDay: (json['paymentDay'] as num?)?.toInt() ?? 0,
      installment: (json['installment'] as num?)?.toInt() ?? 1,
      creditLimit: (json['creditLimit'] as num?)?.toDouble() ?? 0.0,
      interestRate: (json['interestRate'] as num?)?.toDouble(),
      lastInterestDate: json['lastInterestDate'] == null
          ? null
          : DateTime.parse(json['lastInterestDate'] as String),
      accruedInterest: (json['accruedInterest'] as num?)?.toDouble(),
      accountNumber: json['accountNumber'] as String?,
    );

Map<String, dynamic> _$WalletToJson(Wallet instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'balance': instance.balance,
      'type': instance.type,
      'color': instance.color,
      'icon': instance.icon,
      'cutOffDay': instance.cutOffDay,
      'paymentDay': instance.paymentDay,
      'installment': instance.installment,
      'creditLimit': instance.creditLimit,
      'interestRate': instance.interestRate,
      'lastInterestDate': instance.lastInterestDate?.toIso8601String(),
      'accruedInterest': instance.accruedInterest,
      'accountNumber': instance.accountNumber,
    };
