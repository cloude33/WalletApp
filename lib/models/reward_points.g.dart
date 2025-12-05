// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reward_points.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RewardPointsAdapter extends TypeAdapter<RewardPoints> {
  @override
  final int typeId = 20;

  @override
  RewardPoints read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RewardPoints(
      id: fields[0] as String,
      cardId: fields[1] as String,
      rewardType: fields[2] as String,
      pointsBalance: fields[3] as double,
      conversionRate: fields[4] as double,
      lastUpdated: fields[5] as DateTime,
      createdAt: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, RewardPoints obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.cardId)
      ..writeByte(2)
      ..write(obj.rewardType)
      ..writeByte(3)
      ..write(obj.pointsBalance)
      ..writeByte(4)
      ..write(obj.conversionRate)
      ..writeByte(5)
      ..write(obj.lastUpdated)
      ..writeByte(6)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RewardPointsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
