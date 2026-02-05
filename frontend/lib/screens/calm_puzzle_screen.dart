import 'dart:math';
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

enum StressLevel { high, medium, low }

extension StressLevelExtension on StressLevel {
  String get label {
    switch (this) {
      case StressLevel.high:
        return 'High';
      case StressLevel.medium:
        return 'Medium';
      case StressLevel.low:
        return 'Low';
    }
  }

  String get description {
    switch (this) {
      case StressLevel.high:
        return '3×3 Grid (Easier)';
      case StressLevel.medium:
        return '4×4 Grid (Standard)';
      case StressLevel.low:
        return '5×5 Grid (Challenging)';
    }
  }

  Color get color {
    switch (this) {
      case StressLevel.high:
        return const Color(0xFFE89B9B);
      case StressLevel.medium:
        return const Color(0xFFF0B67F);
      case StressLevel.low:
        return const Color(0xFF7BC67E);
    }
  }

  int get gridSize {
    switch (this) {
      case StressLevel.high:
        return 3;
      case StressLevel.medium:
        return 4;
      case StressLevel.low:
        return 5;
    }
  }
}

class CalmPuzzleScreen extends StatefulWidget {
  const CalmPuzzleScreen({super.key});

  @override
  State<CalmPuzzleScreen> createState() => _CalmPuzzleScreenState();
}

class _CalmPuzzleScreenState extends State<CalmPuzzleScreen>
    with SingleTickerProviderStateMixin {
  StressLevel _stressLevel = StressLevel.medium;
  List<int> _pieces = [];
  int _moves = 0;
  bool _isComplete = false;
  int? _selectedIndex;

  late AnimationController _completeAnimController;
  late Animation<double> _completeAnimation;

  @override
  void initState() {
    super.initState();
    _completeAnimController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _completeAnimation = CurvedAnimation(
      parent: _completeAnimController,
      curve: Curves.elasticOut,
    );
    _shuffle();
  }

  @override
  void dispose() {
    _completeAnimController.dispose();
    super.dispose();
  }

  void _shuffle() {
    final totalPieces = _stressLevel.gridSize * _stressLevel.gridSize;
    _pieces = List.generate(totalPieces, (i) => i);

    // Fisher-Yates shuffle
    final random = Random();
    for (int i = _pieces.length - 1; i > 0; i--) {
      int j = random.nextInt(i + 1);
      int temp = _pieces[i];
      _pieces[i] = _pieces[j];
      _pieces[j] = temp;
    }

    setState(() {
      _moves = 0;
      _isComplete = false;
      _selectedIndex = null;
    });
    _completeAnimController.reset();
  }

  void _onStressLevelChanged(StressLevel level) {
    if (level != _stressLevel) {
      setState(() {
        _stressLevel = level;
      });
      _shuffle();
    }
  }

  void _onPieceTap(int index) {
    if (_isComplete) return;

    setState(() {
      if (_selectedIndex == null) {
        // First selection
        _selectedIndex = index;
      } else if (_selectedIndex == index) {
        // Deselect
        _selectedIndex = null;
      } else {
        // Swap pieces
        final temp = _pieces[_selectedIndex!];
        _pieces[_selectedIndex!] = _pieces[index];
        _pieces[index] = temp;
        _selectedIndex = null;
        _moves++;

        // Check completion
        _checkCompletion();
      }
    });
  }

  void _checkCompletion() {
    bool complete = true;
    for (int i = 0; i < _pieces.length; i++) {
      if (_pieces[i] != i) {
        complete = false;
        break;
      }
    }

    if (complete) {
      setState(() {
        _isComplete = true;
      });
      _completeAnimController.forward();
    }
  }

  Color _getPieceColor(int pieceValue) {
    final totalPieces = _stressLevel.gridSize * _stressLevel.gridSize;
    final hue = (pieceValue / totalPieces) * 360;
    final lightness = 0.75 - (pieceValue / totalPieces) * 0.25;
    return HSLColor.fromAHSL(1.0, hue, 0.6, lightness).toColor();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F4F8),
      body: SafeArea(
        child: Column(
          children: [
            // App Bar
            _buildAppBar(),

            // Test Mode Selector
            _buildStressLevelSelector(),

            // Puzzle Area
            Expanded(child: _buildPuzzleArea()),
          ],
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
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
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

          // Title & Moves
          Column(
            children: [
              Text(
                'Calm Puzzle',
                style: AppTextStyles.h4.copyWith(fontSize: 18),
              ),
              Text(
                'Moves: $_moves',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),

          // Reset button
          GestureDetector(
            onTap: _shuffle,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
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

  Widget _buildStressLevelSelector() {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
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
            children: StressLevel.values.map((level) {
              final isSelected = _stressLevel == level;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: level != StressLevel.low ? AppSpacing.sm : 0,
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

          // Adaptive Difficulty Info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Adaptive Difficulty:',
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

  Widget _buildPuzzleArea() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Completion Message
        if (_isComplete)
          ScaleTransition(
            scale: _completeAnimation,
            child: Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.lg),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF7BC67E).withValues(alpha: 0.1),
                borderRadius: AppRadius.lgBorder,
                border: Border.all(
                  color: const Color(0xFF7BC67E).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Color(0xFF2F6B32),
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Puzzle Complete! Well done.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: const Color(0xFF2F6B32),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Puzzle Grid
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.background.withValues(alpha: 0.8),
            borderRadius: AppRadius.lgBorder,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: _buildGrid(),
        ),

        const SizedBox(height: AppSpacing.lg),

        // Instructions
        Text(
          'Tap pieces to swap and arrange them in order',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Grid adapts to your stress level • No pressure, no timer',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint),
        ),
      ],
    );
  }

  Widget _buildGrid() {
    final gridSize = _stressLevel.gridSize;
    final puzzleSize = gridSize == 3
        ? 240.0
        : gridSize == 4
        ? 280.0
        : 300.0;
    final pieceSize = (puzzleSize - (gridSize - 1) * 8) / gridSize;

    return SizedBox(
      width: puzzleSize,
      height: puzzleSize,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: gridSize,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
        ),
        itemCount: _pieces.length,
        itemBuilder: (context, index) {
          final pieceValue = _pieces[index];
          final isSelected = _selectedIndex == index;
          final isCorrect = pieceValue == index;

          return GestureDetector(
            onTap: () => _onPieceTap(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                color: _getPieceColor(pieceValue),
                borderRadius: BorderRadius.circular(12),
                border: isSelected
                    ? Border.all(color: Colors.white, width: 3)
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: _getPieceColor(pieceValue).withValues(alpha: 0.4),
                    blurRadius: isSelected ? 12 : 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              transform: isSelected
                  ? (Matrix4.identity()..scale(1.05))
                  : Matrix4.identity(),
              transformAlignment: Alignment.center,
              child: Center(
                child: Text(
                  '${pieceValue + 1}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: gridSize == 5
                        ? 16
                        : gridSize == 4
                        ? 20
                        : 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
