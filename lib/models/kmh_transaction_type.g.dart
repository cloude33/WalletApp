// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kmh_transaction_type.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class KmhTransactionTypeAdapter extends TypeAdapter<KmhTransactionType> {
  @override
  final int typeId = 31;

  @override
  KmhTransactionType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return KmhTransactionType.withdrawal;
      case 1:
        return KmhTransactionType.deposit;
      case 2:
        return KmhTransactionType.interest;
      case 3:
        return KmhTransactionType.fee;
      case 4:
        return KmhTransactionType.transfer;
      default:
        return KmhTransactionType.withdrawal;
    }
  }

  @override
  void write(BinaryWriter writer, KmhTransactionType obj) {
    switch (obj) {
      case KmhTransactionType.withdrawal:
        writer.writeByte(0);
        break;
      case KmhTransactionType.deposit:
        writer.writeByte(1);
        break;
      case KmhTransactionType.interest:
        writer.writeByte(2);
        break;
      case KmhTransactionType.fee:
        writer.writeByte(3);
        break;
      case KmhTransactionType.transfer:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KmhTransactionTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
