// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'credit_card_transaction.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CreditCardTransactionAdapter extends TypeAdapter<CreditCardTransaction> {
  @override
  final int typeId = 11;

  @override
  CreditCardTransaction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CreditCardTransaction(
      id: fields[0] as String,
      cardId: fields[1] as String,
      amount: fields[2] as double,
      description: fields[3] as String,
      transactionDate: fields[4] as DateTime,
      category: fields[5] as String,
      installmentCount: fields[6] as int,
      installmentsPaid: fields[7] as int,
      createdAt: fields[8] as DateTime,
      images: (fields[9] as List?)?.cast<String>(),
      deferredMonths: fields[10] as int?,
      installmentStartDate: fields[11] as DateTime?,
      isCashAdvance: fields[12] as bool,
      pointsEarned: fields[13] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, CreditCardTransaction obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.cardId)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.transactionDate)
      ..writeByte(5)
      ..write(obj.category)
      ..writeByte(6)
      ..write(obj.installmentCount)
      ..writeByte(7)
      ..write(obj.installmentsPaid)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.images)
      ..writeByte(10)
      ..write(obj.deferredMonths)
      ..writeByte(11)
      ..write(obj.installmentStartDate)
      ..writeByte(12)
      ..write(obj.isCashAdvance)
      ..writeByte(13)
      ..write(obj.pointsEarned);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CreditCardTransactionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
