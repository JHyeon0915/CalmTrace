import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import '../constants/app_constants.dart';

enum RhythmStressLevel { high, medium, low }

extension RhythmStressLevelExtension on RhythmStressLevel {
  String get label {
    switch (this) {
      case RhythmStressLevel.high:
        return 'High';
      case RhythmStressLevel.medium:
        return 'Medium';
      case RhythmStressLevel.low:
        return 'Low';
    }
  }

  String get description {
    switch (this) {
      case RhythmStressLevel.high:
        return '55 BPM • 2× Points';
      case RhythmStressLevel.medium:
        return '80 BPM • Standard';
      case RhythmStressLevel.low:
        return '100 BPM • Streak Bonus';
    }
  }

  String get tempoLabel {
    switch (this) {
      case RhythmStressLevel.high:
        return 'Chill Acoustic';
      case RhythmStressLevel.medium:
        return 'Gentle Piano';
      case RhythmStressLevel.low:
        return 'Upbeat Vibes';
    }
  }

  Color get color {
    switch (this) {
      case RhythmStressLevel.high:
        return const Color(0xFFE89B9B);
      case RhythmStressLevel.medium:
        return const Color(0xFFF0B67F);
      case RhythmStressLevel.low:
        return const Color(0xFF7BC67E);
    }
  }

  int get bpm {
    switch (this) {
      case RhythmStressLevel.high:
        return 55; // Chill acoustic guitar
      case RhythmStressLevel.medium:
        return 80; // Touching piano
      case RhythmStressLevel.low:
        return 100; // Technology vibes
    }
  }

  int get intervalMs {
    // interval = 60000 / BPM (milliseconds per beat)
    switch (this) {
      case RhythmStressLevel.high:
        return 1091; // 60000/55 = ~1091ms per beat
      case RhythmStressLevel.medium:
        return 750; // 60000/80 = 750ms per beat
      case RhythmStressLevel.low:
        return 600; // 60000/100 = 600ms per beat
    }
  }

  int get pointMultiplier {
    switch (this) {
      case RhythmStressLevel.high:
        return 2; // Double points for calm focus
      case RhythmStressLevel.medium:
        return 1;
      case RhythmStressLevel.low:
        return 1;
    }
  }

  /// Local audio assets (place MP3 files in assets/audio/)
  /// - slow.mp3: Chill acoustic guitar 55 BPM (High stress)
  /// - medium.mp3: Touching piano 80 BPM (Medium stress)
  /// - fast.mp3: Technology vibes 100 BPM (Low stress)
  String get musicAsset {
    switch (this) {
      case RhythmStressLevel.high:
        return 'audio/slow.mp3';
      case RhythmStressLevel.medium:
        return 'audio/medium.mp3';
      case RhythmStressLevel.low:
        return 'audio/fast.mp3';
    }
  }
}

class RhythmButton {
  final int id;
  final Color color;
  final String label;

  const RhythmButton({
    required this.id,
    required this.color,
    required this.label,
  });
}

class RhythmFlowScreen extends StatefulWidget {
  const RhythmFlowScreen({super.key});

  @override
  State<RhythmFlowScreen> createState() => _RhythmFlowScreenState();
}

