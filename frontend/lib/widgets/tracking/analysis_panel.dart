import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../models/stress_data_source.dart';

class AnalysisPanel extends StatelessWidget {
  final StressReading? reading;
  final bool isExpanded;
  final VoidCallback onToggle;

  const AnalysisPanel({
    super.key,
    required this.reading,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _AnalysisHeader(isExpanded: isExpanded, onToggle: onToggle),
        if (isExpanded) _AnalysisContent(reading: reading),
      ],
    );
  }
}

class _AnalysisHeader extends StatelessWidget {
  final bool isExpanded;
  final VoidCallback onToggle;

  const _AnalysisHeader({required this.isExpanded, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: isExpanded
              ? const BorderRadius.vertical(top: Radius.circular(12))
              : AppRadius.lgBorder,
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: AppColors.primary, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Why is this detected?',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            AnimatedRotation(
              turns: isExpanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.keyboard_arrow_down,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalysisContent extends StatelessWidget {
  final StressReading? reading;

  const _AnalysisContent({required this.reading});

  @override
  Widget build(BuildContext context) {
    final hasHRV = reading?.hrv != null;
    final hasHR = reading?.heartRate != null;
    final hasRR = reading?.respiratoryRate != null;
    final hasEEG =
        reading?.eegStressIndex != null || reading?.emotivStressDirect != null;

    if (!hasHRV && !hasHR && !hasRR && !hasEEG) {
      return _noDataContent();
    }

    final double totalWeight =
        (hasHRV ? 0.45 : 0) +
        (hasHR ? 0.30 : 0) +
        (hasRR ? 0.15 : 0) +
        (hasEEG ? 0.10 : 0);

    int pct(double w) => totalWeight > 0 ? (w / totalWeight * 100).round() : 0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
        border: Border(
          left: BorderSide(color: AppColors.border),
          right: BorderSide(color: AppColors.border),
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Biomarkers used by the ML model:',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (hasHRV) ...[
            _FactorRow(
              icon: Icons.show_chart,
              iconColor: const Color(0xFFE89B9B),
              label: 'HRV  •  ${reading!.hrv!.toStringAsFixed(1)} ms',
              percentage: pct(0.45),
              description: reading!.hrv! < 25
                  ? 'Low variability — sympathetic activation likely.'
                  : 'Healthy variability — good parasympathetic activity.',
            ),
            if (hasHR || hasRR || hasEEG) const SizedBox(height: AppSpacing.lg),
          ],
          if (hasHR) ...[
            _FactorRow(
              icon: Icons.favorite_outline,
              iconColor: const Color(0xFFE89B9B),
              label:
                  'Heart Rate  •  ${reading!.heartRate!.toStringAsFixed(0)} bpm',
              percentage: pct(0.30),
              description: reading!.heartRate! >= 85
                  ? 'Elevated — may indicate physical or emotional stress.'
                  : reading!.heartRate! >= 75
                  ? 'Slightly above resting baseline.'
                  : 'Within normal resting range.',
            ),
            if (hasRR || hasEEG) const SizedBox(height: AppSpacing.lg),
          ],
          if (hasRR) ...[
            _FactorRow(
              icon: Icons.air,
              iconColor: AppColors.primary,
              label:
                  'Respiratory Rate  •  ${reading!.respiratoryRate!.toStringAsFixed(1)} br/min',
              percentage: pct(0.15),
              description: reading!.respiratoryRate! > 20
                  ? 'Elevated breathing rate observed.'
                  : 'Within normal range.',
            ),
            if (hasEEG) const SizedBox(height: AppSpacing.lg),
          ],
          if (hasEEG)
            _FactorRow(
              icon: Icons.psychology,
              iconColor: const Color(0xFFB4A7D6),
              label: 'EEG Patterns (EMOTIV)',
              percentage: pct(0.10),
              description: (reading?.emotivStressDirect ?? 0) > 0.6
                  ? 'Beta wave dominance — cognitive load detected.'
                  : 'EEG indicates moderate engagement.',
            ),
        ],
      ),
    );
  }

  Widget _noDataContent() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
        border: Border(
          left: BorderSide(color: AppColors.border),
          right: BorderSide(color: AppColors.border),
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: Text(
        'No sensor data available yet. Connect your Garmin watch or EMOTIV headset to see a breakdown.',
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.textSecondary,
          height: 1.5,
        ),
      ),
    );
  }
}

class _FactorRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final int percentage;
  final String description;

  const _FactorRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.percentage,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              '$percentage%',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Stack(
          children: [
            Container(
              height: 6,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            LayoutBuilder(
              builder: (context, constraints) => Container(
                height: 6,
                width: constraints.maxWidth * (percentage / 100),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          description,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
