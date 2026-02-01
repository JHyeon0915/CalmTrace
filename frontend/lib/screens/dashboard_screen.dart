import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../services/auth_service.dart';
import '../widgets/app_bottom_nav_bar.dart';
import 'settings_screen.dart';
import 'games_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _authService = AuthService();
  int _currentIndex = 0;

  void _onNavTap(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(child: _buildBody()),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeContent();
      case 1:
        return _buildPlaceholder('Tracking');
      case 2:
        return _buildPlaceholder('Therapy');
      case 3:
        return const GamesScreen();
      default:
        return _buildHomeContent();
    }
  }

  Widget _buildHomeContent() {
    final user = _authService.currentUser;
    final displayName = user?.displayName ?? 'there';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.lg),
          _buildHeader(displayName),
          const SizedBox(height: AppSpacing.lg),
          _buildStatsRow(),
          const SizedBox(height: AppSpacing.lg),
          _buildStressLevelCard(),
          const SizedBox(height: AppSpacing.lg),
          _buildTodaysGoals(),
          const SizedBox(height: AppSpacing.lg),
          _buildTodaysTip(),
          const SizedBox(height: AppSpacing.lg),
          _buildEncouragement(),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildHeader(String name) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hi, $name', style: AppTextStyles.h2),
            const SizedBox(height: 4),
            Text(
              'Ready to find your calm?',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            );
          },
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

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: '🔥',
            value: '5',
            label: 'Day Streak',
            backgroundColor: const Color(0xFFFFF4E5),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _buildStatCard(
            icon: '🏆',
            value: '1/2',
            label: 'Daily Goals',
            backgroundColor: const Color(0xFFFFF9E5),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String icon,
    required String value,
    required String label,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppRadius.lgBorder,
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStressLevelCard() {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Current Stress Level', style: AppTextStyles.h4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.stressLow.withValues(alpha: 0.15),
                  borderRadius: AppRadius.roundBorder,
                ),
                child: Text(
                  'Low',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.stressLow,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: 160,
            height: 160,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 160,
                  height: 160,
                  child: CircularProgressIndicator(
                    value: 1.0,
                    strokeWidth: 12,
                    backgroundColor: AppColors.border,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.border),
                  ),
                ),
                SizedBox(
                  width: 160,
                  height: 160,
                  child: CircularProgressIndicator(
                    value: 0.35,
                    strokeWidth: 12,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.textSecondary,
                    ),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '35',
                      style: AppTextStyles.h1.copyWith(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Low Stress',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
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
                '92 %',
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
              value: 0.92,
              minHeight: 8,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.stressLow,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Icon(Icons.trending_down, color: AppColors.stressLow, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Trending down from yesterday',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTodaysGoals() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.track_changes,
                    color: AppColors.primary,
                    size: 14,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  "Today's Goals",
                  style: AppTextStyles.h4.copyWith(fontSize: 16),
                ),
              ],
            ),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Change Goals',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _buildGoalItem(
          icon: Icons.air,
          title: 'Practice Breathing',
          iconColor: AppColors.primary,
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildGoalItem(
          icon: Icons.show_chart,
          title: 'Check Stress Levels',
          iconColor: AppColors.warning,
        ),
      ],
    );
  }

  Widget _buildGoalItem({
    required IconData icon,
    required String title,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: AppRadius.mdBorder,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: AppRadius.smBorder,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            title,
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodaysTip() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: AppRadius.lgBorder,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF9E5),
                  borderRadius: AppRadius.smBorder,
                ),
                child: const Center(
                  child: Text('💡', style: TextStyle(fontSize: 14)),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                "Today's Tip",
                style: AppTextStyles.h4.copyWith(fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Take a break from screens for 15 minutes.',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          RichText(
            text: TextSpan(
              style: AppTextStyles.bodySmall,
              children: [
                TextSpan(
                  text: 'Try this: ',
                  style: TextStyle(
                    color: AppColors.stressLow,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(
                  text:
                      'Digital overload contributes to mental fatigue and stress.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEncouragement() {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "You're doing great today! ",
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.stressLow,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Text('🌱', style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(String title) {
    return Center(child: Text('$title Screen', style: AppTextStyles.h3));
  }
}
