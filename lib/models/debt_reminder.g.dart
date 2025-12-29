// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'debt_reminder.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DebtReminder _$DebtReminderFromJson(Map<String, dynamic> json) => DebtReminder(
      id: json['id'] as String,
      debtId: json['debtId'] as String,
      reminderDate: DateTime.parse(json['reminderDate'] as String),
      message: json['message'] as String,
      type: $enumDecode(_$ReminderTypeEnumMap, json['type']),
      status: $enumDecode(_$ReminderStatusEnumMap, json['status']),
      createdDate: DateTime.parse(json['createdDate'] as String),
      sentDate: json['sentDate'] == null
          ? null
          : DateTime.parse(json['sentDate'] as String),
      nextReminderDate: json['nextReminderDate'] == null
          ? null
          : DateTime.parse(json['nextReminderDate'] as String),
      recurrenceFrequency: $enumDecodeNullable(
          _$RecurrenceFrequencyEnumMap, json['recurrenceFrequency']),
      recurrenceInterval: (json['recurrenceInterval'] as num?)?.toInt(),
      maxRecurrences: (json['maxRecurrences'] as num?)?.toInt(),
      currentRecurrenceCount:
          (json['currentRecurrenceCount'] as num?)?.toInt() ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      failureReason: json['failureReason'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$DebtReminderToJson(DebtReminder instance) =>
    <String, dynamic>{
      'id': instance.id,
      'debtId': instance.debtId,
      'reminderDate': instance.reminderDate.toIso8601String(),
      'message': instance.message,
      'type': _$ReminderTypeEnumMap[instance.type]!,
      'status': _$ReminderStatusEnumMap[instance.status]!,
      'createdDate': instance.createdDate.toIso8601String(),
      'sentDate': instance.sentDate?.toIso8601String(),
      'nextReminderDate': instance.nextReminderDate?.toIso8601String(),
      'recurrenceFrequency':
          _$RecurrenceFrequencyEnumMap[instance.recurrenceFrequency],
      'recurrenceInterval': instance.recurrenceInterval,
      'maxRecurrences': instance.maxRecurrences,
      'currentRecurrenceCount': instance.currentRecurrenceCount,
      'isActive': instance.isActive,
      'failureReason': instance.failureReason,
      'metadata': instance.metadata,
    };

const _$ReminderTypeEnumMap = {
  ReminderType.dueDateBefore: 'due_date_before',
  ReminderType.dueDate: 'due_date',
  ReminderType.overdue: 'overdue',
  ReminderType.custom: 'custom',
  ReminderType.recurring: 'recurring',
};

const _$ReminderStatusEnumMap = {
  ReminderStatus.pending: 'pending',
  ReminderStatus.sent: 'sent',
  ReminderStatus.failed: 'failed',
  ReminderStatus.cancelled: 'cancelled',
};

const _$RecurrenceFrequencyEnumMap = {
  RecurrenceFrequency.daily: 'daily',
  RecurrenceFrequency.weekly: 'weekly',
  RecurrenceFrequency.monthly: 'monthly',
  RecurrenceFrequency.customDays: 'custom_days',
};
