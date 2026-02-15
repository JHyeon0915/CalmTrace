import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Device feedback types
enum DeviceFeedbackType { vibration, ring, notification, none }

/// Extension for DeviceFeedbackType to add display properties
extension DeviceFeedbackTypeExtension on DeviceFeedbackType {
  String get title {
    switch (this) {
      case DeviceFeedbackType.vibration:
        return 'Vibration';
      case DeviceFeedbackType.ring:
        return 'Ring';
      case DeviceFeedbackType.notification:
        return 'Notification';
      case DeviceFeedbackType.none:
        return 'None';
    }
  }

  String get subtitle {
    switch (this) {
      case DeviceFeedbackType.vibration:
        return 'Haptic feedback';
      case DeviceFeedbackType.ring:
        return 'Sound notification';
      case DeviceFeedbackType.notification:
        return 'Visual banner';
      case DeviceFeedbackType.none:
        return 'Silent mode';
    }
  }

  IconData get icon {
    switch (this) {
      case DeviceFeedbackType.vibration:
        return Icons.vibration;
      case DeviceFeedbackType.ring:
        return Icons.volume_up_outlined;
      case DeviceFeedbackType.notification:
        return Icons.notifications_outlined;
      case DeviceFeedbackType.none:
        return Icons.notifications_off_outlined;
    }
  }

  String get confirmationMessage {
    switch (this) {
      case DeviceFeedbackType.vibration:
        return 'Switch to haptic feedback only? Your device will vibrate when Emotiv headset or smartwatch is connected.';
      case DeviceFeedbackType.ring:
        return 'Switch to sound notifications? Your device will play a sound when Emotiv headset or smartwatch is connected.';
      case DeviceFeedbackType.notification:
        return 'Switch to visual notifications? A banner will appear when Emotiv headset or smartwatch is connected.';
      case DeviceFeedbackType.none:
        return 'Switch to silent mode? You won\'t receive any feedback when Emotiv headset or smartwatch is connected.';
    }
  }
}

/// Service to manage device feedback settings and trigger feedback
class DeviceFeedbackService {
  static const String _storageKey = 'device_feedback_type';

  /// Get current feedback type from storage
  Future<DeviceFeedbackType> getFeedbackType() async {
    final prefs = await SharedPreferences.getInstance();
    final index =
        prefs.getInt(_storageKey) ?? DeviceFeedbackType.vibration.index;
    return DeviceFeedbackType.values[index];
  }

  /// Save feedback type to storage
  Future<void> setFeedbackType(DeviceFeedbackType type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_storageKey, type.index);
  }

  /// Trigger feedback based on current setting
  /// Call this when device connects
  Future<void> triggerFeedback(BuildContext context) async {
    final type = await getFeedbackType();

    switch (type) {
      case DeviceFeedbackType.vibration:
        await _triggerVibration();
        break;
      case DeviceFeedbackType.ring:
        await _triggerSound();
        break;
      case DeviceFeedbackType.notification:
        if (context.mounted) {
          _showNotificationBanner(context);
        }
        break;
      case DeviceFeedbackType.none:
        // Do nothing
        break;
    }
  }

  /// Trigger vibration feedback
  Future<void> _triggerVibration() async {
    // Check if device supports vibration
    await HapticFeedback.heavyImpact();

    // Double vibration pattern for connection
    await Future.delayed(const Duration(milliseconds: 200));
    await HapticFeedback.mediumImpact();
  }

  /// Trigger sound feedback
  Future<void> _triggerSound() async {
    // Play system sound
    await SystemSound.play(SystemSoundType.alert);
  }

  /// Show notification banner
  void _showNotificationBanner(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.bluetooth_connected, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Device Connected',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  Text(
                    'Emotiv headset is ready',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF68D391),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Test feedback - call this to test the current setting
  Future<void> testFeedback(BuildContext context) async {
    await triggerFeedback(context);
  }
}
