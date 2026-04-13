import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../models/goal_model.dart';
import 'goal_item.dart';

class TodaysGoalsSection extends StatelessWidget {
  final List<UserGoal> dailyGoals;
  final Function(UserGoal) onGoalTap;
  final VoidCallback onSetGoalsTap;
  final VoidCallback onBreathingTap;
  final VoidCallback onTrackingTap;

  const TodaysGoalsSection({
    super.key,
    required this.dailyGoals,
    required this.onGoalTap,
    required this.onSetGoalsTap,
    required this.onBreathingTap,
    required this.onTrackingTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.track_changes,
                    color: AppColors.primary,
                    size: 14,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  "Today's Goals",
                  style: AppTextStyles.h4.copyWith(fontSize: 16),
                ),
              ],
            ),
            TextButton(
              onPressed: onSetGoalsTap,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Change Goals',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (dailyGoals.isEmpty) ...[
          DefaultGoalItem(
            icon: Icons.air,
            title: 'Practice Breathing',
            iconColor: AppColors.primary,
            onTap: onBreathingTap,
          ),
          const SizedBox(height: AppSpacing.sm),
          DefaultGoalItem(
            icon: Icons.show_chart,
            title: 'Check Stress Levels',
            iconColor: AppColors.warning,
            onTap: onTrackingTap,
          ),
        ] else
          ...dailyGoals.asMap().entries.map((entry) {
            final index = entry.key;
            final goal = entry.value;
            return Padding(
              padding: EdgeInsets.only(
                bottom: index < dailyGoals.length - 1 ? AppSpacing.sm : 0,
              ),
              child: GoalItem(goal: goal, onTap: () => onGoalTap(goal)),
            );
          }),
      ],
    );
  }
}
