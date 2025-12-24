// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'credit_card_payment.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CreditCardPaymentAdapter extends TypeAdapter<CreditCardPayment> {
  @override
  final int typeId = 13;

  @override
  CreditCardPayment read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CreditCardPayment(
      id: fields[0] as String,
      cardId: fields[1] as String,
      statementId: fields[2] as String,
      amount: fields[3] as double,
      paymentDate: fields[4] as DateTime,
      paymentMethod: fields[5] as String,
      note: fields[6] as String,
      createdAt: fields[7] as DateTime,
      paymentType: fields[8] as String,
      remainingDebtAfterPayment: fields[9] as double,
    );
  }

  @override
  void write(BinaryWriter writer, CreditCardPayment obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.cardId)
      ..writeByte(2)
      ..write(obj.statementId)
      ..writeByte(3)
      ..write(obj.amount)
      ..writeByte(4)
      ..write(obj.paymentDate)
      ..writeByte(5)
      ..write(obj.paymentMethod)
      ..writeByte(6)
      ..write(obj.note)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.paymentType)
      ..writeByte(9)
      ..write(obj.remainingDebtAfterPayment);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CreditCardPaymentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
