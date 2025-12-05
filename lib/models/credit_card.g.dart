// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'credit_card.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CreditCardAdapter extends TypeAdapter<CreditCard> {
  @override
  final int typeId = 10;

  @override
  CreditCard read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CreditCard(
      id: fields[0] as String,
      bankName: fields[1] as String,
      cardName: fields[2] as String,
      last4Digits: fields[3] as String,
      creditLimit: fields[4] as double,
      statementDay: fields[5] as int,
      dueDateOffset: fields[6] as int,
      monthlyInterestRate: fields[7] as double,
      lateInterestRate: fields[8] as double,
      cardColor: fields[9] as int,
      createdAt: fields[10] as DateTime,
      isActive: fields[11] as bool,
      initialDebt: fields[12] as double,
      cardImagePath: fields[13] as String?,
      iconName: fields[14] as String?,
      rewardType: fields[15] as String?,
      pointsConversionRate: fields[16] as double?,
      cashAdvanceRate: fields[17] as double?,
      cashAdvanceLimit: fields[18] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, CreditCard obj) {
    writer
      ..writeByte(19)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.bankName)
      ..writeByte(2)
      ..write(obj.cardName)
      ..writeByte(3)
      ..write(obj.last4Digits)
      ..writeByte(4)
      ..write(obj.creditLimit)
      ..writeByte(5)
      ..write(obj.statementDay)
      ..writeByte(6)
      ..write(obj.dueDateOffset)
      ..writeByte(7)
      ..write(obj.monthlyInterestRate)
      ..writeByte(8)
      ..write(obj.lateInterestRate)
      ..writeByte(9)
      ..write(obj.cardColor)
      ..writeByte(10)
      ..write(obj.createdAt)
      ..writeByte(11)
      ..write(obj.isActive)
      ..writeByte(12)
      ..write(obj.initialDebt)
      ..writeByte(13)
      ..write(obj.cardImagePath)
      ..writeByte(14)
      ..write(obj.iconName)
      ..writeByte(15)
      ..write(obj.rewardType)
      ..writeByte(16)
      ..write(obj.pointsConversionRate)
      ..writeByte(17)
      ..write(obj.cashAdvanceRate)
      ..writeByte(18)
      ..write(obj.cashAdvanceLimit);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CreditCardAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
