import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

enum TappingStressLevel { high, medium, low }

extension TappingStressLevelExtension on TappingStressLevel {
  String get label {
    switch (this) {
      case TappingStressLevel.high:
        return 'High';
      case TappingStressLevel.medium:
        return 'Medium';
      case TappingStressLevel.low:
        return 'Low';
    }
  }

  String get description {
    switch (this) {
      case TappingStressLevel.high:
        return '40 BPM • Large Targets';
      case TappingStressLevel.medium:
        return '60 BPM • Standard';
      case TappingStressLevel.low:
        return '80 BPM • Small Targets';
    }
  }

  Color get color {
    switch (this) {
      case TappingStressLevel.high:
        return const Color(0xFFE89B9B);
      case TappingStressLevel.medium:
        return const Color(0xFFF0B67F);
      case TappingStressLevel.low:
        return const Color(0xFF7BC67E);
    }
  }

  int get bpm {
    switch (this) {
      case TappingStressLevel.high:
        return 40;
      case TappingStressLevel.medium:
        return 60;
      case TappingStressLevel.low:
        return 80;
    }
  }

  int get intervalMs {
    switch (this) {
      case TappingStressLevel.high:
        return 1500; // Slower
      case TappingStressLevel.medium:
        return 1000; // Standard
      case TappingStressLevel.low:
        return 750; // Faster
    }
  }

  double get circleSize {
    switch (this) {
      case TappingStressLevel.high:
        return 80; // Large
      case TappingStressLevel.medium:
        return 64; // Standard
      case TappingStressLevel.low:
        return 48; // Small
    }
  }
}

class TappingCircle {
  final int id;
  final double x; // Percentage 0-100
  final double y; // Percentage 0-100
  final Color color;

  TappingCircle({
    required this.id,
    required this.x,
    required this.y,
    required this.color,
  });
}

class MindfulTappingScreen extends StatefulWidget {
  const MindfulTappingScreen({super.key});

  @override
  State<MindfulTappingScreen> createState() => _MindfulTappingScreenState();
}

