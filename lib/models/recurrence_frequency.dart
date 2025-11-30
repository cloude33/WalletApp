import 'package:hive/hive.dart';

part 'recurrence_frequency.g.dart';

@HiveType(typeId: 8)
enum RecurrenceFrequency {
  @HiveField(0)
  daily,
  
  @HiveField(1)
  weekly,
  
  @HiveField(2)
  monthly,
  
  @HiveField(3)
  yearly;

  String get displayName {
    switch (this) {
      case RecurrenceFrequency.daily:
        return 'Günlük';
      case RecurrenceFrequency.weekly:
        return 'Haftalık';
      case RecurrenceFrequency.monthly:
        return 'Aylık';
      case RecurrenceFrequency.yearly:
        return 'Yıllık';
    }
  }

  String get shortName {
    switch (this) {
      case RecurrenceFrequency.daily:
        return 'Gün';
      case RecurrenceFrequency.weekly:
        return 'Hafta';
      case RecurrenceFrequency.monthly:
        return 'Ay';
      case RecurrenceFrequency.yearly:
        return 'Yıl';
    }
  }
}
