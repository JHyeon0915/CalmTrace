import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import '../constants/app_constants.dart';
import '../widgets/rhythm_flow/rhythm_app_bar.dart';
import '../widgets/stress_level_selector.dart';
import '../widgets/rhythm_flow/song_progress_bar.dart';
import '../widgets/rhythm_flow/rhythm_tap_button.dart';
import '../widgets/rhythm_flow/game_controls.dart';
import 'game_completion_screen.dart';

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
        return 55;
      case RhythmStressLevel.medium:
        return 80;
      case RhythmStressLevel.low:
        return 100;
    }
  }

  int get intervalMs {
    switch (this) {
      case RhythmStressLevel.high:
        return 1091;
      case RhythmStressLevel.medium:
        return 750;
      case RhythmStressLevel.low:
        return 600;
    }
  }

  int get pointMultiplier {
    switch (this) {
      case RhythmStressLevel.high:
        return 2;
      case RhythmStressLevel.medium:
        return 1;
      case RhythmStressLevel.low:
        return 1;
    }
  }

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
  bool _isComplete = false;
  int _score = 0;
  int _streak = 0;
  int? _activeButton;
  Timer? _beatTimer;
  final Random _random = Random();

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isMusicPlaying = false;
  bool _isMusicEnabled = true;

  Duration _songDuration = Duration.zero;
  Duration _songPosition = Duration.zero;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _durationSubscription;
  StreamSubscription? _completionSubscription;

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
    _audioPlayer.setReleaseMode(ReleaseMode.stop);
    _audioPlayer.setVolume(0.5);

    _positionSubscription = _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) setState(() => _songPosition = position);
    });
    _durationSubscription = _audioPlayer.onDurationChanged.listen((duration) {
      if (mounted) setState(() => _songDuration = duration);
    });
    _completionSubscription = _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted && _isPlaying) _endGame();
    });
  }

  void _setupPulseAnimation() {
    _pulseController = AnimationController(vsync: this);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController!, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _beatTimer?.cancel();
    _pulseController?.dispose();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _completionSubscription?.cancel();
    _audioPlayer.stop();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      _isPlaying = true;
      _isComplete = false;
      _activeButton = null;
      _score = 0;
      _streak = 0;
      _songPosition = Duration.zero;
      _songDuration = Duration.zero;
    });
    _startBeatLoop();
    _playMusic();
  }

  void _endGame() {
    _beatTimer?.cancel();
    _audioPlayer.stop();
    setState(() {
      _isPlaying = false;
      _isComplete = true;
      _isMusicPlaying = false;
    });
  }

  Future<void> _playMusic() async {
    if (!_isMusicEnabled) return;
    try {
      await _audioPlayer.play(AssetSource(_stressLevel.musicAsset));
      setState(() => _isMusicPlaying = true);
    } catch (e) {
      debugPrint('Failed to load music: $e');
    }
  }

  Future<void> _stopMusic() async {
    await _audioPlayer.stop();
    setState(() => _isMusicPlaying = false);
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
      _isComplete = false;
      _score = 0;
      _streak = 0;
      _activeButton = null;
      _songPosition = Duration.zero;
      _songDuration = Duration.zero;
    });
  }

  void _onStressLevelChanged(RhythmStressLevel level) {
    if (level != _stressLevel) {
      _resetGame();
      setState(() => _stressLevel = level);
    }
  }

  void _startBeatLoop() {
    _pulseController?.duration = Duration(
      milliseconds: (_stressLevel.intervalMs * 0.25).toInt(),
    );
    _beatTimer = Timer.periodic(
      Duration(milliseconds: _stressLevel.intervalMs),
      (_) => _triggerBeat(),
    );
  }

  void _triggerBeat() {
    if (!_isPlaying) return;

    // Select random button
    final nextButton = _random.nextInt(4);

    // Clear previous, set new active
    setState(() => _activeButton = nextButton);

    // Start pulse animation
    _pulseController?.forward();

    // Haptic feedback on beat
    HapticFeedback.lightImpact();

    // Window lasts until just before the next beat
    final windowMs = (_stressLevel.intervalMs * 0.9).toInt();

    // Beat window - if not tapped in time, reset streak (for low stress mode)
    Future.delayed(Duration(milliseconds: windowMs), () {
      if (_activeButton == nextButton && mounted) {
        // Missed the beat
        if (_stressLevel == RhythmStressLevel.low) setState(() => _streak = 0);
        setState(() => _activeButton = null);
        _pulseController?.reverse();
      }
    });
  }

  void _onButtonPress(int id) {
    if (!_isPlaying) return;
    if (_activeButton == id) {
      setState(() {
        _score += _stressLevel.pointMultiplier;
        _activeButton = null;

        // Streak bonus every 5 streak for low stress mode
        if (_stressLevel == RhythmStressLevel.low) {
          _streak++;
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
            const Text('Streak Bonus! +5 points'),
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
    // Show game completion screen when song completes
    if (_isComplete) {
      return GameCompletionScreen(
        gameName: 'Rhythm Flow',
        stats: [
          GameStat(label: 'Score', value: '$_score'),
          GameStat(label: 'Stress Level', value: _stressLevel.label),
        ],
        onReturn: () => Navigator.pop(context),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFDF6E3), Colors.white],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              RhythmAppBar(
                score: _score,
                streak: _streak,
                stressLevel: _stressLevel,
                isMusicEnabled: _isMusicEnabled,
                onBack: () {
                  _resetGame();
                  Navigator.pop(context);
                },
                onMusicToggle: () {
                  setState(() => _isMusicEnabled = !_isMusicEnabled);
                  if (_isPlaying) {
                    _isMusicEnabled ? _playMusic() : _stopMusic();
                  }
                },
                onReset: _resetGame,
              ),
              const SizedBox(height: AppSpacing.md),
              if (!_isPlaying && !_isComplete)
                StressLevelSelector(
                  selected: _stressLevel,
                  onChanged: _onStressLevelChanged,
                ),
              if (_isPlaying)
                SongProgressBar(
                  position: _songPosition,
                  duration: _songDuration,
                  stressLevel: _stressLevel,
                ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: AppSpacing.lg),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl,
                        ),
                        child: SizedBox(
                          width: 280,
                          height: 280,
                          child: GridView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 16,
                                  crossAxisSpacing: 16,
                                ),
                            itemCount: 4,
                            itemBuilder: (context, index) {
                              final button = _buttons[index];
                              return RhythmTapButton(
                                button: button,
                                isActive: _activeButton == button.id,
                                pulseAnimation: _pulseAnimation!,
                                stressLevel: _stressLevel,
                                onTap: () => _onButtonPress(button.id),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      GameControls(
                        isPlaying: _isPlaying,
                        stressLevel: _stressLevel,
                        onStart: _startGame,
                        onPause: _pauseGame,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                  ),
                ),
              ),
              GameInstructions(stressLevel: _stressLevel),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}
