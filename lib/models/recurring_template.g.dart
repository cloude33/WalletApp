// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurring_template.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RecurringTemplateAdapter extends TypeAdapter<RecurringTemplate> {
  @override
  final int typeId = 9;

  @override
  RecurringTemplate read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RecurringTemplate(
      id: fields[0] as String,
      name: fields[1] as String,
      category: fields[2] as String,
      defaultFrequency: fields[3] as RecurrenceFrequency,
      isIncome: fields[4] as bool,
      icon: fields[5] as String?,
      isCustom: fields[6] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, RecurringTemplate obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.category)
      ..writeByte(3)
      ..write(obj.defaultFrequency)
      ..writeByte(4)
      ..write(obj.isIncome)
      ..writeByte(5)
      ..write(obj.icon)
      ..writeByte(6)
      ..write(obj.isCustom);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecurringTemplateAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
