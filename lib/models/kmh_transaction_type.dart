import 'package:hive/hive.dart';

part 'kmh_transaction_type.g.dart';

@HiveType(typeId: 31)
enum KmhTransactionType {
  @HiveField(0)
  withdrawal,
  
  @HiveField(1)
  deposit,
  
  @HiveField(2)
  interest,
  
  @HiveField(3)
  fee,
  
  @HiveField(4)
  transfer
}
