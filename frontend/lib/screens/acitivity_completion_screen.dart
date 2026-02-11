import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../services/goals_service.dart';

/// Types of activities that can be completed
enum ActivityType {
  breathing,
  therapy, // covers both mindfulness and cognitive reframing
  stressCheck,
  games,
  chat,
}

/// Configuration for the completion screen
class CompletionConfig {
  final String title;
  final String subtitle;
  final String buttonText;
  final Color accentColor;
  final IconData icon;

  const CompletionConfig({
    required this.title,
    required this.subtitle,
    required this.buttonText,
    this.accentColor = const Color(0xFF8FB996),
    this.icon = Icons.check_circle_outline,
  });

  /// Predefined configs for different activities
  static const breathing = CompletionConfig(
    title: 'Session Complete',
    subtitle: "You've taken a moment for yourself.",
    buttonText: 'Return to Hub',
    accentColor: Color(0xFF7BC67E),
  );

  static const mindfulness = CompletionConfig(
    title: 'Well Done!',
    subtitle:
        "You've completed a grounding exercise. Take this calm feeling with you.",
    buttonText: 'Return to Therapy Hub',
    accentColor: Color(0xFF8FB996),
  );

  static const cognitiveReframing = CompletionConfig(
    title: 'Well Done!',
    subtitle:
        "You've practiced reframing a negative thought. This skill gets easier with practice.",
    buttonText: 'Return to Therapy Hub',
    accentColor: Color(0xFF8FB996),
  );

  static const stressCheck = CompletionConfig(
    title: 'Check Complete',
    subtitle: "Your stress levels have been recorded.",
    buttonText: 'Return to Dashboard',
    accentColor: Color(0xFF6B9BD1),
  );

  static const games = CompletionConfig(
    title: 'Great Job!',
    subtitle: "You've taken a relaxing break.",
    buttonText: 'Return to Games',
    accentColor: Color(0xFF64B5F6),
  );
}

/// Reusable completion screen that handles goal updates
class ActivityCompletionScreen extends StatefulWidget {
  final CompletionConfig config;
  final ActivityType activityType;
  final VoidCallback onReturn;

  const ActivityCompletionScreen({
    super.key,
    required this.config,
    required this.activityType,
    required this.onReturn,
  });

  @override
  State<ActivityCompletionScreen> createState() =>
      _ActivityCompletionScreenState();
}

class _ActivityCompletionScreenState extends State<ActivityCompletionScreen>
    with TickerProviderStateMixin {
  final GoalsService _goalsService = GoalsService();

  late AnimationController _iconController;
  late AnimationController _contentController;
  late Animation<double> _iconScaleAnimation;
  late Animation<double> _iconFadeAnimation;
  late Animation<double> _titleFadeAnimation;
  late Animation<Offset> _titleSlideAnimation;
  late Animation<double> _subtitleFadeAnimation;
  late Animation<Offset> _subtitleSlideAnimation;
  late Animation<double> _buttonFadeAnimation;
  late Animation<Offset> _buttonSlideAnimation;

  bool _isUpdatingGoal = false;
  bool _goalUpdated = false;
  String? _goalUpdateMessage;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _checkAndUpdateGoal();
  }

  void _setupAnimations() {
    _iconController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _contentController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _iconScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _iconController, curve: Curves.elasticOut),
    );

    _iconFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _iconController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _titleFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _titleSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _contentController,
            curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
          ),
        );

    _subtitleFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.2, 0.7, curve: Curves.easeOut),
      ),
    );

    _subtitleSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _contentController,
            curve: const Interval(0.2, 0.7, curve: Curves.easeOut),
          ),
        );

    _buttonFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );

    _buttonSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _contentController,
            curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
          ),
        );

    _iconController.forward().then((_) {
      _contentController.forward();
    });
  }

  /// Map activity type to goal type string used by backend
  String _getGoalType() {
    switch (widget.activityType) {
      case ActivityType.breathing:
        return 'breathing';
      case ActivityType.therapy:
        return 'therapy';
      case ActivityType.stressCheck:
        return 'stress_check';
      case ActivityType.games:
        return 'games';
      case ActivityType.chat:
        return 'chat';
    }
  }

  /// Check if this activity is a daily goal and update if needed
  Future<void> _checkAndUpdateGoal() async {
    setState(() => _isUpdatingGoal = true);

    try {
      final goalType = _getGoalType();
      debugPrint('🎯 Activity completed: $goalType');

      // Get current daily goals
      final goalsData = await _goalsService.getDailyGoals();

      // Check if this activity type is one of today's goals
      final matchingGoal = goalsData.goals
          .where((g) => g.goalType == goalType)
          .toList();

      if (matchingGoal.isNotEmpty) {
        final goal = matchingGoal.first;

        if (goal.isCompleted) {
          // Already completed today
          debugPrint('✅ Goal already completed today');
          setState(() {
            _goalUpdateMessage = 'Goal already completed today!';
          });
        } else {
          // Complete the goal
          debugPrint('📤 Completing goal: $goalType');
          final result = await _goalsService.completeGoal(goalType);

          if (result.success) {
            debugPrint(
              '🎉 Goal completed! Progress: ${result.dailyProgress}/${result.totalGoals}',
            );
            setState(() {
              _goalUpdated = true;
              _goalUpdateMessage = 'Daily goal completed! 🎉';
            });
          }
        }
      } else {
        debugPrint('ℹ️ Activity is not a daily goal');
      }
    } catch (e) {
      debugPrint('❌ Error updating goal: $e');
    } finally {
      if (mounted) {
        setState(() => _isUpdatingGoal = false);
      }
    }
  }

  @override
  void dispose() {
    _iconController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated icon
                FadeTransition(
                  opacity: _iconFadeAnimation,
                  child: ScaleTransition(
                    scale: _iconScaleAnimation,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: widget.config.accentColor.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        widget.config.icon,
                        color: widget.config.accentColor,
                        size: 56,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Animated title
                SlideTransition(
                  position: _titleSlideAnimation,
                  child: FadeTransition(
                    opacity: _titleFadeAnimation,
                    child: Text(widget.config.title, style: AppTextStyles.h2),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                // Animated subtitle
                SlideTransition(
                  position: _subtitleSlideAnimation,
                  child: FadeTransition(
                    opacity: _subtitleFadeAnimation,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                      ),
                      child: Text(
                        widget.config.subtitle,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),

                // Goal update message
                if (_goalUpdateMessage != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  SlideTransition(
                    position: _subtitleSlideAnimation,
                    child: FadeTransition(
                      opacity: _subtitleFadeAnimation,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: _goalUpdated
                              ? AppColors.success.withValues(alpha: 0.1)
                              : AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: AppRadius.roundBorder,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _goalUpdated
                                  ? Icons.check_circle
                                  : Icons.info_outline,
                              size: 16,
                              color: _goalUpdated
                                  ? AppColors.success
                                  : AppColors.primary,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              _goalUpdateMessage!,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: _goalUpdated
                                    ? AppColors.success
                                    : AppColors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: AppSpacing.xl),

                // Animated button
                SlideTransition(
                  position: _buttonSlideAnimation,
                  child: FadeTransition(
                    opacity: _buttonFadeAnimation,
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isUpdatingGoal ? null : widget.onReturn,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: AppColors.primary.withValues(
                            alpha: 0.5,
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.md,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.mdBorder,
                          ),
                          elevation: 0,
                        ),
                        child: _isUpdatingGoal
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Text(
                                widget.config.buttonText,
                                style: AppTextStyles.bodyLarge.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
