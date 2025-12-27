// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'credit_card_statement.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CreditCardStatementAdapter extends TypeAdapter<CreditCardStatement> {
  @override
  final int typeId = 12;

  @override
  CreditCardStatement read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CreditCardStatement(
      id: fields[0] as String,
      cardId: fields[1] as String,
      periodStart: fields[2] as DateTime,
      periodEnd: fields[3] as DateTime,
      dueDate: fields[4] as DateTime,
      previousBalance: fields[5] as double,
      interestCharged: fields[6] as double,
      newPurchases: fields[7] as double,
      installmentPayments: fields[8] as double,
      totalDebt: fields[9] as double,
      minimumPayment: fields[10] as double,
      paidAmount: fields[11] as double,
      remainingDebt: fields[12] as double,
      paymentDate: fields[13] as DateTime?,
      status: fields[14] as String,
      createdAt: fields[15] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, CreditCardStatement obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.cardId)
      ..writeByte(2)
      ..write(obj.periodStart)
      ..writeByte(3)
      ..write(obj.periodEnd)
      ..writeByte(4)
      ..write(obj.dueDate)
      ..writeByte(5)
      ..write(obj.previousBalance)
      ..writeByte(6)
      ..write(obj.interestCharged)
      ..writeByte(7)
      ..write(obj.newPurchases)
      ..writeByte(8)
      ..write(obj.installmentPayments)
      ..writeByte(9)
      ..write(obj.totalDebt)
      ..writeByte(10)
      ..write(obj.minimumPayment)
      ..writeByte(11)
      ..write(obj.paidAmount)
      ..writeByte(12)
      ..write(obj.remainingDebt)
      ..writeByte(13)
      ..write(obj.paymentDate)
      ..writeByte(14)
      ..write(obj.status)
      ..writeByte(15)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CreditCardStatementAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
