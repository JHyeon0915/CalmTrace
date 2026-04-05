import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

enum GaugeDataState { loading, noData, hasData }

class StressGauge extends StatefulWidget {
  /// Null = no data available. Never pass a fake default number.
  final int? level;
  final int maxLevel;
  final double size;
  final double strokeWidth;
  final GaugeDataState dataState;
  final String? dataSourceLabel; // e.g. "Apple Health", "EMOTIV", "Demo"

  const StressGauge({
    super.key,
    required this.level,
    required this.maxLevel,
    this.size = 160,
    this.strokeWidth = 16,
    this.dataState = GaugeDataState.hasData,
    this.dataSourceLabel,
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

    final effectiveLevel = widget.level;
    _animation = Tween<double>(
      begin: 0,
      end: effectiveLevel != null ? effectiveLevel / widget.maxLevel : 0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    if (widget.dataState == GaugeDataState.hasData) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(StressGauge oldWidget) {
    super.didUpdateWidget(oldWidget);

    final newLevel = widget.level;
    final oldLevel = oldWidget.level;

    if (oldLevel != newLevel || oldWidget.dataState != widget.dataState) {
      _animation =
          Tween<double>(
            begin: _animation.value,
            end: newLevel != null && widget.dataState == GaugeDataState.hasData
                ? newLevel / widget.maxLevel
                : 0,
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
    switch (widget.dataState) {
      case GaugeDataState.loading:
        return _buildLoadingState();
      case GaugeDataState.noData:
        return _buildNoDataState();
      case GaugeDataState.hasData:
        return _buildGauge();
    }
  }

  // ──────────────────────────────────────────────────────────
  // States
  // ──────────────────────────────────────────────────────────

  Widget _buildLoadingState() {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: widget.size,
            height: widget.size,
            child: CircularProgressIndicator(
              strokeWidth: widget.strokeWidth,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(
                AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Reading...',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: widget.size * 0.08,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoDataState() {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Dashed/muted track
          SizedBox(
            width: widget.size,
            height: widget.size,
            child: CircularProgressIndicator(
              value: 1,
              strokeWidth: widget.strokeWidth,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(
                AppColors.border.withValues(alpha: 0.5),
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.sensors_off_outlined,
                color: AppColors.textHint,
                size: widget.size * 0.22,
              ),
              const SizedBox(height: 6),
              Text(
                'No data',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textHint,
                  fontWeight: FontWeight.w600,
                  fontSize: widget.size * 0.1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Connect a device',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textHint,
                  fontSize: widget.size * 0.075,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGauge() {
    final level = widget.level;
    if (level == null) return _buildNoDataState();

    final color = _getStressColor(level);
    final label = _getStressLabel(level);

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
              // Center content
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
                  if (widget.dataSourceLabel != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      widget.dataSourceLabel!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textHint,
                        fontSize: widget.size * 0.07,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
