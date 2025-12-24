// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kmh_transaction.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class KmhTransactionAdapter extends TypeAdapter<KmhTransaction> {
  @override
  final int typeId = 30;

  @override
  KmhTransaction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return KmhTransaction(
      id: fields[0] as String,
      walletId: fields[1] as String,
      type: fields[2] as KmhTransactionType,
      amount: fields[3] as double,
      date: fields[4] as DateTime,
      description: fields[5] as String,
      balanceAfter: fields[6] as double,
      interestAmount: fields[7] as double?,
      linkedTransactionId: fields[8] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, KmhTransaction obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.walletId)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.amount)
      ..writeByte(4)
      ..write(obj.date)
      ..writeByte(5)
      ..write(obj.description)
      ..writeByte(6)
      ..write(obj.balanceAfter)
      ..writeByte(7)
      ..write(obj.interestAmount)
      ..writeByte(8)
      ..write(obj.linkedTransactionId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KmhTransactionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
