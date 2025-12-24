// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'limit_alert.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LimitAlertAdapter extends TypeAdapter<LimitAlert> {
  @override
  final int typeId = 22;

  @override
  LimitAlert read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LimitAlert(
      id: fields[0] as String,
      cardId: fields[1] as String,
      threshold: fields[2] as double,
      isTriggered: fields[3] as bool,
      triggeredAt: fields[4] as DateTime?,
      createdAt: fields[5] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, LimitAlert obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.cardId)
      ..writeByte(2)
      ..write(obj.threshold)
      ..writeByte(3)
      ..write(obj.isTriggered)
      ..writeByte(4)
      ..write(obj.triggeredAt)
      ..writeByte(5)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LimitAlertAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
