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
    );
  }

  @override
  void write(BinaryWriter writer, CreditCardTransaction obj) {
    writer
      ..writeByte(9)
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
      ..write(obj.createdAt);
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
