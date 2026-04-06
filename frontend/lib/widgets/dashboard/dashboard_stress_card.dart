import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../models/stress_data_source.dart';
import '../stress_gauge.dart';

class DashboardStressCard extends StatelessWidget {
  final StressReading? reading;
  final GaugeDataState gaugeState;
  final String trendLabel;

  const DashboardStressCard({
    super.key,
    required this.reading,
    required this.gaugeState,
    required this.trendLabel,
  });

  @override
  Widget build(BuildContext context) {
    final confidence = reading?.confidence ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: AppRadius.lgBorder,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [Text('Current Stress Level', style: AppTextStyles.h4)],
          ),
          const SizedBox(height: AppSpacing.lg),
          StressGauge(
            level: reading?.stressLevel,
            maxLevel: 100,
            dataState: gaugeState,
            dataSourceLabel: reading?.source.label,
          ),
          const SizedBox(height: AppSpacing.lg),
          if (gaugeState == GaugeDataState.hasData) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'AI Confidence',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  '$confidence%',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: AppRadius.smBorder,
              child: LinearProgressIndicator(
                value: confidence / 100,
                minHeight: 8,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation<Color>(
                  confidence > 70
                      ? AppColors.stressLow
                      : confidence > 30
                      ? AppColors.stressMedium
                      : AppColors.stressHigh,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Icon(Icons.trending_down, color: AppColors.stressLow, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  trendLabel,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
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
