import 'package:flutter/material.dart';

class NotificationPreferences {
  final bool budgetAlertsEnabled;
  final int budgetAlertThreshold; // percentage (default 80)
  final bool dailySummaryEnabled;
  final TimeOfDay dailySummaryTime;
  final bool weeklySummaryEnabled;
  final TimeOfDay weeklySummaryTime;
  final bool billRemindersEnabled;
  final int billReminderDays; // days before due date (default 3)
  final bool installmentRemindersEnabled;
  final int installmentReminderDays; // days before due date (default 5)

  const NotificationPreferences({
    required this.budgetAlertsEnabled,
    required this.budgetAlertThreshold,
    required this.dailySummaryEnabled,
    required this.dailySummaryTime,
    required this.weeklySummaryEnabled,
    required this.weeklySummaryTime,
    required this.billRemindersEnabled,
    required this.billReminderDays,
    required this.installmentRemindersEnabled,
    required this.installmentReminderDays,
  });

  /// Default preferences
  static NotificationPreferences get defaults => const NotificationPreferences(
        budgetAlertsEnabled: true,
        budgetAlertThreshold: 80,
        dailySummaryEnabled: false,
        dailySummaryTime: TimeOfDay(hour: 20, minute: 0), // 8 PM
        weeklySummaryEnabled: false,
        weeklySummaryTime: TimeOfDay(hour: 9, minute: 0), // 9 AM Monday
        billRemindersEnabled: true,
        billReminderDays: 3,
        installmentRemindersEnabled: true,
        installmentReminderDays: 5,
      );

  Map<String, dynamic> toJson() => {
        'budgetAlertsEnabled': budgetAlertsEnabled,
        'budgetAlertThreshold': budgetAlertThreshold,
        'dailySummaryEnabled': dailySummaryEnabled,
        'dailySummaryTime': {
          'hour': dailySummaryTime.hour,
          'minute': dailySummaryTime.minute,
        },
        'weeklySummaryEnabled': weeklySummaryEnabled,
        'weeklySummaryTime': {
          'hour': weeklySummaryTime.hour,
          'minute': weeklySummaryTime.minute,
        },
        'billRemindersEnabled': billRemindersEnabled,
        'billReminderDays': billReminderDays,
        'installmentRemindersEnabled': installmentRemindersEnabled,
        'installmentReminderDays': installmentReminderDays,
      };

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      budgetAlertsEnabled: json['budgetAlertsEnabled'] ?? true,
      budgetAlertThreshold: json['budgetAlertThreshold'] ?? 80,
      dailySummaryEnabled: json['dailySummaryEnabled'] ?? false,
      dailySummaryTime: json['dailySummaryTime'] != null
          ? TimeOfDay(
              hour: json['dailySummaryTime']['hour'],
              minute: json['dailySummaryTime']['minute'],
            )
          : const TimeOfDay(hour: 20, minute: 0),
      weeklySummaryEnabled: json['weeklySummaryEnabled'] ?? false,
      weeklySummaryTime: json['weeklySummaryTime'] != null
          ? TimeOfDay(
              hour: json['weeklySummaryTime']['hour'],
              minute: json['weeklySummaryTime']['minute'],
            )
          : const TimeOfDay(hour: 9, minute: 0),
      billRemindersEnabled: json['billRemindersEnabled'] ?? true,
      billReminderDays: json['billReminderDays'] ?? 3,
      installmentRemindersEnabled: json['installmentRemindersEnabled'] ?? true,
      installmentReminderDays: json['installmentReminderDays'] ?? 5,
    );
  }

  NotificationPreferences copyWith({
    bool? budgetAlertsEnabled,
    int? budgetAlertThreshold,
    bool? dailySummaryEnabled,
    TimeOfDay? dailySummaryTime,
    bool? weeklySummaryEnabled,
    TimeOfDay? weeklySummaryTime,
    bool? billRemindersEnabled,
    int? billReminderDays,
    bool? installmentRemindersEnabled,
    int? installmentReminderDays,
  }) {
    return NotificationPreferences(
      budgetAlertsEnabled: budgetAlertsEnabled ?? this.budgetAlertsEnabled,
      budgetAlertThreshold: budgetAlertThreshold ?? this.budgetAlertThreshold,
      dailySummaryEnabled: dailySummaryEnabled ?? this.dailySummaryEnabled,
      dailySummaryTime: dailySummaryTime ?? this.dailySummaryTime,
      weeklySummaryEnabled: weeklySummaryEnabled ?? this.weeklySummaryEnabled,
      weeklySummaryTime: weeklySummaryTime ?? this.weeklySummaryTime,
      billRemindersEnabled: billRemindersEnabled ?? this.billRemindersEnabled,
      billReminderDays: billReminderDays ?? this.billReminderDays,
      installmentRemindersEnabled:
          installmentRemindersEnabled ?? this.installmentRemindersEnabled,
      installmentReminderDays:
          installmentReminderDays ?? this.installmentReminderDays,
    );
  }
}
