import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import 'calm_puzzle_screen.dart';
import 'mindful_tapping_screen.dart';

class GamesScreen extends StatelessWidget {
  const GamesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.md),

              // Header
              Text('Relaxing Games', style: AppTextStyles.h2),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Short sessions (≤ 5 min)',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // AR Note
              _buildARNote(),

              const SizedBox(height: AppSpacing.lg),

              // Game Cards
              _buildGameCard(
                context,
                title: 'Calm Puzzle',
                description: 'Assemble peaceful landscapes.',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CalmPuzzleScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: AppSpacing.md),

              _buildGameCard(
                context,
                title: 'Mindful Tapping',
                description: 'Rhythmic tapping for focus.',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MindfulTappingScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: AppSpacing.md),

              _buildGameCard(
                context,
                title: 'Rhythm Flow',
                description: 'Match the gentle beat.',
                onTap: () {
                  // TODO: Navigate to Rhythm Flow
                  _showComingSoon(context, 'Rhythm Flow');
                },
              ),

              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildARNote() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: AppRadius.lgBorder,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Note:',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'AR games require camera access. 2D mode is always available.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameCard(
    BuildContext context, {
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: AppRadius.lgBorder,
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            // Left content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2D Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: AppRadius.smBorder,
                    ),
                    child: Text(
                      '2D',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Title
                  Text(
                    title,
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),

                  // Description
                  Text(
                    description,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Game icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.textGreen.withValues(alpha: 0.1),
                borderRadius: AppRadius.mdBorder,
              ),
              child: Icon(
                Icons.videogame_asset_outlined,
                color: AppColors.textGreen,
                size: 28,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String gameName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$gameName coming soon!'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdBorder),
      ),
    );
  }
}
