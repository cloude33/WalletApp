import 'package:json_annotation/json_annotation.dart';

part 'debt_reminder.g.dart';

/// Hatırlatma tipi enum'u
enum ReminderType {
  @JsonValue('due_date_before')
  dueDateBefore, // Vade tarihinden önce
  
  @JsonValue('due_date')
  dueDate, // Vade tarihinde
  
  @JsonValue('overdue')
  overdue, // Vadesi geçmiş
  
  @JsonValue('custom')
  custom, // Özel hatırlatma
  
  @JsonValue('recurring')
  recurring, // Tekrarlayan hatırlatma
}

/// Hatırlatma durumu enum'u
enum ReminderStatus {
  @JsonValue('pending')
  pending, // Bekliyor
  
  @JsonValue('sent')
  sent, // Gönderildi
  
  @JsonValue('failed')
  failed, // Başarısız
  
  @JsonValue('cancelled')
  cancelled, // İptal edildi
}

/// Tekrarlama sıklığı enum'u
enum RecurrenceFrequency {
  @JsonValue('daily')
  daily, // Günlük
  
  @JsonValue('weekly')
  weekly, // Haftalık
  
  @JsonValue('monthly')
  monthly, // Aylık
  
  @JsonValue('custom_days')
  customDays, // Özel gün sayısı
}

/// Borç hatırlatması modeli
@JsonSerializable()
class DebtReminder {
  final String id;
  final String debtId;
  final DateTime reminderDate;
  final String message;
  final ReminderType type;
  final ReminderStatus status;
  final DateTime createdDate;
  final DateTime? sentDate;
  final DateTime? nextReminderDate;
  final RecurrenceFrequency? recurrenceFrequency;
  final int? recurrenceInterval; // Kaç günde bir
  final int? maxRecurrences; // Maksimum tekrar sayısı
  final int currentRecurrenceCount;
  final bool isActive;
  final String? failureReason;
  final Map<String, dynamic>? metadata;

  const DebtReminder({
    required this.id,
    required this.debtId,
    required this.reminderDate,
    required this.message,
    required this.type,
    required this.status,
    required this.createdDate,
    this.sentDate,
    this.nextReminderDate,
    this.recurrenceFrequency,
    this.recurrenceInterval,
    this.maxRecurrences,
    this.currentRecurrenceCount = 0,
    this.isActive = true,
    this.failureReason,
    this.metadata,
  });

  factory DebtReminder.fromJson(Map<String, dynamic> json) => _$DebtReminderFromJson(json);
  Map<String, dynamic> toJson() => _$DebtReminderToJson(this);

  DebtReminder copyWith({
    String? id,
    String? debtId,
    DateTime? reminderDate,
    String? message,
    ReminderType? type,
    ReminderStatus? status,
    DateTime? createdDate,
    DateTime? sentDate,
    DateTime? nextReminderDate,
    RecurrenceFrequency? recurrenceFrequency,
    int? recurrenceInterval,
    int? maxRecurrences,
    int? currentRecurrenceCount,
    bool? isActive,
    String? failureReason,
    Map<String, dynamic>? metadata,
  }) {
    return DebtReminder(
      id: id ?? this.id,
      debtId: debtId ?? this.debtId,
      reminderDate: reminderDate ?? this.reminderDate,
      message: message ?? this.message,
      type: type ?? this.type,
      status: status ?? this.status,
      createdDate: createdDate ?? this.createdDate,
      sentDate: sentDate ?? this.sentDate,
      nextReminderDate: nextReminderDate ?? this.nextReminderDate,
      recurrenceFrequency: recurrenceFrequency ?? this.recurrenceFrequency,
      recurrenceInterval: recurrenceInterval ?? this.recurrenceInterval,
      maxRecurrences: maxRecurrences ?? this.maxRecurrences,
      currentRecurrenceCount: currentRecurrenceCount ?? this.currentRecurrenceCount,
      isActive: isActive ?? this.isActive,
      failureReason: failureReason ?? this.failureReason,
      metadata: metadata ?? this.metadata,
    );
  }

  String get typeText {
    switch (type) {
      case ReminderType.dueDateBefore:
        return 'Vade Öncesi';
      case ReminderType.dueDate:
        return 'Vade Tarihi';
      case ReminderType.overdue:
        return 'Vadesi Geçmiş';
      case ReminderType.custom:
        return 'Özel Hatırlatma';
      case ReminderType.recurring:
        return 'Tekrarlayan';
    }
  }

  String get statusText {
    switch (status) {
      case ReminderStatus.pending:
        return 'Bekliyor';
      case ReminderStatus.sent:
        return 'Gönderildi';
      case ReminderStatus.failed:
        return 'Başarısız';
      case ReminderStatus.cancelled:
        return 'İptal Edildi';
    }
  }

  bool get isPastDue {
    return DateTime.now().isAfter(reminderDate) && status == ReminderStatus.pending;
  }

  bool get isRecurring {
    return recurrenceFrequency != null && type == ReminderType.recurring;
  }

  String? validate() {
    if (message.trim().isEmpty) {
      return 'Hatırlatma mesajı boş olamaz';
    }
    if (reminderDate.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
      return 'Hatırlatma tarihi çok geçmişte olamaz';
    }
    return null;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DebtReminder && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
