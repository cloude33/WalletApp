import 'package:flutter/material.dart';

enum NotificationType {
  system,
  general,
  dailySummary,
  weeklySummary,
  monthlySummary,
  billReminder,
  installmentReminder,
  paymentDue,
  recurringDue,
  goalAchieved,
  savingsSuggestion,
  kmhLimitWarning,
  kmhLimitCritical,
  kmhInterestAccrued,
  // Security notification types
  securityFailedLogin,
  securityNewDevice,
  securitySettingsChange,
  securitySuspiciousActivity,
  securityAccountLocked,
}

enum NotificationPriority { low, normal, high, urgent }

class NotificationAction {
  final String id;
  final String title;
  final bool requiresInput;

  const NotificationAction({
    required this.id,
    required this.title,
    this.requiresInput = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'requiresInput': requiresInput,
  };

  factory NotificationAction.fromJson(Map<String, dynamic> json) {
    return NotificationAction(
      id: json['id'],
      title: json['title'],
      requiresInput: json['requiresInput'] ?? false,
    );
  }
}

class AppNotification {
  final String id;
  final NotificationType type;
  final NotificationPriority priority;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;
  final bool isDismissed;
  final Map<String, dynamic>? data;
  final List<NotificationAction>? actions;

  AppNotification({
    required this.id,
    required this.type,
    this.priority = NotificationPriority.normal,
    required this.title,
    required this.message,
    required this.createdAt,
    this.isRead = false,
    this.isDismissed = false,
    this.data,
    this.actions,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'priority': priority.name,
      'title': title,
      'message': message,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
      'isDismissed': isDismissed,
      'data': data,
      'actions': actions?.map((a) => a.toJson()).toList(),
    };
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'],
      type: NotificationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => NotificationType.dailySummary,
      ),
      priority: json['priority'] != null
          ? NotificationPriority.values.firstWhere(
              (e) => e.name == json['priority'],
              orElse: () => NotificationPriority.normal,
            )
          : NotificationPriority.normal,
      title: json['title'],
      message: json['message'],
      createdAt: DateTime.parse(json['createdAt']),
      isRead: json['isRead'] ?? false,
      isDismissed: json['isDismissed'] ?? false,
      data: json['data'],
      actions: json['actions'] != null
          ? (json['actions'] as List)
                .map((a) => NotificationAction.fromJson(a))
                .toList()
          : null,
    );
  }

  AppNotification copyWith({
    String? id,
    NotificationType? type,
    NotificationPriority? priority,
    String? title,
    String? message,
    DateTime? createdAt,
    bool? isRead,
    bool? isDismissed,
    Map<String, dynamic>? data,
    List<NotificationAction>? actions,
  }) {
    return AppNotification(
      id: id ?? this.id,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      title: title ?? this.title,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      isDismissed: isDismissed ?? this.isDismissed,
      data: data ?? this.data,
      actions: actions ?? this.actions,
    );
  }

  IconData getIcon() {
    switch (type) {
      case NotificationType.system:
        return Icons.info;
      case NotificationType.general:
        return Icons.notifications;
      case NotificationType.dailySummary:
      case NotificationType.weeklySummary:
      case NotificationType.monthlySummary:
        return Icons.summarize;
      case NotificationType.billReminder:
        return Icons.receipt;
      case NotificationType.installmentReminder:
        return Icons.credit_card;
      case NotificationType.paymentDue:
        return Icons.payment;
      case NotificationType.recurringDue:
        return Icons.repeat;
      case NotificationType.goalAchieved:
        return Icons.emoji_events;
      case NotificationType.savingsSuggestion:
        return Icons.lightbulb;
      case NotificationType.kmhLimitWarning:
      case NotificationType.kmhLimitCritical:
        return Icons.warning;
      case NotificationType.kmhInterestAccrued:
        return Icons.account_balance;
      // Security notification icons
      case NotificationType.securityFailedLogin:
        return Icons.security;
      case NotificationType.securityNewDevice:
        return Icons.devices;
      case NotificationType.securitySettingsChange:
        return Icons.settings_applications;
      case NotificationType.securitySuspiciousActivity:
        return Icons.warning_amber;
      case NotificationType.securityAccountLocked:
        return Icons.lock;
    }
  }

  Color getColor() {
    switch (type) {
      case NotificationType.system:
        return Colors.blue;
      case NotificationType.general:
        return Colors.blue;
      case NotificationType.dailySummary:
      case NotificationType.weeklySummary:
      case NotificationType.monthlySummary:
        return Colors.blue;
      case NotificationType.billReminder:
        return Colors.indigo;
      case NotificationType.installmentReminder:
        return Colors.purple;
      case NotificationType.paymentDue:
        return Colors.red;
      case NotificationType.recurringDue:
        return Colors.purple;
      case NotificationType.goalAchieved:
        return Colors.green;
      case NotificationType.savingsSuggestion:
        return Colors.amber;
      case NotificationType.kmhLimitWarning:
        return Colors.orange;
      case NotificationType.kmhLimitCritical:
        return Colors.red;
      case NotificationType.kmhInterestAccrued:
        return Colors.blue;
      // Security notification colors
      case NotificationType.securityFailedLogin:
        return Colors.orange;
      case NotificationType.securityNewDevice:
        return Colors.blue;
      case NotificationType.securitySettingsChange:
        return Colors.teal;
      case NotificationType.securitySuspiciousActivity:
        return Colors.red;
      case NotificationType.securityAccountLocked:
        return Colors.red;
    }
  }
}
