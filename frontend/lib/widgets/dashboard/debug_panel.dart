import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';

class DebugPanel extends StatelessWidget {
  final VoidCallback onTestML;
  final VoidCallback onTestNotification;
  final VoidCallback onTestDeviceFeedback;

  const DebugPanel({
    super.key,
    required this.onTestML,
    required this.onTestNotification,
    required this.onTestDeviceFeedback,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "You're doing great today! ",
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.stressLow,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Text('🌱', style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _MLTestCard(onTest: onTestML),
        _NotificationTestCard(
          onTestNotification: onTestNotification,
          onTestDeviceFeedback: onTestDeviceFeedback,
        ),
      ],
    );
  }
}

class _MLTestCard extends StatelessWidget {
  final VoidCallback onTest;

  const _MLTestCard({required this.onTest});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F0),
        borderRadius: AppRadius.mdBorder,
        border: Border.all(color: const Color(0xFFFFCCCC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bug_report, color: Colors.red[400], size: 18),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Debug: ML Model Test',
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.red[400],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onTest,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B9BD1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Test Stress Prediction'),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationTestCard extends StatelessWidget {
  final VoidCallback onTestNotification;
  final VoidCallback onTestDeviceFeedback;

  const _NotificationTestCard({
    required this.onTestNotification,
    required this.onTestDeviceFeedback,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: AppRadius.smBorder,
      ),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onTestNotification,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Test Headset Notification'),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onTestDeviceFeedback,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Test Device Feedback'),
            ),
          ),
        ],
      ),
    );
  }
}
