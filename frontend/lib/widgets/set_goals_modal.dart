import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../models/goal_model.dart';

class SetGoalsModal extends StatefulWidget {
  final List<String> initialSelectedGoals;
  final int maxGoals;

  const SetGoalsModal({
    super.key,
    this.initialSelectedGoals = const [],
    this.maxGoals = 2,
  });

  /// Show the modal and return selected goal IDs
  static Future<List<String>?> show(
    BuildContext context, {
    List<String> initialSelectedGoals = const [],
    int maxGoals = 2,
  }) {
    return showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SetGoalsModal(
        initialSelectedGoals: initialSelectedGoals,
        maxGoals: maxGoals,
      ),
    );
  }

  @override
  State<SetGoalsModal> createState() => _SetGoalsModalState();
}

class _SetGoalsModalState extends State<SetGoalsModal> {
  late Set<String> _selectedGoalIds;

  @override
  void initState() {
    super.initState();
    _selectedGoalIds = Set.from(widget.initialSelectedGoals);
  }

  void _toggleGoal(String goalId) {
    setState(() {
      if (_selectedGoalIds.contains(goalId)) {
        _selectedGoalIds.remove(goalId);
      } else if (_selectedGoalIds.length < widget.maxGoals) {
        _selectedGoalIds.add(goalId);
      }
    });
  }

  void _saveGoals() {
    if (_selectedGoalIds.length == widget.maxGoals) {
      Navigator.pop(context, _selectedGoalIds.toList());
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: const EdgeInsets.only(top: 80),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Set Your Daily Goals', style: AppTextStyles.h3),
                    const SizedBox(height: 4),
                    Text(
                      'Choose ${widget.maxGoals} goals to focus on today',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: const Icon(
                      Icons.close,
                      color: AppColors.textSecondary,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Goals list
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                bottom: bottomPadding + AppSpacing.lg,
              ),
              child: Column(
                children: [
                  ...AvailableGoals.all.map(
                    (goal) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _GoalOptionTile(
                        goal: goal,
                        isSelected: _selectedGoalIds.contains(goal.id),
                        onTap: () => _toggleGoal(goal.id),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // Status text
                  Text(
                    _selectedGoalIds.length == widget.maxGoals
                        ? 'Perfect! Ready to save your goals'
                        : 'Select ${widget.maxGoals} goals to get started',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _selectedGoalIds.length == widget.maxGoals
                          ? _saveGoals
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _selectedGoalIds.length == widget.maxGoals
                            ? AppColors.primary
                            : AppColors.border,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.mdBorder,
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Save Goals',
                        style: AppTextStyles.button.copyWith(
                          color: _selectedGoalIds.length == widget.maxGoals
                              ? Colors.white
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalOptionTile extends StatelessWidget {
  final GoalOption goal;
  final bool isSelected;
  final VoidCallback onTap;

  const _GoalOptionTile({
    required this.goal,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.05)
              : AppColors.background,
          borderRadius: AppRadius.mdBorder,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Icon container
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: goal.iconColor.withValues(alpha: 0.1),
                borderRadius: AppRadius.smBorder,
              ),
              child: Icon(goal.icon, color: goal.iconColor, size: 24),
            ),

            const SizedBox(width: AppSpacing.md),

            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    goal.title,
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    goal.description,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Checkbox
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
