import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class StreakCelebrationModal extends StatefulWidget {
  final int streakCount;
  final bool isNewStreak;
  final VoidCallback onClose;

  const StreakCelebrationModal({
    super.key,
    required this.streakCount,
    this.isNewStreak = false,
    required this.onClose,
  });

  // Static method to show the modal
  static Future<void> show(
    BuildContext context, {
    required int streakCount,
    bool isNewStreak = false,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Streak Celebration',
      barrierColor: Colors.black.withValues(alpha: 0.4),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return StreakCelebrationModal(
          streakCount: streakCount,
          isNewStreak: isNewStreak,
          onClose: () => Navigator.of(context).pop(),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutBack,
            ),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<StreakCelebrationModal> createState() => _StreakCelebrationModalState();
}

class _StreakCelebrationModalState extends State<StreakCelebrationModal>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _rotateAnimation = Tween<double>(begin: -0.05, end: 0.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  StreakMessage _getMessage() {
    if (widget.isNewStreak && widget.streakCount == 1) {
      return StreakMessage(
        title: 'Streak Started! 🎉',
        message: "You've completed your first day of goals. Keep it up!",
        emoji: '🌱',
      );
    }

    switch (widget.streakCount) {
      case 3:
        return StreakMessage(
          title: '3 Day Streak! 🔥',
          message: "You're building a great habit. Three days in a row!",
          emoji: '🌿',
        );
      case 7:
        return StreakMessage(
          title: 'One Week Strong! ⭐',
          message: "A full week of self-care. You're doing amazing!",
          emoji: '🌟',
        );
      case 14:
        return StreakMessage(
          title: 'Two Weeks! 🎊',
          message: 'Your dedication is inspiring. Keep nurturing yourself!',
          emoji: '🌸',
        );
      case 30:
        return StreakMessage(
          title: '30 Days! 🏆',
          message: "A full month of wellness. You're a champion!",
          emoji: '👑',
        );
      default:
        return StreakMessage(
          title: '${widget.streakCount} Day Streak! 🔥',
          message: "You're making great progress. Keep going!",
          emoji: '✨',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final message = _getMessage();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Material(
          color: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 340),
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: AppRadius.xlBorder,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated Flame Icon
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Transform.rotate(
                        angle: _rotateAnimation.value,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                const Color(0xFFFED7AA),
                                const Color(0xFFFDBA74),
                              ],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.local_fire_department,
                              color: Color(0xFFF97316),
                              size: 40,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.lg),

                // Title
                Text(
                  message.title,
                  style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),

                // Message
                Text(
                  message.message,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),

                // Emoji
                Text(message.emoji, style: const TextStyle(fontSize: 48)),
                const SizedBox(height: AppSpacing.lg),

                // Continue Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: widget.onClose,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.mdBorder,
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Continue',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
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

class StreakMessage {
  final String title;
  final String message;
  final String emoji;

  StreakMessage({
    required this.title,
    required this.message,
    required this.emoji,
  });
}
