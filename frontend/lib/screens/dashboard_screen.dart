import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../services/auth_service.dart';
import '../services/streak_service.dart';
import '../widgets/app_bottom_nav_bar.dart';
import '../widgets/streak_celebration_modal.dart';
import 'settings_screen.dart';
import 'games_screen.dart';
import 'therapy_hub_screen.dart';
import 'guided_breathing_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _authService = AuthService();
  final _streakService = StreakService();
  int _currentIndex = 0;
  int _streakCount = 0;
  int _goalsCompleted = 0;
  final int _totalGoals = 2;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStreakData();
  }

  Future<void> _loadStreakData() async {
    try {
      debugPrint('🔄 Loading streak data...');

      // Get streak from backend
      final streak = await _streakService.checkAndUpdateStreak();
      debugPrint('📊 Streak from API: $streak');

      if (!mounted) return;

      setState(() {
        _streakCount = streak;
        _isLoading = false;
      });

      debugPrint('✅ State updated - streakCount: $_streakCount');

      // Check if we should show celebration
      if (streak > 0) {
        final hasSeenToday = await _streakService.hasSeenTodaysCelebration();
        debugPrint('👀 Has seen today celebration: $hasSeenToday');

        if (!hasSeenToday && mounted) {
          // Small delay to let the screen build first
          await Future.delayed(const Duration(milliseconds: 500));

          if (!mounted) return;

          await _streakService.markCelebrationSeen();
          debugPrint('🎉 Showing celebration modal for streak: $streak');

          _showCelebrationModal(streak, false);
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading streak: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showCelebrationModal(int streakCount, bool isNewStreak) {
    if (!mounted) return;

    StreakCelebrationModal.show(
      context,
      streakCount: streakCount,
      isNewStreak: isNewStreak,
    );
  }

  void _onNavTap(int index) {
    setState(() => _currentIndex = index);
  }

  Future<void> _onGoalCompleted() async {
    try {
      debugPrint('🎯 Completing goal...');
      final result = await _streakService.completeGoal();
      debugPrint(
        '📊 Goal complete result - streak: ${result.streakCount}, shouldCelebrate: ${result.shouldCelebrate}',
      );

      if (!mounted) return;

      setState(() {
        _streakCount = result.streakCount;
        _goalsCompleted = (_goalsCompleted + 1).clamp(0, _totalGoals);
      });

      // Show celebration if needed
      if (result.shouldCelebrate) {
        final hasSeenToday = await _streakService.hasSeenTodaysCelebration();
        debugPrint('👀 Has seen today (after goal): $hasSeenToday');

        if (!hasSeenToday && mounted) {
          await _streakService.markCelebrationSeen();
          debugPrint('🎉 Showing celebration after goal completion');
          _showCelebrationModal(result.streakCount, result.isNewStreak);
        }
      }
    } catch (e) {
      debugPrint('❌ Error completing goal: $e');
    }
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
        return const TherapyHubScreen();
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
            Text('Ready to find your calm?', style: AppTextStyles.bodyMedium),
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
          child: GestureDetector(
            onTap: () {
              if (_streakCount > 0) {
                _showCelebrationModal(_streakCount, false);
              }
            },
            child: _buildStatCard(
              icon: '🔥',
              value: _isLoading ? '-' : '$_streakCount',
              label: 'Day Streak',
              backgroundColor: const Color(0xFFFFF4E5),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _buildStatCard(
            icon: '🏆',
            value: '$_goalsCompleted/$_totalGoals',
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
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('AI Confidence', style: AppTextStyles.bodyMedium),
              Text(
                '92 %',
                style: AppTextStyles.bodyMedium.copyWith(
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
                  color: AppColors.textPrimary,
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
          onTap: () async {
            final result = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (context) => const GuidedBreathingScreen(),
              ),
            );
            if (result == true) {
              _onGoalCompleted();
            }
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildGoalItem(
          icon: Icons.show_chart,
          title: 'Check Stress Levels',
          iconColor: AppColors.warning,
          onTap: () {
            _onGoalCompleted();
          },
        ),
      ],
    );
  }

  Widget _buildGoalItem({
    required IconData icon,
    required String title,
    required Color iconColor,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary,
                size: 20,
              ),
          ],
        ),
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
                  text:
                      'Digital overload contributes to mental fatigue and stress.',
                  style: AppTextStyles.bodySmall,
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
