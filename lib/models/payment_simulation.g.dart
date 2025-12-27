// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_simulation.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PaymentSimulationAdapter extends TypeAdapter<PaymentSimulation> {
  @override
  final int typeId = 23;

  @override
  PaymentSimulation read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PaymentSimulation(
      id: fields[0] as String,
      cardId: fields[1] as String,
      currentDebt: fields[2] as double,
      proposedPayment: fields[3] as double,
      remainingDebt: fields[4] as double,
      interestCharged: fields[5] as double,
      monthsToPayoff: fields[6] as int,
      totalCost: fields[7] as double,
      simulationDate: fields[8] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, PaymentSimulation obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.cardId)
      ..writeByte(2)
      ..write(obj.currentDebt)
      ..writeByte(3)
      ..write(obj.proposedPayment)
      ..writeByte(4)
      ..write(obj.remainingDebt)
      ..writeByte(5)
      ..write(obj.interestCharged)
      ..writeByte(6)
      ..write(obj.monthsToPayoff)
      ..writeByte(7)
      ..write(obj.totalCost)
      ..writeByte(8)
      ..write(obj.simulationDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentSimulationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
