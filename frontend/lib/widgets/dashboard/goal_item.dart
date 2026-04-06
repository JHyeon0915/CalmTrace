import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../models/goal_model.dart';

class GoalItem extends StatelessWidget {
  final UserGoal goal;
  final VoidCallback onTap;

  const GoalItem({super.key, required this.goal, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final goalOption = goal.goalOption;
    final icon = goalOption?.icon ?? Icons.check_circle_outline;
    final iconColor = goalOption?.iconColor ?? AppColors.primary;
    final title = goalOption?.title ?? goal.title;

    return GestureDetector(
      onTap: goal.isCompleted ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: goal.isCompleted
              ? AppColors.success.withValues(alpha: 0.05)
              : AppColors.background,
          borderRadius: AppRadius.mdBorder,
          border: Border.all(
            color: goal.isCompleted ? AppColors.success : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: goal.isCompleted
                    ? AppColors.success.withValues(alpha: 0.1)
                    : iconColor.withValues(alpha: 0.1),
                borderRadius: AppRadius.smBorder,
              ),
              child: Icon(
                goal.isCompleted ? Icons.check : icon,
                color: goal.isCompleted ? AppColors.success : iconColor,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w500,
                      decoration: goal.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                      color: goal.isCompleted
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                    ),
                  ),
                  if (goal.isCompleted)
                    Text(
                      'Completed',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.success,
                      ),
                    ),
                ],
              ),
            ),
            if (!goal.isCompleted)
              const Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

class DefaultGoalItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color iconColor;
  final VoidCallback? onTap;

  const DefaultGoalItem({
    super.key,
    required this.icon,
    required this.title,
    required this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: AppRadius.mdBorder,
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: AppRadius.smBorder,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (onTap != null)
              const Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
