import 'package:flutter/material.dart';

/// Quiet hours configuration
class QuietHours {
  final bool enabled;
  final String start; // HH:MM format
  final String end; // HH:MM format

  const QuietHours({
    this.enabled = true,
    this.start = "22:00",
    this.end = "07:00",
  });

  factory QuietHours.fromJson(Map<String, dynamic> json) {
    return QuietHours(
      enabled: json['enabled'] ?? true,
      start: json['start'] ?? "22:00",
      end: json['end'] ?? "07:00",
    );
  }

  Map<String, dynamic> toJson() {
    return {'enabled': enabled, 'start': start, 'end': end};
  }

  QuietHours copyWith({bool? enabled, String? start, String? end}) {
    return QuietHours(
      enabled: enabled ?? this.enabled,
      start: start ?? this.start,
      end: end ?? this.end,
    );
  }

  /// Parse time string to TimeOfDay
  TimeOfDay get startTime {
    final parts = start.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  TimeOfDay get endTime {
    final parts = end.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  /// Format TimeOfDay to HH:MM string
  static String formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  /// Check if current time is within quiet hours
  bool isCurrentlyQuiet() {
    if (!enabled) return false;

    final now = TimeOfDay.now();
    final nowMinutes = now.hour * 60 + now.minute;
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;

    // Handle overnight quiet hours (e.g., 22:00 - 07:00)
    if (startMinutes > endMinutes) {
      return nowMinutes >= startMinutes || nowMinutes < endMinutes;
    } else {
      return nowMinutes >= startMinutes && nowMinutes < endMinutes;
    }
  }
}

/// Full notification preferences
class NotificationPreferences {
  final bool enabled;
  final dynamic maxPerDay;
  final QuietHours quietHours;
  final bool stressAlerts;
  final bool dailyReminders;
  final bool goalReminders;
  final bool streakReminders;
  final DateTime? updatedAt;

  const NotificationPreferences({
    this.enabled = true,
    this.maxPerDay,
    this.quietHours = const QuietHours(),
    this.stressAlerts = true,
    this.dailyReminders = true,
    this.goalReminders = true,
    this.streakReminders = true,
    this.updatedAt,
  });

  bool get isUnlimited => maxPerDay == "unlimited" || maxPerDay == null;

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      enabled: json['enabled'] ?? true,
      maxPerDay: json['max_per_day'] ?? "unlimited",
      quietHours: json['quiet_hours'] != null
          ? QuietHours.fromJson(json['quiet_hours'])
          : const QuietHours(),
      stressAlerts: json['stress_alerts'] ?? true,
      dailyReminders: json['daily_reminders'] ?? true,
      goalReminders: json['goal_reminders'] ?? true,
      streakReminders: json['streak_reminders'] ?? true,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'max_per_day': maxPerDay,
      'quiet_hours': quietHours.toJson(),
      'stress_alerts': stressAlerts,
      'daily_reminders': dailyReminders,
      'goal_reminders': goalReminders,
      'streak_reminders': streakReminders,
    };
  }

  NotificationPreferences copyWith({
    bool? enabled,
    int? maxPerDay,
    QuietHours? quietHours,
    bool? stressAlerts,
    bool? dailyReminders,
    bool? goalReminders,
    bool? streakReminders,
    DateTime? updatedAt,
  }) {
    return NotificationPreferences(
      enabled: enabled ?? this.enabled,
      maxPerDay: maxPerDay ?? this.maxPerDay,
      quietHours: quietHours ?? this.quietHours,
      stressAlerts: stressAlerts ?? this.stressAlerts,
      dailyReminders: dailyReminders ?? this.dailyReminders,
      goalReminders: goalReminders ?? this.goalReminders,
      streakReminders: streakReminders ?? this.streakReminders,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get count of enabled notification types
  int get enabledTypesCount {
    int count = 0;
    if (stressAlerts) count++;
    if (dailyReminders) count++;
    if (goalReminders) count++;
    if (streakReminders) count++;
    return count;
  }
}

/// Registered device for push notifications
class RegisteredDevice {
  final String deviceId;
  final String platform;
  final DateTime registeredAt;
  final DateTime? lastSeen;

  const RegisteredDevice({
    required this.deviceId,
    required this.platform,
    required this.registeredAt,
    this.lastSeen,
  });

  factory RegisteredDevice.fromJson(Map<String, dynamic> json) {
    return RegisteredDevice(
      deviceId: json['device_id'],
      platform: json['platform'],
      registeredAt: DateTime.parse(json['registered_at']),
      lastSeen: json['last_seen'] != null
          ? DateTime.parse(json['last_seen'])
          : null,
    );
  }
}
