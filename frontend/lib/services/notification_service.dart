import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/notification_preferences_model.dart';
import '../network/api_client.dart';

class NotificationService {
  final ApiClient _apiClient = ApiClient();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // ==================== FCM Setup ====================

  /// Initialize Firebase Cloud Messaging
  Future<void> initializeFCM() async {
    // Request permission
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    debugPrint('🔔 FCM Permission: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      // Get FCM token
      final token = await _messaging.getToken();
      if (token != null) {
        debugPrint('🔔 FCM Token: ${token.substring(0, 20)}...');
        await registerDevice(token);
      }

      // Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) async {
        debugPrint('🔔 FCM Token refreshed');
        await registerDevice(newToken);
      });
    }
  }

  /// Register device with backend
  Future<void> registerDevice(String fcmToken) async {
    try {
      final platform = Platform.isAndroid ? 'android' : 'ios';

      final response = await _apiClient.post(
        '/notifications/devices/register',
        body: jsonEncode({'platform': platform, 'fcm_token': fcmToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('✅ Device registered: ${data['device_id']}');
      } else {
        debugPrint('❌ Failed to register device: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Error registering device: $e');
    }
  }

  // ==================== Preferences ====================

  /// Get notification preferences from backend
  Future<NotificationPreferences> getPreferences() async {
    try {
      final response = await _apiClient.get('/notifications/preferences');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return NotificationPreferences.fromJson(data);
      } else {
        debugPrint('❌ Failed to get preferences: ${response.body}');
        return const NotificationPreferences(); // Return defaults
      }
    } catch (e) {
      debugPrint('❌ Error getting preferences: $e');
      return const NotificationPreferences();
    }
  }

  /// Update notification preferences
  Future<NotificationPreferences> updatePreferences({
    bool? enabled,
    dynamic maxPerDay,
    QuietHours? quietHours,
    bool? stressAlerts,
    bool? dailyReminders,
    bool? goalReminders,
    bool? streakReminders,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (enabled != null) body['enabled'] = enabled;
      if (maxPerDay != null) body['max_per_day'] = maxPerDay;
      if (quietHours != null) body['quiet_hours'] = quietHours.toJson();
      if (stressAlerts != null) body['stress_alerts'] = stressAlerts;
      if (dailyReminders != null) body['daily_reminders'] = dailyReminders;
      if (goalReminders != null) body['goal_reminders'] = goalReminders;
      if (streakReminders != null) body['streak_reminders'] = streakReminders;

      final response = await _apiClient.put(
        '/notifications/preferences',
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return NotificationPreferences.fromJson(data);
      } else {
        debugPrint('❌ Failed to update preferences: ${response.body}');
        throw Exception('Failed to update preferences');
      }
    } catch (e) {
      debugPrint('❌ Error updating preferences: $e');
      rethrow;
    }
  }

  /// Update quiet hours only
  Future<NotificationPreferences> updateQuietHours(
    QuietHours quietHours,
  ) async {
    try {
      final response = await _apiClient.put(
        '/notifications/preferences/quiet-hours',
        body: quietHours.toJson(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return NotificationPreferences.fromJson(data);
      } else {
        debugPrint('❌ Failed to update quiet hours: ${response.body}');
        throw Exception('Failed to update quiet hours');
      }
    } catch (e) {
      debugPrint('❌ Error updating quiet hours: $e');
      rethrow;
    }
  }

  /// Toggle all notifications on/off
  Future<bool> toggleNotifications(bool enabled) async {
    try {
      final response = await _apiClient.post(
        '/notifications/preferences/toggle',
        body: {'enabled': enabled},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['enabled'] ?? enabled;
      } else {
        debugPrint('❌ Failed to toggle notifications: ${response.body}');
        return !enabled; // Return opposite on failure
      }
    } catch (e) {
      debugPrint('❌ Error toggling notifications: $e');
      return !enabled;
    }
  }

  // ==================== Device Management ====================

  /// Get list of registered devices
  Future<List<RegisteredDevice>> getDevices() async {
    try {
      final response = await _apiClient.get('/notifications/devices');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final devicesList = data['devices'] as List;
        return devicesList.map((d) => RegisteredDevice.fromJson(d)).toList();
      } else {
        debugPrint('❌ Failed to get devices: ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('❌ Error getting devices: $e');
      return [];
    }
  }

  /// Unregister a device
  Future<bool> unregisterDevice(String deviceId) async {
    try {
      final response = await _apiClient.delete(
        '/notifications/devices/$deviceId',
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ Error unregistering device: $e');
      return false;
    }
  }

  // ==================== Status Check ====================

  /// Check if notifications can be sent right now
  Future<Map<String, dynamic>> checkCanNotify({
    String type = 'daily_reminder',
  }) async {
    try {
      final response = await _apiClient.get(
        '/notifications/can-notify?notification_type=$type',
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'can_notify': false, 'reason': 'api_error'};
      }
    } catch (e) {
      debugPrint('❌ Error checking notification status: $e');
      return {'can_notify': false, 'reason': 'error'};
    }
  }

  // ==================== Test ====================

  /// Send a test notification
  Future<bool> sendTestNotification({
    String type = 'daily_reminder',
    String title = 'Test Notification',
    String body = 'This is a test notification from your app.',
  }) async {
    try {
      final response = await _apiClient.post(
        '/notifications/send-test',
        body: {'type': type, 'title': title, 'body': body},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['sent'] ?? false;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Error sending test notification: $e');
      return false;
    }
  }
}
