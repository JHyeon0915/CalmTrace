import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../models/stress_data_source.dart';

class NoDataBanner extends StatelessWidget {
  const NoDataBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final msg = PlatformCapabilities.supportsHealthKit
        ? 'Open Apple Health and grant CalmTrace access, or sync your Garmin watch.'
        : PlatformCapabilities.supportsHealthConnect
        ? 'Open Health Connect and grant CalmTrace access, or sync your Garmin watch.'
        : 'Connect your EMOTIV headset via the EMOTIV Cortex app.';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgBorder,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              msg,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
