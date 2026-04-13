import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../screens/rhythm_flow_screen.dart';

class RhythmAppBar extends StatelessWidget {
  final int score;
  final int streak;
  final RhythmStressLevel stressLevel;
  final bool isMusicEnabled;
  final VoidCallback onBack;
  final VoidCallback onMusicToggle;
  final VoidCallback onReset;

  const RhythmAppBar({
    super.key,
    required this.score,
    required this.streak,
    required this.stressLevel,
    required this.isMusicEnabled,
    required this.onBack,
    required this.onMusicToggle,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _BackButton(onTap: onBack),
          _TitleScore(
            score: score,
            streak: streak,
            stressLevel: stressLevel,
          ),
          _ActionButtons(
            isMusicEnabled: isMusicEnabled,
            onMusicToggle: onMusicToggle,
            onReset: onReset,
          ),
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  final VoidCallback onTap;

  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: AppColors.background,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.arrow_back,
          color: AppColors.textPrimary,
          size: 20,
        ),
      ),
    );
  }
}

class _TitleScore extends StatelessWidget {
  final int score;
  final int streak;
  final RhythmStressLevel stressLevel;

  const _TitleScore({
    required this.score,
    required this.streak,
    required this.stressLevel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Rhythm Flow',
          style: AppTextStyles.h4.copyWith(fontSize: 18),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Score: $score',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            if (stressLevel == RhythmStressLevel.low && streak > 0) ...[
              const SizedBox(width: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bolt, size: 14, color: const Color(0xFF7BC67E)),
                  const SizedBox(width: 2),
                  Text(
                    '$streak streak',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: const Color(0xFF7BC67E),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final bool isMusicEnabled;
  final VoidCallback onMusicToggle;
  final VoidCallback onReset;

  const _ActionButtons({
    required this.isMusicEnabled,
    required this.onMusicToggle,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onMusicToggle,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isMusicEnabled
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isMusicEnabled ? Icons.music_note : Icons.music_off,
              color: isMusicEnabled ? AppColors.primary : AppColors.textHint,
              size: 18,
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onReset,
          child: Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: AppColors.background,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.refresh,
              color: AppColors.textPrimary,
              size: 18,
            ),
          ),
        ),
      ],
    );
  }
}
