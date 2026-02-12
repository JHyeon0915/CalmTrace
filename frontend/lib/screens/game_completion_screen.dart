import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../services/goals_service.dart';

/// A stat to display on the game end screen
class GameStat {
  final String label;
  final String value;

  const GameStat({required this.label, required this.value});
}

/// Game end screen that displays stats and updates goals
class GameCompletionScreen extends StatefulWidget {
  final String gameName;
  final List<GameStat> stats;
  final VoidCallback onReturn;

  const GameCompletionScreen({
    super.key,
    required this.gameName,
    required this.stats,
    required this.onReturn,
  });

  @override
  State<GameCompletionScreen> createState() => _GameCompletionScreenState();
}

class _GameCompletionScreenState extends State<GameCompletionScreen>
    with TickerProviderStateMixin {
  final GoalsService _goalsService = GoalsService();

  late AnimationController _trophyController;
  late AnimationController _contentController;
  late Animation<double> _trophyScaleAnimation;
  late Animation<double> _trophyBounceAnimation;
  late Animation<double> _titleFadeAnimation;
  late Animation<Offset> _titleSlideAnimation;
  late Animation<double> _statsFadeAnimation;
  late Animation<Offset> _statsSlideAnimation;
  late Animation<double> _messageFadeAnimation;
  late Animation<double> _buttonFadeAnimation;
  late Animation<Offset> _buttonSlideAnimation;

  bool _isUpdatingGoal = false;
  String? _goalUpdateMessage;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _checkAndUpdateGoal();
  }

  void _setupAnimations() {
    // Trophy animation controller
    _trophyController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Content animation controller
    _contentController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Trophy scale with spring effect
    _trophyScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _trophyController, curve: Curves.elasticOut),
    );

    // Trophy bounce animation (continuous)
    _trophyBounceAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_trophyController);

    // Title animations
    _titleFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.1, 0.4, curve: Curves.easeOut),
      ),
    );

    _titleSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _contentController,
            curve: const Interval(0.1, 0.4, curve: Curves.easeOut),
          ),
        );

    // Stats animations
    _statsFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.3, 0.6, curve: Curves.easeOut),
      ),
    );

    _statsSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _contentController,
            curve: const Interval(0.3, 0.6, curve: Curves.easeOut),
          ),
        );

    // Message animation
    _messageFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.6, 0.8, curve: Curves.easeOut),
      ),
    );

    // Button animations
    _buttonFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
      ),
    );

    _buttonSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _contentController,
            curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
          ),
        );

    // Start animations
    _trophyController.forward().then((_) {
      _contentController.forward();
    });
  }

  Future<void> _checkAndUpdateGoal() async {
    setState(() => _isUpdatingGoal = true);

    try {
      debugPrint('🎮 Game completed: ${widget.gameName}');

      // Get current daily goals
      final goalsData = await _goalsService.getDailyGoals();

      // Check if "games" is one of today's goals
      final matchingGoal = goalsData.goals
          .where((g) => g.goalType == 'games')
          .toList();

      if (matchingGoal.isNotEmpty) {
        final goal = matchingGoal.first;

        if (goal.isCompleted) {
          debugPrint('✅ Games goal already completed today');
          setState(() {
            _goalUpdateMessage = 'Goal already completed today!';
          });
        } else {
          debugPrint('📤 Completing games goal');
          final result = await _goalsService.completeGoal('games');

          if (result.success) {
            debugPrint('🎉 Games goal completed!');
            setState(() {
              _goalUpdateMessage = 'Daily goal completed! 🎉';
            });
          }
        }
      } else {
        debugPrint('ℹ️ Games is not a daily goal');
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
    _trophyController.dispose();
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
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Trophy icon with bounce animation
                ScaleTransition(
                  scale: _trophyScaleAnimation,
                  child: _AnimatedTrophy(controller: _trophyController),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Title
                SlideTransition(
                  position: _titleSlideAnimation,
                  child: FadeTransition(
                    opacity: _titleFadeAnimation,
                    child: Text('Session Complete', style: AppTextStyles.h2),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),

                // Game name subtitle
                SlideTransition(
                  position: _titleSlideAnimation,
                  child: FadeTransition(
                    opacity: _titleFadeAnimation,
                    child: Text(
                      widget.gameName,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Stats cards
                SlideTransition(
                  position: _statsSlideAnimation,
                  child: FadeTransition(
                    opacity: _statsFadeAnimation,
                    child: Column(
                      children: widget.stats.asMap().entries.map((entry) {
                        final index = entry.key;
                        final stat = entry.value;
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: index < widget.stats.length - 1
                                ? AppSpacing.sm
                                : 0,
                          ),
                          child: _StatCard(stat: stat),
                        );
                      }).toList(),
                    ),
                  ),
                ),

                // Goal update message
                if (_goalUpdateMessage != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  FadeTransition(
                    opacity: _messageFadeAnimation,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: AppRadius.roundBorder,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check_circle,
                            size: 16,
                            color: AppColors.success,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            _goalUpdateMessage!,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: AppSpacing.xl),

                // Encouraging message
                FadeTransition(
                  opacity: _messageFadeAnimation,
                  child: Text(
                    'Great job taking time for yourself 🌿',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.stressLow,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Return button
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
                                'Return to Games',
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

/// Animated trophy icon with bounce effect
class _AnimatedTrophy extends StatefulWidget {
  final AnimationController controller;

  const _AnimatedTrophy({required this.controller});

  @override
  State<_AnimatedTrophy> createState() => _AnimatedTrophyState();
}

class _AnimatedTrophyState extends State<_AnimatedTrophy>
    with SingleTickerProviderStateMixin {
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _bounceAnimation = Tween<double>(begin: 0, end: -4).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );

    // Start bouncing after initial animation completes
    widget.controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _bounceController.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bounceAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _bounceAnimation.value),
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: const Color(0xFFF0B67F).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.emoji_events_outlined,
              color: Color(0xFFF0B67F),
              size: 48,
            ),
          ),
        );
      },
    );
  }
}

/// Stat card widget
class _StatCard extends StatelessWidget {
  final GameStat stat;

  const _StatCard({required this.stat});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: AppRadius.lgBorder,
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            stat.label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            stat.value,
            style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
