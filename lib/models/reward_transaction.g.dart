// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reward_transaction.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RewardTransactionAdapter extends TypeAdapter<RewardTransaction> {
  @override
  final int typeId = 21;

  @override
  RewardTransaction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RewardTransaction(
      id: fields[0] as String,
      cardId: fields[1] as String,
      transactionId: fields[2] as String?,
      pointsEarned: fields[3] as double,
      pointsSpent: fields[4] as double,
      description: fields[5] as String,
      transactionDate: fields[6] as DateTime,
      createdAt: fields[7] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, RewardTransaction obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.cardId)
      ..writeByte(2)
      ..write(obj.transactionId)
      ..writeByte(3)
      ..write(obj.pointsEarned)
      ..writeByte(4)
      ..write(obj.pointsSpent)
      ..writeByte(5)
      ..write(obj.description)
      ..writeByte(6)
      ..write(obj.transactionDate)
      ..writeByte(7)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RewardTransactionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
