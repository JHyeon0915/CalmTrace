import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class CognitiveReframingScreen extends StatefulWidget {
  const CognitiveReframingScreen({super.key});

  @override
  State<CognitiveReframingScreen> createState() =>
      _CognitiveReframingScreenState();
}

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

    // Icon animation controller
    _iconController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Content animation controller (for staggered text and button)
    _contentController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Icon animations
    _iconScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _iconController, curve: Curves.elasticOut),
    );

    _iconFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _iconController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    // Title animations
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

    // Subtitle animations
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

    // Button animations
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

    // Start animations
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
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: const Color(0xFF8FB996).withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_outline,
                        color: Color(0xFF8FB996),
                        size: 64,
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
                    child: Text('Well Done!', style: AppTextStyles.h2),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Animated subtitle
                SlideTransition(
                  position: _subtitleSlideAnimation,
                  child: FadeTransition(
                    opacity: _subtitleFadeAnimation,
                    child: Text(
                      "You've practiced reframing a negative thought. This skill gets easier with practice.",
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
                          'Return to Therapy Hub',
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

class _CognitiveReframingScreenState extends State<CognitiveReframingScreen> {
  int _currentStep = 0;
  final List<TextEditingController> _controllers = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];

  final List<ReframingStep> _steps = [
    ReframingStep(
      title: 'Identify the Thought',
      prompt: 'What negative thought is bothering you right now?',
      placeholder: "e.g., 'I'm not good enough' or 'I always mess things up'",
      helper: 'Be specific and honest. This is just for you.',
    ),
    ReframingStep(
      title: 'Challenge the Thought',
      prompt: 'Is this thought based on facts or feelings?',
      placeholder:
          "e.g., 'This is a feeling, not a fact. I've succeeded before.'",
      helper: 'Look for evidence that contradicts this thought.',
    ),
    ReframingStep(
      title: 'Reframe Positively',
      prompt: "What's a more balanced, realistic way to think about this?",
      placeholder:
          "e.g., 'I'm learning and growing. Mistakes are part of progress.'",
      helper: 'Be kind to yourself. What would you tell a friend?',
    ),
  ];

  bool get _isCompleted => _currentStep >= _steps.length;

  bool get _canProceed => _controllers[_currentStep].text.trim().isNotEmpty;

  void _handleNext() {
    if (_currentStep < _steps.length - 1) {
      setState(() {
        _currentStep++;
      });
    }
  }

  void _handleBack() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  void _handleComplete() {
    setState(() {
      _currentStep = _steps.length;
    });
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isCompleted) {
      return _buildCompletionScreen();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: AppRadius.roundBorder,
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: AppColors.textPrimary,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Cognitive Reframing', style: AppTextStyles.h3),
                        Text(
                          'Step ${_currentStep + 1} of ${_steps.length}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Progress Bar
              Row(
                children: List.generate(_steps.length, (index) {
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: EdgeInsets.only(
                        right: index < _steps.length - 1 ? AppSpacing.sm : 0,
                      ),
                      decoration: BoxDecoration(
                        color: index <= _currentStep
                            ? const Color(0xFF8FB996)
                            : AppColors.border,
                        borderRadius: AppRadius.smBorder,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Content
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _buildStepContent(_steps[_currentStep]),
                ),
              ),

              // Buttons
              _buildButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent(ReframingStep step) {
    return Column(
      key: ValueKey(_currentStep),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Instruction Card
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: const Color(0xFF8FB996).withValues(alpha: 0.05),
            borderRadius: AppRadius.lgBorder,
            border: Border.all(
              color: const Color(0xFF8FB996).withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF8FB996).withValues(alpha: 0.2),
                  borderRadius: AppRadius.mdBorder,
                ),
                child: const Icon(
                  Icons.lightbulb_outline,
                  color: Color(0xFF8FB996),
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.title,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      step.prompt,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Text Input
        Container(
          height: 140,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: AppRadius.lgBorder,
            border: Border.all(color: AppColors.border),
          ),
          child: TextField(
            controller: _controllers[_currentStep],
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: step.placeholder,
              hintStyle: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              contentPadding: const EdgeInsets.all(AppSpacing.md),
              border: InputBorder.none,
            ),
            style: AppTextStyles.bodyMedium,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            step.helper,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildButtons() {
    return Row(
      children: [
        if (_currentStep > 0)
          Expanded(
            child: TextButton(
              onPressed: _handleBack,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              ),
              child: Text(
                'Back',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
        if (_currentStep > 0) const SizedBox(width: AppSpacing.md),
        Expanded(
          flex: _currentStep > 0 ? 2 : 1,
          child: ElevatedButton(
            onPressed: _canProceed
                ? (_currentStep < _steps.length - 1
                      ? _handleNext
                      : _handleComplete)
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              shape: RoundedRectangleBorder(borderRadius: AppRadius.mdBorder),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _currentStep < _steps.length - 1 ? 'Next' : 'Complete',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (_currentStep < _steps.length - 1) ...[
                  const SizedBox(width: AppSpacing.sm),
                  const Icon(Icons.arrow_forward, size: 18),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompletionScreen() {
    return _CompletionScreen(onReturn: () => Navigator.pop(context));
  }
}

class ReframingStep {
  final String title;
  final String prompt;
  final String placeholder;
  final String helper;

  ReframingStep({
    required this.title,
    required this.prompt,
    required this.placeholder,
    required this.helper,
  });
}
