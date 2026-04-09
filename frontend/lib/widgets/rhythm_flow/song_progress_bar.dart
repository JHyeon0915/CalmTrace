import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../screens/rhythm_flow_screen.dart';

class SongProgressBar extends StatelessWidget {
  final Duration position;
  final Duration duration;
  final RhythmStressLevel stressLevel;

  const SongProgressBar({
    super.key,
    required this.position,
    required this.duration,
    required this.stressLevel,
  });

  String _format(Duration d) {
    final mins = d.inMinutes;
    final secs = d.inSeconds % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final progress = duration.inMilliseconds > 0
        ? position.inMilliseconds / duration.inMilliseconds
        : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _format(position),
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Row(
                children: [
                  Icon(
                    Icons.music_note,
                    size: 16,
                    color: stressLevel.color,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    stressLevel.tempoLabel,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: stressLevel.color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Text(
                _format(duration),
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: AppRadius.smBorder,
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(stressLevel.color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}
