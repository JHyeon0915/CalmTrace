import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';

class GentleRemindersSection extends StatelessWidget {
  final bool enabled;
  final int frequency;
  final bool isUnlimited;
  final ValueChanged<bool> onEnabledChanged;
  final ValueChanged<int> onFrequencyChanged;
  final VoidCallback onUnlimitedToggle;

  const GentleRemindersSection({
    super.key,
    required this.enabled,
    required this.frequency,
    required this.isUnlimited,
    required this.onEnabledChanged,
    required this.onFrequencyChanged,
    required this.onUnlimitedToggle,
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
          _RemindersHeader(enabled: enabled, onChanged: onEnabledChanged),
          if (enabled) ...[
            const SizedBox(height: AppSpacing.lg),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.lg),
            _FrequencySection(
              frequency: frequency,
              isUnlimited: isUnlimited,
              onFrequencyChanged: onFrequencyChanged,
              onUnlimitedToggle: onUnlimitedToggle,
            ),
          ],
        ],
      ),
    );
  }
}

class _RemindersHeader extends StatelessWidget {
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _RemindersHeader({required this.enabled, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF6B9BD1).withValues(alpha: 0.15),
            borderRadius: AppRadius.smBorder,
          ),
          child: const Icon(
            Icons.notifications_outlined,
            color: Color(0xFF6B9BD1),
            size: 20,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Gentle Reminders',
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Prompts to check in and practice self-care',
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
          activeColor: const Color(0xFF6B9BD1),
          inactiveTrackColor: AppColors.surfaceGray,
          inactiveThumbColor: AppColors.background,
        ),
      ],
    );
  }
}

class _FrequencySection extends StatelessWidget {
  final int frequency;
  final bool isUnlimited;
  final ValueChanged<int> onFrequencyChanged;
  final VoidCallback onUnlimitedToggle;

  const _FrequencySection({
    required this.frequency,
    required this.isUnlimited,
    required this.onFrequencyChanged,
    required this.onUnlimitedToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Daily Frequency',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              isUnlimited ? 'Unlimited' : '$frequency per day',
              style: AppTextStyles.bodyMedium.copyWith(
                color: const Color(0xFF6B9BD1),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: const Color(0xFF6B9BD1),
            inactiveTrackColor: AppColors.border,
            thumbColor: const Color(0xFF6B9BD1),
            overlayColor: const Color(0xFF6B9BD1).withValues(alpha: 0.2),
            trackHeight: 6,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
          ),
          child: Slider(
            value: isUnlimited ? 20 : frequency.toDouble(),
            min: 1,
            max: 20,
            divisions: 19,
            onChanged: isUnlimited
                ? null
                : (value) => onFrequencyChanged(value.round()),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['1', '10', '20']
                .map(
                  (label) => Text(
                    label,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textHint,
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        GestureDetector(
          onTap: onUnlimitedToggle,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            decoration: BoxDecoration(
              color: isUnlimited
                  ? const Color(0xFF6B9BD1)
                  : AppColors.surface,
              borderRadius: AppRadius.mdBorder,
              border: Border.all(
                color: isUnlimited
                    ? const Color(0xFF6B9BD1)
                    : AppColors.border,
              ),
            ),
            child: Text(
              isUnlimited ? '✓ Unlimited (as needed)' : 'Set to Unlimited',
              style: AppTextStyles.bodyMedium.copyWith(
                color: isUnlimited ? Colors.white : AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}
