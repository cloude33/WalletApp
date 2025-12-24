import 'package:flutter/material.dart';

class NotificationPreferences {
  final bool dailySummaryEnabled;
  final TimeOfDay dailySummaryTime;
  final bool weeklySummaryEnabled;
  final TimeOfDay weeklySummaryTime;
  final bool billRemindersEnabled;
  final int billReminderDays;
  final bool installmentRemindersEnabled;
  final int installmentReminderDays;
  final bool paymentRemindersEnabled;
  final List<int> paymentReminderDays;
  final bool limitAlertsEnabled;
  final List<double> limitAlertThresholds;
  final bool statementCutNotificationsEnabled;
  final bool installmentEndingNotificationsEnabled;

  const NotificationPreferences({
    required this.dailySummaryEnabled,
    required this.dailySummaryTime,
    required this.weeklySummaryEnabled,
    required this.weeklySummaryTime,
    required this.billRemindersEnabled,
    required this.billReminderDays,
    required this.installmentRemindersEnabled,
    required this.installmentReminderDays,
    required this.paymentRemindersEnabled,
    required this.paymentReminderDays,
    required this.limitAlertsEnabled,
    required this.limitAlertThresholds,
    required this.statementCutNotificationsEnabled,
    required this.installmentEndingNotificationsEnabled,
  });
  static NotificationPreferences get defaults => const NotificationPreferences(
    dailySummaryEnabled: false,
    dailySummaryTime: TimeOfDay(hour: 20, minute: 0),
    weeklySummaryEnabled: false,
    weeklySummaryTime: TimeOfDay(hour: 9, minute: 0),
    billRemindersEnabled: true,
    billReminderDays: 3,
    installmentRemindersEnabled: true,
    installmentReminderDays: 5,
    paymentRemindersEnabled: true,
    paymentReminderDays: [3, 7],
    limitAlertsEnabled: true,
    limitAlertThresholds: [80.0, 90.0, 100.0],
    statementCutNotificationsEnabled: true,
    installmentEndingNotificationsEnabled: true,
  );

  Map<String, dynamic> toJson() => {
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
    'paymentRemindersEnabled': paymentRemindersEnabled,
    'paymentReminderDays': paymentReminderDays,
    'limitAlertsEnabled': limitAlertsEnabled,
    'limitAlertThresholds': limitAlertThresholds,
    'statementCutNotificationsEnabled': statementCutNotificationsEnabled,
    'installmentEndingNotificationsEnabled': installmentEndingNotificationsEnabled,
  };

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
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
      paymentRemindersEnabled: json['paymentRemindersEnabled'] ?? true,
      paymentReminderDays: json['paymentReminderDays'] != null
          ? List<int>.from(json['paymentReminderDays'])
          : [3, 7],
      limitAlertsEnabled: json['limitAlertsEnabled'] ?? true,
      limitAlertThresholds: json['limitAlertThresholds'] != null
          ? List<double>.from(json['limitAlertThresholds'])
          : [80.0, 90.0, 100.0],
      statementCutNotificationsEnabled: json['statementCutNotificationsEnabled'] ?? true,
      installmentEndingNotificationsEnabled: json['installmentEndingNotificationsEnabled'] ?? true,
    );
  }

  NotificationPreferences copyWith({
    bool? dailySummaryEnabled,
    TimeOfDay? dailySummaryTime,
    bool? weeklySummaryEnabled,
    TimeOfDay? weeklySummaryTime,
    bool? billRemindersEnabled,
    int? billReminderDays,
    bool? installmentRemindersEnabled,
    int? installmentReminderDays,
    bool? paymentRemindersEnabled,
    List<int>? paymentReminderDays,
    bool? limitAlertsEnabled,
    List<double>? limitAlertThresholds,
    bool? statementCutNotificationsEnabled,
    bool? installmentEndingNotificationsEnabled,
  }) {
    return NotificationPreferences(
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
      paymentRemindersEnabled: paymentRemindersEnabled ?? this.paymentRemindersEnabled,
      paymentReminderDays: paymentReminderDays ?? this.paymentReminderDays,
      limitAlertsEnabled: limitAlertsEnabled ?? this.limitAlertsEnabled,
      limitAlertThresholds: limitAlertThresholds ?? this.limitAlertThresholds,
      statementCutNotificationsEnabled: statementCutNotificationsEnabled ?? this.statementCutNotificationsEnabled,
      installmentEndingNotificationsEnabled: installmentEndingNotificationsEnabled ?? this.installmentEndingNotificationsEnabled,
    );
  }
}
