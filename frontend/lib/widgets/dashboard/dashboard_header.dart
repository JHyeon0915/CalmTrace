import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';

class DashboardHeader extends StatelessWidget {
  final String displayName;
  final VoidCallback onSettingsTap;

  const DashboardHeader({
    super.key,
    required this.displayName,
    required this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hi, $displayName', style: AppTextStyles.h2),
            const SizedBox(height: 4),
            Text('Ready to find your calm?', style: AppTextStyles.bodyMedium),
          ],
        ),
        GestureDetector(
          onTap: onSettingsTap,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: AppRadius.smBorder,
            ),
            child: const Icon(
              Icons.settings_outlined,
              color: AppColors.textSecondary,
              size: 22,
            ),
          ),
        ),
      ],
    );
  }
}
