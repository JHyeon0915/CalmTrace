import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../services/auth_service.dart';
import '../services/streak_service.dart';
import '../services/goals_service.dart';
import '../models/goal_model.dart';
import '../models/daily_tip_model.dart';
import '../widgets/app_bottom_nav_bar.dart';
import '../widgets/streak_celebration_modal.dart';
import '../widgets/set_goals_modal.dart';
import 'settings_screen.dart';
import 'games_screen.dart';
import 'therapy_hub_screen.dart';
import 'guided_breathing_screen.dart';
import 'tracking_screen.dart';
import '../services/stress_prediction_service.dart';
import 'package:flutter/foundation.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _authService = AuthService();
  final _streakService = StreakService();
  final _goalsService = GoalsService();

  int _currentIndex = 0;
  int _streakCount = 0;
  bool _isLoading = true;

  // Goals data
  List<UserGoal> _dailyGoals = [];
  int _goalsCompleted = 0;

  // Daily tip - gets set once based on today's date
  late final DailyTip _todaysTip;

  @override
  void initState() {
    super.initState();
    _todaysTip = DailyTips.getTodaysTip();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([_loadStreakData(), _loadGoalsData()]);
  }

  Future<void> _loadStreakData() async {
    try {
      debugPrint('🔄 Loading streak data...');
      final streak = await _streakService.checkAndUpdateStreak();
      debugPrint('📊 Streak from API: $streak');

      if (!mounted) return;

      setState(() {
        _streakCount = streak;
        _isLoading = false;
      });

      // Show celebration if user has a streak and hasn't seen today's celebration
      if (streak > 0) {
        final hasSeenToday = await _streakService.hasSeenTodaysCelebration();
        debugPrint('👀 Has seen today celebration: $hasSeenToday');

        if (!hasSeenToday && mounted) {
          await Future.delayed(const Duration(milliseconds: 500));
          if (!mounted) return;

          await _streakService.markCelebrationSeen();
          _showCelebrationModal(streak, false);
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading streak: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadGoalsData() async {
    try {
      debugPrint('🎯 Loading goals data...');
      final goalsData = await _goalsService.getDailyGoals();
      debugPrint('📋 Goals loaded: ${goalsData.goals.length}');

      if (!mounted) return;

      setState(() {
        _dailyGoals = goalsData.goals;
        _goalsCompleted = goalsData.completedCount;
      });
    } catch (e) {
      debugPrint('❌ Error loading goals: $e');
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

  Future<void> _showSetGoalsModal() async {
    final currentGoalTypes = _dailyGoals.map((g) => g.goalType).toList();

    final selectedGoals = await SetGoalsModal.show(
      context,
      initialSelectedGoals: currentGoalTypes,
      maxGoals: 2,
    );

    if (selectedGoals != null && selectedGoals.isNotEmpty && mounted) {
      debugPrint('💾 Saving goals: $selectedGoals');

      try {
        final goalsData = await _goalsService.setDailyGoals(selectedGoals);

        if (mounted) {
          setState(() {
            _dailyGoals = goalsData.goals;
            _goalsCompleted = goalsData.completedCount;
          });
        }
      } catch (e) {
        debugPrint('❌ Error saving goals: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Failed to save goals. Please try again.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  void _onNavTap(int index) {
    setState(() => _currentIndex = index);
  }

  Future<void> _onGoalTap(UserGoal goal) async {
    final goalOption = goal.goalOption;
    if (goalOption == null) return;

    // Navigate based on goal destination
    bool? completed;

    switch (goalOption.destination) {
      case GoalDestination.breathing:
        completed = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) => const GuidedBreathingScreen(),
          ),
        );
        break;

      case GoalDestination.tracking:
        // Navigate to tracking page (index 1 in bottom nav)
        setState(() => _currentIndex = 1);
        completed = true;
        break;

      case GoalDestination.therapy:
        // Navigate to therapy hub (index 2 in bottom nav)
        setState(() => _currentIndex = 2);
        completed = true;
        break;

      case GoalDestination.games:
        // Navigate to games (index 3 in bottom nav)
        setState(() => _currentIndex = 3);
        completed = true;
        break;

      case GoalDestination.chat:
        // TODO: Navigate to AI Coach chat
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('AI Coach coming soon!')),
          );
        }
        return;
    }

    // Complete the goal if navigation was successful
    if (completed == true && !goal.isCompleted) {
      await _completeGoal(goal.goalType);
    }
  }

  Future<void> _completeGoal(String goalType) async {
    try {
      debugPrint('🎯 Completing goal: $goalType');
      final result = await _goalsService.completeGoal(goalType);
      debugPrint(
        '📊 Goal complete result - progress: ${result.dailyProgress}/${result.totalGoals}',
      );

      if (!mounted) return;

      // Reload goals to get updated completion status
      await _loadGoalsData();

      // Update streak if needed
      if (result.streakUpdated && result.streakData != null) {
        setState(() {
          _streakCount = result.streakData!.streakCount;
        });

        // Show celebration if needed
        if (result.streakData!.shouldCelebrate) {
          final hasSeenToday = await _streakService.hasSeenTodaysCelebration();
          if (!hasSeenToday && mounted) {
            await _streakService.markCelebrationSeen();
            _showCelebrationModal(
              result.streakData!.streakCount,
              result.streakData!.isNewStreak,
            );
          }
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
        return const TrackingScreen();
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
    final totalGoals = _dailyGoals.isNotEmpty ? _dailyGoals.length : 2;

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
            value: '$_goalsCompleted/$totalGoals',
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
              onPressed: _showSetGoalsModal,
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

        // Dynamic goals list
        if (_dailyGoals.isEmpty)
        // Show default goals if none set
        ...[
          _buildDefaultGoalItem(
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
                _completeGoal('breathing');
              }
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildDefaultGoalItem(
            icon: Icons.show_chart,
            title: 'Check Stress Levels',
            iconColor: AppColors.warning,
            onTap: () {
              setState(() => _currentIndex = 1);
              _completeGoal('stress_check');
            },
          ),
        ] else
          // Show user's selected goals
          ..._dailyGoals.asMap().entries.map((entry) {
            final index = entry.key;
            final goal = entry.value;
            final goalOption = goal.goalOption;

            return Padding(
              padding: EdgeInsets.only(
                bottom: index < _dailyGoals.length - 1 ? AppSpacing.sm : 0,
              ),
              child: _buildGoalItem(
                goal: goal,
                goalOption: goalOption,
                onTap: () => _onGoalTap(goal),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildGoalItem({
    required UserGoal goal,
    required GoalOption? goalOption,
    required VoidCallback onTap,
  }) {
    final icon = goalOption?.icon ?? Icons.check_circle_outline;
    final iconColor = goalOption?.iconColor ?? AppColors.primary;
    final title = goalOption?.title ?? goal.title;

    return GestureDetector(
      onTap: goal.isCompleted ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: goal.isCompleted
              ? AppColors.success.withValues(alpha: 0.05)
              : AppColors.background,
          borderRadius: AppRadius.mdBorder,
          border: Border.all(
            color: goal.isCompleted ? AppColors.success : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: goal.isCompleted
                    ? AppColors.success.withValues(alpha: 0.1)
                    : iconColor.withValues(alpha: 0.1),
                borderRadius: AppRadius.smBorder,
              ),
              child: Icon(
                goal.isCompleted ? Icons.check : icon,
                color: goal.isCompleted ? AppColors.success : iconColor,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w500,
                      decoration: goal.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                      color: goal.isCompleted
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                    ),
                  ),
                  if (goal.isCompleted)
                    Text(
                      'Completed',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.success,
                      ),
                    ),
                ],
              ),
            ),
            if (!goal.isCompleted)
              const Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultGoalItem({
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
              const Icon(
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
                child: Center(
                  child: Text(
                    _todaysTip.emoji,
                    style: const TextStyle(fontSize: 14),
                  ),
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
          Text(_todaysTip.description, style: AppTextStyles.bodyMedium),
          const SizedBox(height: AppSpacing.sm),
          RichText(
            text: TextSpan(
              style: AppTextStyles.bodySmall,
              children: [
                TextSpan(
                  text: '${_todaysTip.actionPrefix} ',
                  style: TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(
                  text: _todaysTip.actionText,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget _buildEncouragement() {
  //   return Center(
  //     child: Row(
  //       mainAxisSize: MainAxisSize.min,
  //       children: [
  //         Text(
  //           "You're doing great today! ",
  //           style: AppTextStyles.bodyMedium.copyWith(
  //             color: AppColors.stressLow,
  //             fontWeight: FontWeight.w500,
  //           ),
  //         ),
  //         const Text('🌱', style: TextStyle(fontSize: 16)),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildEncouragement() {
    return Column(
      children: [
        Center(
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
        ),

        // Debug: Test ML Model Button
        if (kDebugMode) ...[
          const SizedBox(height: AppSpacing.lg),
          _buildTestMLButton(),
        ],
      ],
    );
  }

  Widget _buildTestMLButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F0),
        borderRadius: AppRadius.mdBorder,
        border: Border.all(color: const Color(0xFFFFCCCC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bug_report, color: Colors.red[400], size: 18),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Debug: ML Model Test',
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.red[400],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _testMLPrediction,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B9BD1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Test Stress Prediction'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _testMLPrediction() async {
    debugPrint('');
    debugPrint(
      '╔════════════════════════════════════════════════════════════╗',
    );
    debugPrint(
      '║              ML STRESS PREDICTION TEST                     ║',
    );
    debugPrint(
      '╚════════════════════════════════════════════════════════════╝',
    );
    debugPrint('');

    final stressService = StressPredictionService();

    // Step 1: Check model status
    debugPrint('📍 Step 1: Checking model status...');
    final status = await stressService.getModelStatus();
    debugPrint('   Models loaded: ${status.modelsLoaded}');
    debugPrint('   Available models: ${status.availableModels}');
    debugPrint('');

    // Step 2: Generate mock health data
    debugPrint('📍 Step 2: Generating mock health data...');

    // Simulate Garmin smartwatch data
    final mockHrvValues = <double>[
      45.2,
      48.1,
      42.3,
      50.5,
      47.8,
      44.2,
      46.9,
      49.1,
      43.5,
      47.2,
    ];
    final mockRrValues = <double>[
      14.5,
      15.2,
      14.8,
      15.0,
      14.7,
      15.1,
      14.6,
      14.9,
      15.3,
      14.8,
    ];
    final mockHrValues = <double>[72, 75, 71, 73, 74, 76, 70, 72, 74, 73];

    debugPrint('   HRV values: $mockHrvValues');
    debugPrint('   RR values: $mockRrValues');
    debugPrint('   HR values: $mockHrValues');
    debugPrint('');

    // Step 3: Make prediction
    debugPrint('📍 Step 3: Calling ML API...');

    try {
      final prediction = await stressService.predictStress(
        hrvValues: mockHrvValues,
        rrValues: mockRrValues,
        hrValues: mockHrValues,
      );

      debugPrint('');
      debugPrint('✅ PREDICTION RESULT:');
      debugPrint('   ┌─────────────────────────────────────');
      debugPrint('   │ Stress Level: ${prediction.stressLevel}/100');
      debugPrint('   │ Stress Class: ${prediction.stressClass}');
      debugPrint('   │ Stress Label: ${prediction.stressLabel}');
      debugPrint('   │ Confidence: ${prediction.confidence}%');
      debugPrint('   │ Model Used: ${prediction.modelUsed}');
      debugPrint('   │ Data Sources: ${prediction.dataSources.activeSources}');
      debugPrint('   │ Timestamp: ${prediction.timestamp}');
      debugPrint('   └─────────────────────────────────────');
      debugPrint('');

      // Show snackbar with result
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Stress: ${prediction.stressLevel}% (${prediction.stressLabel}) - Confidence: ${prediction.confidence}%',
            ),
            backgroundColor: prediction.isLowStress
                ? AppColors.success
                : prediction.isMediumStress
                ? AppColors.warning
                : AppColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      debugPrint('');
      debugPrint('❌ PREDICTION ERROR: $e');
      debugPrint('');

      // Try mock prediction as fallback
      debugPrint('📍 Step 4: Trying mock prediction...');
      try {
        final mockPrediction = await stressService.mockPredict(
          stressLevel: 35,
          confidence: 92,
        );

        debugPrint('');
        debugPrint('✅ MOCK PREDICTION RESULT:');
        debugPrint('   Stress Level: ${mockPrediction.stressLevel}');
        debugPrint('   Label: ${mockPrediction.stressLabel}');
        debugPrint('');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '⚠️ Used mock: Stress ${mockPrediction.stressLevel}% (${mockPrediction.stressLabel})',
              ),
              backgroundColor: AppColors.warning,
            ),
          );
        }
      } catch (e2) {
        debugPrint('❌ Mock prediction also failed: $e2');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ ML Error: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }

    debugPrint('');
    debugPrint('════════════════════════════════════════════════════════════');
    debugPrint('');
  }
}
