import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../models/stress_data_source.dart';
import '../stress_gauge.dart';

class TrackingStressGaugeCard extends StatelessWidget {
  final StressReading? reading;
  final GaugeDataState gaugeState;
  final String trendLabel;

  const TrackingStressGaugeCard({
    super.key,
    required this.reading,
    required this.gaugeState,
    required this.trendLabel,
  });

  Color _confidenceColor(int confidence) {
    if (confidence > 70) return const Color(0xFF68D391);
    if (confidence > 30) return const Color(0xFFF6B93B);
    return const Color(0xFFE57373);
  }

  @override
  Widget build(BuildContext context) {
    final confidence = reading?.confidence ?? 0;
    final confidenceColor = _confidenceColor(confidence);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: AppRadius.lgBorder,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          StressGauge(
            level: reading?.stressLevel,
            maxLevel: 100,
            dataState: gaugeState,
            dataSourceLabel: reading?.source.label,
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Trend:',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                trendLabel,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          if (gaugeState == GaugeDataState.hasData)
            _ConfidenceMeter(confidence: confidence, color: confidenceColor),
        ],
      ),
    );
  }
}

class _ConfidenceMeter extends StatelessWidget {
  final int confidence;
  final Color color;

  const _ConfidenceMeter({required this.confidence, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
        LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                Container(
                  height: 8,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  height: 8,
                  width: constraints.maxWidth * (confidence / 100),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color.withValues(alpha: 0.7), color],
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
