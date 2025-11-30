import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class ScheduledNotification {
  final String id;
  final int platformId; // Platform-specific notification ID
  final String type; // NotificationType as string
  final DateTime scheduledFor;
  final Map<String, dynamic> data;
  final bool isRecurring;
  final String? repeatInterval; // RepeatInterval as string

  const ScheduledNotification({
    required this.id,
    required this.platformId,
    required this.type,
    required this.scheduledFor,
    required this.data,
    this.isRecurring = false,
    this.repeatInterval,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'platformId': platformId,
        'type': type,
        'scheduledFor': scheduledFor.toIso8601String(),
        'data': data,
        'isRecurring': isRecurring,
        'repeatInterval': repeatInterval,
      };

  factory ScheduledNotification.fromJson(Map<String, dynamic> json) {
    return ScheduledNotification(
      id: json['id'],
      platformId: json['platformId'],
      type: json['type'],
      scheduledFor: DateTime.parse(json['scheduledFor']),
      data: Map<String, dynamic>.from(json['data']),
      isRecurring: json['isRecurring'] ?? false,
      repeatInterval: json['repeatInterval'],
    );
  }

  ScheduledNotification copyWith({
    String? id,
    int? platformId,
    String? type,
    DateTime? scheduledFor,
    Map<String, dynamic>? data,
    bool? isRecurring,
    String? repeatInterval,
  }) {
    return ScheduledNotification(
      id: id ?? this.id,
      platformId: platformId ?? this.platformId,
      type: type ?? this.type,
      scheduledFor: scheduledFor ?? this.scheduledFor,
      data: data ?? this.data,
      isRecurring: isRecurring ?? this.isRecurring,
      repeatInterval: repeatInterval ?? this.repeatInterval,
    );
  }
}
