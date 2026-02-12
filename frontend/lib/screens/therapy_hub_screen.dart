import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import 'cognitive_reframing_screen.dart';
import 'guided_breathing_screen.dart';
import 'mindfulness_screen.dart';

class TherapyHubScreen extends StatelessWidget {
  const TherapyHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final therapies = [
      TherapyItem(
        title: 'Guided Breathing',
        description: 'Regulate your system with paced breathing.',
        time: '1-3 min',
        icon: Icons.air,
        color: const Color(0xFF6B9BD1),
        path: '/therapy/breathing',
      ),
      TherapyItem(
        title: 'Mindfulness',
        description: 'Ground yourself in the present moment.',
        time: '2-5 min',
        icon: Icons.local_florist,
        color: const Color(0xFF8FB996),
        path: '/therapy/mindfulness',
      ),
      TherapyItem(
        title: 'Cognitive Reframing',
        description: 'Challenge negative thought patterns.',
        time: '3-5 min',
        icon: Icons.psychology,
        color: const Color(0xFFE89B9B),
        path: '/therapy/reframing',
      ),
      TherapyItem(
        title: 'AI Stress Coach',
        description: 'Chat with a supportive AI companion.',
        time: '1-5 min',
        icon: Icons.chat_bubble_outline,
        color: const Color(0xFFB4A7D6),
        path: '/therapy/coach',
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.lg),
          Text('Therapy Hub', style: AppTextStyles.h2),
          const SizedBox(height: 4),
          Text('Choose a technique to relax', style: AppTextStyles.bodyMedium),
          const SizedBox(height: AppSpacing.lg),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: AppSpacing.sm,
              mainAxisSpacing: AppSpacing.sm,
              childAspectRatio: 0.75,
            ),
            itemCount: therapies.length,
            itemBuilder: (context, index) {
              return TherapyCard(
                therapy: therapies[index],
                onTap: () {
                  if (therapies[index].path == '/therapy/reframing') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CognitiveReframingScreen(),
                      ),
                    );
                  } else if (therapies[index].path == '/therapy/breathing') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const GuidedBreathingScreen(),
                      ),
                    );
                  } else if (therapies[index].path == '/therapy/mindfulness') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MindfulnessScreen(),
                      ),
                    );
                  }
                  // Add other navigation routes as needed
                },
              );
            },
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

class TherapyItem {
  final String title;
  final String description;
  final String time;
  final IconData icon;
  final Color color;
  final String path;

  TherapyItem({
    required this.title,
    required this.description,
    required this.time,
    required this.icon,
    required this.color,
    required this.path,
  });
}

class TherapyCard extends StatelessWidget {
  final TherapyItem therapy;
  final VoidCallback onTap;

  const TherapyCard({super.key, required this.therapy, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: AppRadius.lgBorder,
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: therapy.color.withValues(alpha: 0.15),
                    borderRadius: AppRadius.mdBorder,
                  ),
                  child: Icon(therapy.icon, color: therapy.color, size: 24),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  therapy.title,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  therapy.description,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            Text(
              therapy.time,
              style: AppTextStyles.labelSmall.copyWith(
                color: therapy.color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
