// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_plan.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PaymentPlanAdapter extends TypeAdapter<PaymentPlan> {
  @override
  final int typeId = 31;

  @override
  PaymentPlan read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PaymentPlan(
      id: fields[0] as String,
      walletId: fields[1] as String,
      initialDebt: fields[2] as double,
      monthlyPayment: fields[3] as double,
      annualRate: fields[4] as double,
      durationMonths: fields[5] as int,
      totalInterest: fields[6] as double,
      totalPayment: fields[7] as double,
      createdAt: fields[8] as DateTime,
      isActive: fields[9] as bool,
      reminderSchedule: fields[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, PaymentPlan obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.walletId)
      ..writeByte(2)
      ..write(obj.initialDebt)
      ..writeByte(3)
      ..write(obj.monthlyPayment)
      ..writeByte(4)
      ..write(obj.annualRate)
      ..writeByte(5)
      ..write(obj.durationMonths)
      ..writeByte(6)
      ..write(obj.totalInterest)
      ..writeByte(7)
      ..write(obj.totalPayment)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.isActive)
      ..writeByte(10)
      ..write(obj.reminderSchedule);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentPlanAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
