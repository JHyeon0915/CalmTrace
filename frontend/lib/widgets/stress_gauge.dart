import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class StressGauge extends StatefulWidget {
  final int level;
  final int maxLevel;
  final double size;
  final double strokeWidth;

  const StressGauge({
    super.key,
    required this.level,
    required this.maxLevel,
    this.size = 160,
    this.strokeWidth = 16,
  });

  @override
  State<StressGauge> createState() => _StressGaugeState();
}

class _StressGaugeState extends State<StressGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  Color _getStressColor(int level) {
    if (level <= 40) return AppColors.stressLow;
    if (level <= 70) return AppColors.stressMedium;
    return AppColors.stressHigh;
  }

  String _getStressLabel(int level) {
    if (level <= 40) return 'Low Stress';
    if (level <= 70) return 'Medium Stress';
    return 'High Stress';
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0,
      end: widget.level / widget.maxLevel,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void didUpdateWidget(StressGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.level != widget.level) {
      _animation =
          Tween<double>(
            begin: _animation.value,
            end: widget.level / widget.maxLevel,
          ).animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
          );
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = _getStressColor(widget.level);
    final label = _getStressLabel(widget.level);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final animatedLevel = (_animation.value * widget.maxLevel).toInt();
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background track
              SizedBox(
                width: widget.size,
                height: widget.size,
                child: CircularProgressIndicator(
                  value: 1,
                  strokeWidth: widget.strokeWidth,
                  backgroundColor: AppColors.border,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.border),
                ),
              ),
              // Animated progress arc
              SizedBox(
                width: widget.size,
                height: widget.size,
                child: CircularProgressIndicator(
                  value: _animation.value,
                  strokeWidth: widget.strokeWidth,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  strokeCap: StrokeCap.round,
                ),
              ),
              // Center text
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$animatedLevel',
                    style: AppTextStyles.h1.copyWith(
                      fontSize: widget.size * 0.3,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    label,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: widget.size * 0.09,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
