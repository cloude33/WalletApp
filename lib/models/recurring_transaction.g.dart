// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurring_transaction.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RecurringTransactionAdapter extends TypeAdapter<RecurringTransaction> {
  @override
  final int typeId = 7;

  @override
  RecurringTransaction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RecurringTransaction(
      id: fields[0] as String,
      title: fields[1] as String,
      amount: fields[2] as double,
      category: fields[3] as String,
      description: fields[4] as String?,
      frequency: fields[5] as RecurrenceFrequency,
      startDate: fields[6] as DateTime,
      endDate: fields[7] as DateTime?,
      occurrenceCount: fields[8] as int?,
      createdCount: fields[9] as int,
      lastCreatedDate: fields[10] as DateTime?,
      isActive: fields[11] as bool,
      isIncome: fields[12] as bool,
      createdAt: fields[13] as DateTime,
      notificationEnabled: fields[14] as bool,
      reminderDaysBefore: fields[15] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, RecurringTransaction obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.category)
      ..writeByte(4)
      ..write(obj.description)
      ..writeByte(5)
      ..write(obj.frequency)
      ..writeByte(6)
      ..write(obj.startDate)
      ..writeByte(7)
      ..write(obj.endDate)
      ..writeByte(8)
      ..write(obj.occurrenceCount)
      ..writeByte(9)
      ..write(obj.createdCount)
      ..writeByte(10)
      ..write(obj.lastCreatedDate)
      ..writeByte(11)
      ..write(obj.isActive)
      ..writeByte(12)
      ..write(obj.isIncome)
      ..writeByte(13)
      ..write(obj.createdAt)
      ..writeByte(14)
      ..write(obj.notificationEnabled)
      ..writeByte(15)
      ..write(obj.reminderDaysBefore);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecurringTransactionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