class _MindfulTappingScreenState extends State<MindfulTappingScreen>
    with TickerProviderStateMixin {
  TappingStressLevel _stressLevel = TappingStressLevel.medium;
  bool _isPlaying = false;
  int _score = 0;
  List<TappingCircle> _circles = [];
  Timer? _spawnTimer;
  final Random _random = Random();

  final List<Color> _circleColors = const [
    Color(0xFF6B9BD1), // Blue
    Color(0xFF8FB996), // Green
    Color(0xFFB4A7D6), // Purple
    Color(0xFFF0B67F), // Orange
  ];

  // Track animation controllers for each circle
  final Map<int, AnimationController> _circleAnimControllers = {};

  @override
  void dispose() {
    _stopGame();
    for (var controller in _circleAnimControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _startGame() {
    setState(() {
      _isPlaying = true;
      _circles = [];
    });
    _startSpawning();
  }

  void _pauseGame() {
    _spawnTimer?.cancel();
    setState(() {
      _isPlaying = false;
    });
  }

  void _stopGame() {
    _spawnTimer?.cancel();
    for (var controller in _circleAnimControllers.values) {
      controller.dispose();
    }
    _circleAnimControllers.clear();
  }

  void _resetGame() {
    _stopGame();
    setState(() {
      _isPlaying = false;
      _score = 0;
      _circles = [];
    });
  }

  void _onStressLevelChanged(TappingStressLevel level) {
    if (level != _stressLevel) {
      _resetGame();
      setState(() {
        _stressLevel = level;
      });
    }
  }

  void _startSpawning() {
    _spawnTimer = Timer.periodic(
      Duration(milliseconds: _stressLevel.intervalMs),
      (_) => _spawnCircle(),
    );
  }

  void _spawnCircle() {
    if (!_isPlaying) return;

    final circleSize = _stressLevel.circleSize;
    // Calculate safe boundaries (percentage-based, accounting for circle size)
    final maxX = 100 - (circleSize / 3);
    final maxY = 100 - (circleSize / 3);

    final newCircle = TappingCircle(
      id: DateTime.now().millisecondsSinceEpoch,
      x: _random.nextDouble() * (maxX - 10) + 5,
      y: _random.nextDouble() * (maxY - 10) + 5,
      color: _circleColors[_random.nextInt(_circleColors.length)],
    );

    // Create animation controller for this circle
    final controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _circleAnimControllers[newCircle.id] = controller;
    controller.forward();

    setState(() {
      _circles.add(newCircle);
    });

    // Auto-remove after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      _removeCircle(newCircle.id, tapped: false);
    });
  }

  void _removeCircle(int id, {required bool tapped}) {
    final controller = _circleAnimControllers[id];
    if (controller != null) {
      controller.reverse().then((_) {
        controller.dispose();
        _circleAnimControllers.remove(id);
        if (mounted) {
          setState(() {
            _circles.removeWhere((c) => c.id == id);
          });
        }
      });
    } else {
      if (mounted) {
        setState(() {
          _circles.removeWhere((c) => c.id == id);
        });
      }
    }
  }

  void _onCircleTap(int id) {
    setState(() {
      _score++;
    });
    _removeCircle(id, tapped: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE8E0F0), // Light purple top
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App Bar
              _buildAppBar(),

              // Game Area
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: _buildGameArea(),
                ),
              ),

              // Instructions
              _buildInstructions(),

              // Pause Button (when playing)
              if (_isPlaying) _buildPauseButton(),

              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button
          GestureDetector(
            onTap: () {
              _stopGame();
              Navigator.pop(context);
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppColors.background,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back,
                color: AppColors.textPrimary,
                size: 20,
              ),
            ),
          ),

          // Title & Score
          Column(
            children: [
              Text(
                'Mindful Tapping',
                style: AppTextStyles.h4.copyWith(fontSize: 18),
              ),
              Text(
                'Tapped: $_score',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),

          // Reset button
          GestureDetector(
            onTap: _resetGame,
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppColors.background,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.refresh,
                color: AppColors.textPrimary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameArea() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border, width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            // Circles
            ..._circles.map((circle) => _buildCircle(circle)),

            // Start Screen (when not playing and no circles)
            if (!_isPlaying && _circles.isEmpty) _buildStartScreen(),
          ],
        ),
      ),
    );
  }

  Widget _buildCircle(TappingCircle circle) {
    final controller = _circleAnimControllers[circle.id];
    final size = _stressLevel.circleSize;

    return Positioned(
      left: 0,
      top: 0,
      right: 0,
      bottom: 0,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final xPos = (circle.x / 100) * constraints.maxWidth - (size / 2);
          final yPos = (circle.y / 100) * constraints.maxHeight - (size / 2);

          return Stack(
            children: [
              Positioned(
                left: xPos.clamp(0, constraints.maxWidth - size),
                top: yPos.clamp(0, constraints.maxHeight - size),
                child: controller != null
                    ? ScaleTransition(
                        scale: CurvedAnimation(
                          parent: controller,
                          curve: Curves.elasticOut,
                        ),
                        child: _buildCircleButton(circle, size),
                      )
                    : _buildCircleButton(circle, size),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCircleButton(TappingCircle circle, double size) {
    return GestureDetector(
      onTap: () => _onCircleTap(circle.id),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: circle.color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: circle.color.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Stress Level Selector
          _buildStressLevelSelector(),

          const SizedBox(height: AppSpacing.xl),

          Text(
            'Tap the circles as they appear',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Start Button
          GestureDetector(
            onTap: _startGame,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: AppRadius.lgBorder,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.play_arrow, color: Colors.white, size: 24),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Start',
                    style: AppTextStyles.button.copyWith(fontSize: 18),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStressLevelSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: AppRadius.lgBorder,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.monitor_heart_outlined,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'STRESS LEVEL (TEST MODE)',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Stress Level Buttons
          Row(
            children: TappingStressLevel.values.map((level) {
              final isSelected = _stressLevel == level;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: level != TappingStressLevel.low ? AppSpacing.sm : 0,
                  ),
                  child: GestureDetector(
                    onTap: () => _onStressLevelChanged(level),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.sm + 2,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? level.color : AppColors.surface,
                        borderRadius: AppRadius.smBorder,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: level.color.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          level.label,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: isSelected
                                ? Colors.white
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.md),

          // Adaptive Info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Adaptive Rhythm:',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                _stressLevel.description,
                style: AppTextStyles.bodySmall.copyWith(
                  color: _stressLevel.color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInstructions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        children: [
          Text(
            'Focus on the rhythm. Breathe with each tap.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Rhythm adapts to your stress level • No pressure',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint),
          ),
        ],
      ),
    );
  }

  Widget _buildPauseButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: GestureDetector(
        onTap: _pauseGame,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: AppRadius.mdBorder,
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.pause, color: AppColors.textPrimary, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Pause',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
