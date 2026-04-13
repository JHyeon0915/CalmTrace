import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';

class QuietHoursSection extends StatelessWidget {
  final bool enabled;
  final String quietStart;
  final String quietEnd;
  final ValueChanged<bool> onEnabledChanged;
  final VoidCallback onStartTap;
  final VoidCallback onEndTap;

  const QuietHoursSection({
    super.key,
    required this.enabled,
    required this.quietStart,
    required this.quietEnd,
    required this.onEnabledChanged,
    required this.onStartTap,
    required this.onEndTap,
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
          _QuietHoursHeader(enabled: enabled, onChanged: onEnabledChanged),
          if (enabled) ...[
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: _TimeInput(
                    label: 'Start',
                    value: quietStart,
                    onTap: onStartTap,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _TimeInput(
                    label: 'End',
                    value: quietEnd,
                    onTap: onEndTap,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _QuietHoursHeader extends StatelessWidget {
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _QuietHoursHeader({required this.enabled, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFB4A7D6).withValues(alpha: 0.2),
            borderRadius: AppRadius.smBorder,
          ),
          child: const Icon(
            Icons.bedtime_outlined,
            color: Color(0xFFB4A7D6),
            size: 20,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quiet Hours',
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'No notifications during these times',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: enabled,
          onChanged: onChanged,
          trackOutlineColor: WidgetStateProperty.resolveWith<Color?>(
            (_) => Colors.transparent,
          ),
          activeColor: const Color(0xFFB4A7D6),
          inactiveTrackColor: AppColors.surfaceGray,
          inactiveThumbColor: AppColors.background,
        ),
      ],
    );
  }
}

class _TimeInput extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _TimeInput({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: AppRadius.mdBorder,
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              value,
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