class _RhythmFlowScreenState extends State<RhythmFlowScreen>
    with TickerProviderStateMixin {
  RhythmStressLevel _stressLevel = RhythmStressLevel.medium;
  bool _isPlaying = false;
  int _score = 0;
  int _streak = 0;
  int _beatCount = 0;
  int? _activeButton;
  Timer? _beatTimer;
  final Random _random = Random();

  // Audio player for background music
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isMusicPlaying = false;
  bool _isMusicEnabled = true;

  // Animation controller for active button
  AnimationController? _pulseController;
  Animation<double>? _pulseAnimation;

  final List<RhythmButton> _buttons = const [
    RhythmButton(id: 0, color: Color(0xFF6B9BD1), label: 'Calm'),
    RhythmButton(id: 1, color: Color(0xFF8FB996), label: 'Peace'),
    RhythmButton(id: 2, color: Color(0xFFB4A7D6), label: 'Flow'),
    RhythmButton(id: 3, color: Color(0xFFF0B67F), label: 'Ease'),
  ];

  @override
  void initState() {
    super.initState();
    _setupPulseAnimation();
    _setupAudioPlayer();
  }

  void _setupAudioPlayer() {
    _audioPlayer.setReleaseMode(ReleaseMode.loop);
    _audioPlayer.setVolume(0.5);
  }

  void _setupPulseAnimation() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController!, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _beatTimer?.cancel();
    _pulseController?.dispose();
    _audioPlayer.stop();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      _isPlaying = true;
      _activeButton = null;
    });
    _startBeatLoop();
    _playMusic();
  }

  Future<void> _playMusic() async {
    if (!_isMusicEnabled) return;

    try {
      await _audioPlayer.play(AssetSource(_stressLevel.musicAsset));
      setState(() {
        _isMusicPlaying = true;
      });
    } catch (e) {
      // Music failed to load, continue without it
      debugPrint('Failed to load music: $e');
    }
  }

  Future<void> _stopMusic() async {
    await _audioPlayer.stop();
    setState(() {
      _isMusicPlaying = false;
    });
  }

  void _pauseGame() {
    _beatTimer?.cancel();
    _audioPlayer.pause();
    setState(() {
      _isPlaying = false;
      _activeButton = null;
      _isMusicPlaying = false;
    });
  }

  void _resetGame() {
    _beatTimer?.cancel();
    _pulseController?.reset();
    _stopMusic();
    setState(() {
      _isPlaying = false;
      _score = 0;
      _streak = 0;
      _beatCount = 0;
      _activeButton = null;
    });
  }

  void _onStressLevelChanged(RhythmStressLevel level) {
    if (level != _stressLevel) {
      _resetGame();
      setState(() {
        _stressLevel = level;
      });
    }
  }

  void _startBeatLoop() {
    _beatTimer = Timer.periodic(
      Duration(milliseconds: _stressLevel.intervalMs),
      (_) => _triggerBeat(),
    );
  }

  void _triggerBeat() {
    if (!_isPlaying) return;

    // Select random button
    final nextButton = _random.nextInt(4);

    setState(() {
      _activeButton = nextButton;
      _beatCount++;
    });

    // Start pulse animation
    _pulseController?.forward();

    // Haptic feedback on beat
    HapticFeedback.lightImpact();

    // Beat window - if not tapped in time, reset streak (for low stress mode)
    Future.delayed(const Duration(milliseconds: 400), () {
      if (_activeButton == nextButton && mounted) {
        // Missed the beat
        if (_stressLevel == RhythmStressLevel.low) {
          setState(() {
            _streak = 0;
          });
        }
        setState(() {
          _activeButton = null;
        });
        _pulseController?.reverse();
      }
    });
  }

  void _onButtonPress(int id) {
    if (!_isPlaying) return;

    if (_activeButton == id) {
      // Correct timing!
      final points = _stressLevel.pointMultiplier;

      setState(() {
        _score += points;
        _activeButton = null;

        // Streak bonus for low stress mode
        if (_stressLevel == RhythmStressLevel.low) {
          _streak++;
          // Bonus every 5 streak
          if (_streak % 5 == 0) {
            _score += 5;
            _showStreakBonus();
          }
        }
      });

      _pulseController?.reverse();

      // Success haptic
      HapticFeedback.mediumImpact();
    }
  }

  void _showStreakBonus() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bolt, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('Streak Bonus! +5 points'),
          ],
        ),
        backgroundColor: const Color(0xFF7BC67E),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height * 0.4,
          left: 50,
          right: 50,
        ),
      ),
    );
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
              Color(0xFFFDF6E3), // Warm cream/orange top
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App Bar
              _buildAppBar(),

              const SizedBox(height: AppSpacing.md),

              // Stress Level Selector (only when not playing)
              if (!_isPlaying) _buildStressLevelSelector(),

              // Game Area
              Expanded(child: _buildGameArea()),

              // Instructions
              _buildInstructions(),

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
              _resetGame();
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
                'Rhythm Flow',
                style: AppTextStyles.h4.copyWith(fontSize: 18),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Beat: $_beatCount',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (_stressLevel == RhythmStressLevel.low && _streak > 0) ...[
                    const SizedBox(width: 12),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.bolt,
                          size: 14,
                          color: const Color(0xFF7BC67E),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '$_streak streak',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: const Color(0xFF7BC67E),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ],
          ),

          // Music & Reset buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Music toggle
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isMusicEnabled = !_isMusicEnabled;
                  });
                  if (_isPlaying) {
                    if (_isMusicEnabled) {
                      _playMusic();
                    } else {
                      _stopMusic();
                    }
                  }
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _isMusicEnabled
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : AppColors.surface,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isMusicEnabled ? Icons.music_note : Icons.music_off,
                    color: _isMusicEnabled
                        ? AppColors.primary
                        : AppColors.textHint,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Reset button
              GestureDetector(
                onTap: _resetGame,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.refresh,
                    color: AppColors.textPrimary,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStressLevelSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
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
            children: RhythmStressLevel.values.map((level) {
              final isSelected = _stressLevel == level;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: level != RhythmStressLevel.low ? AppSpacing.sm : 0,
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
                'Adaptive Tempo:',
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

  Widget _buildGameArea() {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: AppSpacing.lg),

          // Score Display
          if (_isPlaying)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: Text(
                'Score: $_score',
                style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
              ),
            ),

          // 2x2 Button Grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: SizedBox(
              width: 280,
              height: 280,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                ),
                itemCount: 4,
                itemBuilder: (context, index) {
                  return _buildRhythmButton(_buttons[index]);
                },
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Start/Pause Controls
          if (!_isPlaying) ...[
            Text(
              'Tap the glowing button to match the rhythm',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${_stressLevel.bpm} BPM • ${_stressLevel.tempoLabel}',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textHint,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildStartButton(),
          ] else ...[
            _buildPauseButton(),
          ],

          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  Widget _buildRhythmButton(RhythmButton button) {
    final isActive = _activeButton == button.id;

    return GestureDetector(
      onTap: () => _onButtonPress(button.id),
      child: AnimatedBuilder(
        animation: _pulseAnimation!,
        builder: (context, child) {
          final scale = isActive ? _pulseAnimation!.value : 1.0;
          return Transform.scale(
            scale: scale,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                color: button.color.withValues(alpha: isActive ? 1.0 : 0.7),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: button.color.withValues(alpha: isActive ? 0.5 : 0.2),
                    blurRadius: isActive ? 20 : 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      button.label,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (isActive && _stressLevel == RhythmStressLevel.high) ...[
                      const SizedBox(height: 4),
                      Text(
                        '2×',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStartButton() {
    return GestureDetector(
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
              'Start Flow',
              style: AppTextStyles.button.copyWith(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPauseButton() {
    return GestureDetector(
      onTap: _pauseGame,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: AppRadius.mdBorder,
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
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
    );
  }

  Widget _buildInstructions() {
    String extraInfo = '';
    if (_stressLevel == RhythmStressLevel.high) {
      extraInfo = ' • Double points for calm focus';
    } else if (_stressLevel == RhythmStressLevel.low) {
      extraInfo = ' • Build streaks for bonuses';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        children: [
          Text(
            'Follow the gentle rhythm. Let it guide you.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Tempo adapts to your stress level$extraInfo',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
