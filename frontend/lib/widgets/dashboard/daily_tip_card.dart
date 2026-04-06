import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../models/daily_tip_model.dart';

class DailyTipCard extends StatelessWidget {
  final DailyTip tip;

  const DailyTipCard({super.key, required this.tip});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: AppRadius.lgBorder,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF9E5),
                  borderRadius: AppRadius.smBorder,
                ),
                child: Center(
                  child: Text(
                    tip.emoji,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                "Today's Tip",
                style: AppTextStyles.h4.copyWith(fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(tip.description, style: AppTextStyles.bodyMedium),
          const SizedBox(height: AppSpacing.sm),
          RichText(
            text: TextSpan(
              style: AppTextStyles.bodySmall,
              children: [
                TextSpan(
                  text: '${tip.actionPrefix} ',
                  style: TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(
                  text: tip.actionText,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
