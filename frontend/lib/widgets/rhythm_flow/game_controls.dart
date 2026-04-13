import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../screens/rhythm_flow_screen.dart';

class GameControls extends StatelessWidget {
  final bool isPlaying;
  final RhythmStressLevel stressLevel;
  final VoidCallback onStart;
  final VoidCallback onPause;

  const GameControls({
    super.key,
    required this.isPlaying,
    required this.stressLevel,
    required this.onStart,
    required this.onPause,
  });

  @override
  Widget build(BuildContext context) {
    if (isPlaying) {
      return _PauseButton(onPause: onPause);
    }

    return Column(
      children: [
        Text(
          'Tap the glowing button to match the rhythm',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '${stressLevel.bpm} BPM • ${stressLevel.tempoLabel}',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint),
        ),
        const SizedBox(height: AppSpacing.lg),
        _StartButton(onStart: onStart),
      ],
    );
  }
}

class _StartButton extends StatelessWidget {
  final VoidCallback onStart;

  const _StartButton({required this.onStart});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onStart,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: AppRadius.lgBorder,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.play_arrow, color: Colors.white, size: 24),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Start Flow',
              style: AppTextStyles.button.copyWith(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}

class _PauseButton extends StatelessWidget {
  final VoidCallback onPause;

  const _PauseButton({required this.onPause});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPause,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: AppRadius.mdBorder,
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.pause, color: AppColors.textPrimary, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Pause',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GameInstructions extends StatelessWidget {
  final RhythmStressLevel stressLevel;

  const GameInstructions({super.key, required this.stressLevel});

  @override
  Widget build(BuildContext context) {
    String extraInfo = '';
    if (stressLevel == RhythmStressLevel.high) {
      extraInfo = ' • Double points for calm focus';
    } else if (stressLevel == RhythmStressLevel.low) {
      extraInfo = ' • Build streaks for bonuses';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        children: [
          Text(
            'Follow the gentle rhythm. Let it guide you.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Tempo adapts to your stress level$extraInfo',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textHint,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
