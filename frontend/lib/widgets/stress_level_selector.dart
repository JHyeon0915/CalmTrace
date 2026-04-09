import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../screens/rhythm_flow_screen.dart';

class StressLevelSelector extends StatelessWidget {
  final RhythmStressLevel selected;
  final ValueChanged<RhythmStressLevel> onChanged;

  const StressLevelSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: AppRadius.lgBorder,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.monitor_heart_outlined,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'STRESS LEVEL (TEST MODE)',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: RhythmStressLevel.values.map((level) {
              final isSelected = selected == level;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right:
                        level != RhythmStressLevel.low ? AppSpacing.sm : 0,
                  ),
                  child: GestureDetector(
                    onTap: () => onChanged(level),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.sm + 2,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? level.color : AppColors.surface,
                        borderRadius: AppRadius.smBorder,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: level.color.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          level.label,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: isSelected
                                ? Colors.white
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Adaptive Tempo:',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                selected.description,
                style: AppTextStyles.bodySmall.copyWith(
                  color: selected.color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
