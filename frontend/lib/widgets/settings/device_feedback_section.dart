import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../services/device_feedback_service.dart';

class DeviceFeedbackSection extends StatelessWidget {
  final DeviceFeedbackType selectedFeedback;
  final ValueChanged<DeviceFeedbackType> onFeedbackTap;

  const DeviceFeedbackSection({
    super.key,
    required this.selectedFeedback,
    required this.onFeedbackTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: AppRadius.lgBorder,
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(),
          const SizedBox(height: AppSpacing.lg),
          _FeedbackGrid(
            selectedFeedback: selectedFeedback,
            onFeedbackTap: onFeedbackTap,
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.textGreen.withValues(alpha: 0.2),
            borderRadius: AppRadius.smBorder,
          ),
          child: Icon(
            Icons.smartphone_outlined,
            color: AppColors.textGreen,
            size: 20,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Device Feedback',
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'When Emotiv headset or smartwatch is connected',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FeedbackGrid extends StatelessWidget {
  final DeviceFeedbackType selectedFeedback;
  final ValueChanged<DeviceFeedbackType> onFeedbackTap;

  const _FeedbackGrid({
    required this.selectedFeedback,
    required this.onFeedbackTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _FeedbackOption(
                type: DeviceFeedbackType.vibration,
                isSelected: selectedFeedback == DeviceFeedbackType.vibration,
                onTap: onFeedbackTap,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _FeedbackOption(
                type: DeviceFeedbackType.ring,
                isSelected: selectedFeedback == DeviceFeedbackType.ring,
                onTap: onFeedbackTap,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _FeedbackOption(
                type: DeviceFeedbackType.notification,
                isSelected:
                    selectedFeedback == DeviceFeedbackType.notification,
                onTap: onFeedbackTap,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _FeedbackOption(
                type: DeviceFeedbackType.none,
                isSelected: selectedFeedback == DeviceFeedbackType.none,
                onTap: onFeedbackTap,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FeedbackOption extends StatelessWidget {
  final DeviceFeedbackType type;
  final bool isSelected;
  final ValueChanged<DeviceFeedbackType> onTap;

  const _FeedbackOption({
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.lg,
          horizontal: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.textGreen.withValues(alpha: 0.05)
              : AppColors.surface,
          borderRadius: AppRadius.mdBorder,
          border: Border.all(
            color: isSelected ? AppColors.textGreen : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.textGreen.withValues(alpha: 0.2)
                    : AppColors.background,
                shape: BoxShape.circle,
              ),
              child: Icon(
                type.icon,
                color: isSelected
                    ? AppColors.textGreen
                    : AppColors.textSecondary,
                size: 22,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              type.title,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isSelected
                    ? AppColors.textGreen
                    : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              type.subtitle,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textHint,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
