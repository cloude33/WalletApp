import 'package:hive/hive.dart';
import 'recurrence_frequency.dart';

part 'recurring_transaction.g.dart';

@HiveType(typeId: 7)
class RecurringTransaction extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String title;

  @HiveField(2)
  late double amount;

  @HiveField(3)
  late String category;

  @HiveField(4)
  String? description;

  @HiveField(5)
  late RecurrenceFrequency frequency;

  @HiveField(6)
  late DateTime startDate;

  @HiveField(7)
  DateTime? endDate;

  @HiveField(8)
  int? occurrenceCount;

  @HiveField(9)
  late int createdCount;

  @HiveField(10)
  DateTime? lastCreatedDate;

  @HiveField(11)
  late bool isActive;

  @HiveField(12)
  late bool isIncome;

  @HiveField(13)
  late DateTime createdAt;

  @HiveField(14)
  late bool notificationEnabled;

  @HiveField(15)
  int? reminderDaysBefore;

  RecurringTransaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    this.description,
    required this.frequency,
    required this.startDate,
    this.endDate,
    this.occurrenceCount,
    this.createdCount = 0,
    this.lastCreatedDate,
    this.isActive = true,
    required this.isIncome,
    required this.createdAt,
    this.notificationEnabled = true,
    this.reminderDaysBefore,
  });

  DateTime? get nextDate {
    if (!isActive) return null;

    if (lastCreatedDate == null) {
      final next = startDate;
      if (endDate != null && next.isAfter(endDate!)) {
        return null;
      }
      if (occurrenceCount != null && createdCount >= occurrenceCount!) {
        return null;
      }
      return next;
    }

    final next = _calculateNextDate(lastCreatedDate!);

    if (endDate != null && next.isAfter(endDate!)) {
      return null;
    }
    if (occurrenceCount != null && createdCount >= occurrenceCount!) {
      return null;
    }

    return next;
  }

  DateTime _calculateNextDate(DateTime from) {
    switch (frequency) {
      case RecurrenceFrequency.daily:
        return DateTime(from.year, from.month, from.day + 1);
      case RecurrenceFrequency.weekly:
        return DateTime(from.year, from.month, from.day + 7);
      case RecurrenceFrequency.monthly:
        return DateTime(from.year, from.month + 1, from.day);
      case RecurrenceFrequency.yearly:
        return DateTime(from.year + 1, from.month, from.day);
    }
  }

  bool get shouldDeactivate {
    if (endDate != null && DateTime.now().isAfter(endDate!)) {
      return true;
    }
    if (occurrenceCount != null && createdCount >= occurrenceCount!) {
      return true;
    }
    return false;
  }

  bool shouldProcess(DateTime currentDate) {
    if (!isActive) return false;

    final next = nextDate;
    if (next == null) return false;

    return next.isBefore(currentDate) || next.isAtSameMomentAs(currentDate);
  }

  RecurringTransaction copyWith({
    String? id,
    String? title,
    double? amount,
    String? category,
    String? description,
    RecurrenceFrequency? frequency,
    DateTime? startDate,
    DateTime? endDate,
    int? occurrenceCount,
    int? createdCount,
    DateTime? lastCreatedDate,
    bool? isActive,
    bool? isIncome,
    DateTime? createdAt,
    bool? notificationEnabled,
    int? reminderDaysBefore,
  }) {
    return RecurringTransaction(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      description: description ?? this.description,
      frequency: frequency ?? this.frequency,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      occurrenceCount: occurrenceCount ?? this.occurrenceCount,
      createdCount: createdCount ?? this.createdCount,
      lastCreatedDate: lastCreatedDate ?? this.lastCreatedDate,
      isActive: isActive ?? this.isActive,
      isIncome: isIncome ?? this.isIncome,
      createdAt: createdAt ?? this.createdAt,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
      reminderDaysBefore: reminderDaysBefore ?? this.reminderDaysBefore,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'category': category,
      'description': description,
      'frequency': frequency.index,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'occurrenceCount': occurrenceCount,
      'createdCount': createdCount,
      'lastCreatedDate': lastCreatedDate?.toIso8601String(),
      'isActive': isActive,
      'isIncome': isIncome,
      'createdAt': createdAt.toIso8601String(),
      'notificationEnabled': notificationEnabled,
      'reminderDaysBefore': reminderDaysBefore,
    };
  }

  factory RecurringTransaction.fromJson(Map<String, dynamic> json) {
    return RecurringTransaction(
      id: json['id'] as String,
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      category: json['category'] as String,
      description: json['description'] as String?,
      frequency: RecurrenceFrequency.values[json['frequency'] as int],
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : null,
      occurrenceCount: json['occurrenceCount'] as int?,
      createdCount: json['createdCount'] as int? ?? 0,
      lastCreatedDate: json['lastCreatedDate'] != null
          ? DateTime.parse(json['lastCreatedDate'] as String)
          : null,
      isActive: json['isActive'] as bool? ?? true,
      isIncome: json['isIncome'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      notificationEnabled: json['notificationEnabled'] as bool? ?? true,
      reminderDaysBefore: json['reminderDaysBefore'] as int?,
    );
  }
}
