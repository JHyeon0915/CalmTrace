import 'dart:async';
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../services/auth_service.dart';
import '../services/streak_service.dart';
import '../services/goals_service.dart';
import '../services/stress_prediction_service.dart';
import '../services/notification_service.dart';
import '../services/device_feedback_service.dart';
import '../services/emotiv_service.dart';
import '../models/stress_data_source.dart';
import '../models/goal_model.dart';
import '../models/daily_tip_model.dart';
import '../widgets/app_bottom_nav_bar.dart';
import '../widgets/streak_celebration_modal.dart';
import '../widgets/set_goals_modal.dart';
import '../widgets/stress_gauge.dart';
import '../widgets/dashboard/dashboard_header.dart';
import '../widgets/dashboard/stat_card.dart';
import '../widgets/dashboard/dashboard_stress_card.dart';
import '../widgets/dashboard/todays_goals_section.dart';
import '../widgets/dashboard/daily_tip_card.dart';
import '../widgets/dashboard/debug_panel.dart';
import 'settings_screen.dart';
import 'games_screen.dart';
import 'therapy_hub_screen.dart';
import 'guided_breathing_screen.dart';
import 'ai_coach_screen.dart';
import 'tracking_screen.dart';

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

  List<UserGoal> _dailyGoals = [];
  int _goalsCompleted = 0;

  StressReading? _currentReading;
  StreamSubscription<StressReading>? _fusionSubscription;

  late final DailyTip _todaysTip;

  @override
  void initState() {
    super.initState();
    _todaysTip = DailyTips.getTodaysTip();
    _loadData();
    GoalsService.onGoalCompleted = _onAnyGoalCompleted;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      EmotivService().fullConnect(context);
    });
  }

  @override
  void dispose() {
    _fusionSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([_loadStreakData(), _loadGoalsData(), _loadStressData()]);
  }

  Future<void> _loadStressData() async {
    if (_currentReading != null) return;
  }

  Future<void> _loadStreakData() async {
    try {
      final streak = await _streakService.checkAndUpdateStreak();
      debugPrint('📊 Streak from API: $streak');
      if (!mounted) return;
      setState(() {
        _streakCount = streak;
        _isLoading = false;
      });
      if (streak > 0) {
        final hasSeenToday = await _streakService.hasSeenTodaysCelebration();
        if (!hasSeenToday && mounted) {
          await Future.delayed(const Duration(milliseconds: 500));
          if (!mounted) return;
          await _streakService.markCelebrationSeen();
          _showCelebrationModal(streak, false);
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading streak: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadGoalsData() async {
    try {
      final goalsData = await _goalsService.getDailyGoals();
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
    final previousIndex = _currentIndex;
    setState(() => _currentIndex = index);
    // Reload when returning home so completions from other screens are reflected
    if (index == 0 && previousIndex != 0) _loadData();
  }

  Future<void> _onGoalTap(UserGoal goal) async {
    final goalOption = goal.goalOption;
    if (goalOption == null) return;
    switch (goalOption.destination) {
      case GoalDestination.breathing:
        Navigator.push<bool>(
          context,
          MaterialPageRoute(builder: (_) => const GuidedBreathingScreen()),
        );
        break;
      case GoalDestination.tracking:
        setState(() => _currentIndex = 1);
        break;
      case GoalDestination.therapy:
        setState(() => _currentIndex = 2);
        break;
      case GoalDestination.games:
        setState(() => _currentIndex = 3);
        break;
      case GoalDestination.chat:
        Navigator.push<bool>(
          context,
          MaterialPageRoute(builder: (_) => const AICoachScreen()),
        );
        break;
    }
  }

  Future<void> _onAnyGoalCompleted() async {
    await _loadData();
    final goalsData = await _goalsService.getDailyGoals();
    final allDone =
        goalsData.goals.isNotEmpty &&
        goalsData.goals.every((g) => g.isCompleted);
    if (allDone && mounted) {
      final streak = await _streakService.checkAndUpdateStreak();
      final hasSeenToday = await _streakService.hasSeenTodaysCelebration();
      if (!hasSeenToday && streak > 0 && mounted) {
        await _streakService.markCelebrationSeen();
        _showCelebrationModal(streak, false);
      }
    }
  }

  GaugeDataState get _gaugeState {
    if (_isLoading && _currentReading == null) return GaugeDataState.loading;
    if (_currentReading == null ||
        _currentReading!.source == DataSource.none ||
        _currentReading!.stressLevel == null) {
      return GaugeDataState.noData;
    }
    return GaugeDataState.hasData;
  }

  String _trendLabel() {
    final level = _currentReading?.stressLevel;
    if (level == null) return '—';
    if (level <= 40) return 'Trending down ↓';
    if (level <= 70) return 'Moderate';
    return 'Elevated ↑';
  }

  Future<void> _testMLPrediction() async {
    final stressService = StressPredictionService();
    final status = await stressService.getModelStatus();
    debugPrint('Models loaded: ${status.modelsLoaded}');
    debugPrint('   Available models: ${status.availableModels}');
    debugPrint('');

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
              '✅ Stress: ${prediction.stressLevel}% — Confidence: ${prediction.confidence}%',
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
      debugPrint('❌ PREDICTION ERROR: $e');

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
              content: Text('⚠️ Mock: Stress ${mockPrediction.stressLevel}%'),
              backgroundColor: AppColors.warning,
            ),
          );
        }
      } catch (e2) {
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
  }

  Future<void> _testNotification() async {
    try {
      await NotificationService().showLocalNotification(
        title: '🔔 Notification successfully sent',
        body: 'Notification service is working correctly.',
      );
    } catch (e) {
      debugPrint('❌ showLocalNotification failed: $e');
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
    final displayName = _authService.currentUser?.displayName ?? 'there';
    final totalGoals = _dailyGoals.isNotEmpty ? _dailyGoals.length : 2;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.lg),
          DashboardHeader(
            displayName: displayName,
            onSettingsTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  icon: '🔥',
                  value: _isLoading ? '-' : '$_streakCount',
                  label: 'Day Streak',
                  backgroundColor: const Color(0xFFFFF4E5),
                  onTap: _streakCount > 0
                      ? () => _showCelebrationModal(_streakCount, false)
                      : null,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: StatCard(
                  icon: '🏆',
                  value: '$_goalsCompleted/$totalGoals',
                  label: 'Daily Goals',
                  backgroundColor: const Color(0xFFFFF9E5),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          DashboardStressCard(
            reading: _currentReading,
            gaugeState: _gaugeState,
            trendLabel: _trendLabel(),
          ),
          const SizedBox(height: AppSpacing.lg),
          TodaysGoalsSection(
            dailyGoals: _dailyGoals,
            onGoalTap: _onGoalTap,
            onSetGoalsTap: _showSetGoalsModal,
            onBreathingTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const GuidedBreathingScreen()),
            ),
            onTrackingTap: () => setState(() => _currentIndex = 1),
          ),
          const SizedBox(height: AppSpacing.lg),
          DailyTipCard(tip: _todaysTip),
          const SizedBox(height: AppSpacing.lg),
          DebugPanel(
            onTestML: _testMLPrediction,
            onTestNotification: _testNotification,
            onTestDeviceFeedback: () async {
              await DeviceFeedbackService().triggerFeedback(context);
            },
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}
