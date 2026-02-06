import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../constants/app_constants.dart';

class GuidedBreathingScreen extends StatefulWidget {
  const GuidedBreathingScreen({super.key});

  @override
  State<GuidedBreathingScreen> createState() => _GuidedBreathingScreenState();
}

class _GuidedBreathingScreenState extends State<GuidedBreathingScreen> {
  bool _isActive = false;
  bool _isCompleted = false;
  int _duration = 1; // minutes
  bool _soundEnabled = true;

  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _audioPlayer.setReleaseMode(ReleaseMode.loop);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _startBreathing() async {
    setState(() {
      _isActive = true;
    });

    if (_soundEnabled) {
      await _audioPlayer.play(AssetSource('audio/breathing.mp3'));
    }
  }

  void _stopAudio() async {
    await _audioPlayer.stop();
  }

  void _toggleSound() async {
    setState(() {
      _soundEnabled = !_soundEnabled;
    });

    if (_isActive) {
      if (_soundEnabled) {
        await _audioPlayer.play(AssetSource('audio/breathing.mp3'));
      } else {
        await _audioPlayer.pause();
      }
    }
  }

  void _onComplete() {
    _stopAudio();
    setState(() {
      _isActive = false;
      _isCompleted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isCompleted) {
      return _CompletionScreen(
        onReturn: () {
          _stopAudio();
          Navigator.pop(context);
        },
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      _stopAudio();
                      Navigator.pop(context);
                    },
                    child: const Icon(
                      Icons.arrow_back,
                      color: AppColors.textPrimary,
                      size: 24,
                    ),
                  ),
                  // Sound toggle
                  GestureDetector(
                    onTap: _toggleSound,
                    child: Icon(
                      _soundEnabled ? Icons.volume_up : Icons.volume_off,
                      color: AppColors.textSecondary,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),

            // Main content
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  BreathingCircle(
                    durationMinutes: _duration,
                    isActive: _isActive,
                    onComplete: _onComplete,
                  ),
                  const SizedBox(height: AppSpacing.xl * 2),

                  // Duration selector and start button (only when not active)
                  if (!_isActive)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Duration (minutes)',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [1, 2, 3].map((m) {
                              final isSelected = _duration == m;
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.xs,
                                ),
                                child: GestureDetector(
                                  onTap: () => setState(() => _duration = m),
                                  child: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.primary
                                          : AppColors.background,
                                      shape: BoxShape.circle,
                                      border: isSelected
                                          ? null
                                          : Border.all(color: AppColors.border),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '$m',
                                        style: AppTextStyles.bodyLarge.copyWith(
                                          color: isSelected
                                              ? Colors.white
                                              : AppColors.textSecondary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _startBreathing,
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
                                'Start Breathing',
                                style: AppTextStyles.bodyLarge.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BreathingCircle extends StatefulWidget {
  final int durationMinutes;
  final bool isActive;
  final VoidCallback onComplete;

  const BreathingCircle({
    super.key,
    required this.durationMinutes,
    required this.isActive,
    required this.onComplete,
  });

  @override
  State<BreathingCircle> createState() => _BreathingCircleState();
}

class _BreathingCircleState extends State<BreathingCircle>
    with TickerProviderStateMixin {
  late AnimationController _breathingController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  String _phase = 'Ready';
  int _timeLeft = 0;
  Timer? _timer;
  Timer? _phaseTimer;

  @override
  void initState() {
    super.initState();
    _timeLeft = widget.durationMinutes * 60;

    _breathingController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 0.1, end: 0.4).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(BreathingCircle oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isActive && !oldWidget.isActive) {
      _startBreathing();
    } else if (!widget.isActive && oldWidget.isActive) {
      _stopBreathing();
    }
  }

  void _startBreathing() {
    _timeLeft = widget.durationMinutes * 60;
    _phase = 'INHALE';

    // Start breathing animation loop
    _breathingController.forward();
    _breathingController.addStatusListener(_onAnimationStatus);

    // Start countdown timer
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _timeLeft--;
        if (_timeLeft <= 0) {
          _stopBreathing();
          widget.onComplete();
        }
      });
    });
  }

  void _onAnimationStatus(AnimationStatus status) {
    if (!widget.isActive) return;

    if (status == AnimationStatus.completed) {
      setState(() => _phase = 'EXHALE');
      _breathingController.reverse();
    } else if (status == AnimationStatus.dismissed) {
      setState(() => _phase = 'INHALE');
      _breathingController.forward();
    }
  }

  void _stopBreathing() {
    _timer?.cancel();
    _phaseTimer?.cancel();
    _breathingController.removeStatusListener(_onAnimationStatus);
    _breathingController.stop();
    _breathingController.reset();
    setState(() => _phase = 'Ready');
  }

  @override
  void dispose() {
    _timer?.cancel();
    _phaseTimer?.cancel();
    _breathingController.dispose();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '$mins : ${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 280,
          height: 280,
          child: AnimatedBuilder(
            animation: _breathingController,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  // Outer glow
                  Container(
                    width: 200 * _scaleAnimation.value,
                    height: 200 * _scaleAnimation.value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF6B9BD1,
                          ).withValues(alpha: _glowAnimation.value),
                          blurRadius: 60,
                          spreadRadius: 20,
                        ),
                      ],
                    ),
                  ),
                  // Main circle with gradient
                  Container(
                    width: 180 * _scaleAnimation.value,
                    height: 180 * _scaleAnimation.value,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF6B9BD1), Color(0xFF8FB996)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x336B9BD1),
                          blurRadius: 20,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        _phase,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          _formatTime(_timeLeft),
          style: AppTextStyles.h3.copyWith(
            fontFamily: 'monospace',
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}

// Completion Screen with animations
class _CompletionScreen extends StatefulWidget {
  final VoidCallback onReturn;

  const _CompletionScreen({required this.onReturn});

  @override
  State<_CompletionScreen> createState() => _CompletionScreenState();
}

class _CompletionScreenState extends State<_CompletionScreen>
    with TickerProviderStateMixin {
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

  @override
  void initState() {
    super.initState();

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
                        color: const Color(0xFF7BC67E).withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_outline,
                        color: Color(0xFF7BC67E),
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
                    child: Text('Session Complete', style: AppTextStyles.h2),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                // Animated subtitle
                SlideTransition(
                  position: _subtitleSlideAnimation,
                  child: FadeTransition(
                    opacity: _subtitleFadeAnimation,
                    child: Text(
                      "You've taken a moment for yourself.",
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Animated button
                SlideTransition(
                  position: _buttonSlideAnimation,
                  child: FadeTransition(
                    opacity: _buttonFadeAnimation,
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: widget.onReturn,
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
                          'Return to Hub',
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
