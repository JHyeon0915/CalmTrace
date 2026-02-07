import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/services/device_feedback_service.dart';

void main() {
  // Set up SharedPreferences mock before each test
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('DeviceFeedbackService', () {
    test('default feedback type should be vibration', () async {
      final service = DeviceFeedbackService();
      final type = await service.getFeedbackType();
      expect(type, DeviceFeedbackType.vibration);
    });

    test('should save and load vibration type', () async {
      final service = DeviceFeedbackService();
      await service.setFeedbackType(DeviceFeedbackType.vibration);
      final type = await service.getFeedbackType();
      expect(type, DeviceFeedbackType.vibration);
    });

    test('should save and load ring type', () async {
      final service = DeviceFeedbackService();
      await service.setFeedbackType(DeviceFeedbackType.ring);
      final type = await service.getFeedbackType();
      expect(type, DeviceFeedbackType.ring);
    });

    test('should save and load notification type', () async {
      final service = DeviceFeedbackService();
      await service.setFeedbackType(DeviceFeedbackType.notification);
      final type = await service.getFeedbackType();
      expect(type, DeviceFeedbackType.notification);
    });

    test('should save and load none type', () async {
      final service = DeviceFeedbackService();
      await service.setFeedbackType(DeviceFeedbackType.none);
      final type = await service.getFeedbackType();
      expect(type, DeviceFeedbackType.none);
    });

    test('should persist across multiple service instances', () async {
      final service1 = DeviceFeedbackService();
      await service1.setFeedbackType(DeviceFeedbackType.ring);

      // Create new instance (simulating app restart)
      final service2 = DeviceFeedbackService();
      final type = await service2.getFeedbackType();
      expect(type, DeviceFeedbackType.ring);
    });
  });

  group('DeviceFeedbackType extension', () {
    test('vibration should have correct properties', () {
      const type = DeviceFeedbackType.vibration;
      expect(type.title, 'Vibration');
      expect(type.subtitle, 'Haptic feedback only');
      expect(type.icon, Icons.vibration);
    });

    test('ring should have correct properties', () {
      const type = DeviceFeedbackType.ring;
      expect(type.title, 'Ring');
      expect(type.subtitle, 'Sound notification');
      expect(type.icon, Icons.volume_up_outlined);
    });

    test('notification should have correct properties', () {
      const type = DeviceFeedbackType.notification;
      expect(type.title, 'Notification');
      expect(type.subtitle, 'Visual banner');
      expect(type.icon, Icons.notifications_outlined);
    });

    test('none should have correct properties', () {
      const type = DeviceFeedbackType.none;
      expect(type.title, 'None');
      expect(type.subtitle, 'Silent mode');
      expect(type.icon, Icons.notifications_off_outlined);
    });

    test(
      'all types should have confirmation messages mentioning "is connected"',
      () {
        for (final type in DeviceFeedbackType.values) {
          expect(
            type.confirmationMessage.contains('is connected'),
            isTrue,
            reason: '${type.title} should mention "is connected"',
          );
        }
      },
    );

    test('all types should have non-empty titles', () {
      for (final type in DeviceFeedbackType.values) {
        expect(type.title.isNotEmpty, isTrue);
      }
    });

    test('all types should have non-empty subtitles', () {
      for (final type in DeviceFeedbackType.values) {
        expect(type.subtitle.isNotEmpty, isTrue);
      }
    });

    test('all types should have valid icons', () {
      for (final type in DeviceFeedbackType.values) {
        expect(type.icon, isNotNull);
      }
    });
  });

  group('DeviceFeedbackType enum', () {
    test('should have exactly 4 types', () {
      expect(DeviceFeedbackType.values.length, 4);
    });

    test('should have correct order', () {
      expect(DeviceFeedbackType.values[0], DeviceFeedbackType.vibration);
      expect(DeviceFeedbackType.values[1], DeviceFeedbackType.ring);
      expect(DeviceFeedbackType.values[2], DeviceFeedbackType.notification);
      expect(DeviceFeedbackType.values[3], DeviceFeedbackType.none);
    });

    test('vibration should have index 0', () {
      expect(DeviceFeedbackType.vibration.index, 0);
    });

    test('ring should have index 1', () {
      expect(DeviceFeedbackType.ring.index, 1);
    });

    test('notification should have index 2', () {
      expect(DeviceFeedbackType.notification.index, 2);
    });

    test('none should have index 3', () {
      expect(DeviceFeedbackType.none.index, 3);
    });
  });
}
