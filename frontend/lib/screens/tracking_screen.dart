import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../services/health_data_service.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen>
    with TickerProviderStateMixin {
  final HealthDataService _healthService = HealthDataService();

  // State
  bool _isLoading = true;
  StressHealthData? _healthData;

  // Stress data (mock)
  int _stressLevel = 80;
  int _confidence = 82;
  String _trend = 'Stable';
  String _selectedRange = '1d';
  bool _analysisExpanded = false;

  // Animation controllers
  late AnimationController _gaugeController;
  late Animation<double> _gaugeAnimation;

  final List<Map<String, String>> _timeRanges = [
    {'value': '1d', 'label': '1 day'},
    {'value': '2d', 'label': '2 days'},
    {'value': '3d', 'label': '3 days'},
    {'value': '7d', 'label': '7 days'},
    {'value': '30d', 'label': '30 days'},
  ];

  // Mock stress data - only 10 days of data available
  final List<int> _mockDailyData = [65, 58, 52, 48, 45, 42, 40, 38, 36, 35];

  // Stream subscriptions
  StreamSubscription<HealthConnectionStatus>? _statusSubscription;
  StreamSubscription<StressHealthData>? _dataSubscription;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _setupListeners();
    _loadData();
  }

  void _setupAnimations() {
    _gaugeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _gaugeAnimation = Tween<double>(begin: 0, end: _stressLevel / 100).animate(
      CurvedAnimation(parent: _gaugeController, curve: Curves.easeOutCubic),
    );
  }

  void _setupListeners() {
    _statusSubscription = _healthService.statusStream.listen((status) {
      debugPrint('🔔 [TrackingScreen] Status: ${status.label}');
    });

    _dataSubscription = _healthService.dataStream.listen((data) {
      debugPrint('🔔 [TrackingScreen] New health data received');
      if (mounted) {
        setState(() => _healthData = data);
      }
    });
  }

  Future<void> _loadData() async {
    await _healthService.initialize();
    await _healthService.connect(context, forceMock: true);
    final data = await _healthService.fetchHealthData(hours: 24);

    if (mounted) {
      setState(() {
        _healthData = data;
        _isLoading = false;
      });
      _gaugeController.forward();
    }
  }

  @override
  void dispose() {
    _gaugeController.dispose();
    _statusSubscription?.cancel();
    _dataSubscription?.cancel();
    super.dispose();
  }

  // Get data points based on selected range
  List<int> _getDataPoints() {
    switch (_selectedRange) {
      case '1d':
        return [38, 42, 35, 40, 35];
      case '2d':
        return [42, 38, 35, 40, 35];
      case '3d':
        return _mockDailyData.sublist(7, 10).toList();
      case '7d':
        return _mockDailyData.sublist(3, 10).toList();
      case '30d':
        // 30 days - only 10 days have data, rest is 0
        List<int> data = List<int>.filled(20, 0);
        data = [...data, ..._mockDailyData];
        return data;
      default:
        return _mockDailyData.sublist(7, 10).toList();
    }
  }

  List<String> _getLabels() {
    switch (_selectedRange) {
      case '1d':
        return ['3am', '9am', '3pm', '9pm', 'Now'];
      case '2d':
        return ['Yesterday AM', 'Yesterday PM', 'Today AM', 'Today PM', 'Now'];
      case '3d':
        return ['2 days ago', 'Yesterday', 'Today'];
      case '7d':
        return ['6d', '5d', '4d', '3d', '2d', '1d', 'Today'];
      case '30d':
        return ['30d', '20d', '10d', 'Today'];
      default:
        return [];
    }
  }

  String _getRangeDescription() {
    switch (_selectedRange) {
      case '1d':
        return 'Your stress levels today';
      case '2d':
        return 'Last 2 days of stress patterns';
      case '3d':
        return 'Last 3 days overview';
      case '7d':
        return 'Your week at a glance';
      case '30d':
        return 'Monthly stress overview';
      default:
        return '';
    }
  }

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

  Color _getConfidenceColor(int confidence) {
    if (confidence > 70) return const Color(0xFF68D391);
    if (confidence > 30) return const Color(0xFFF6B93B);
    return const Color(0xFFE57373);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppSpacing.lg),

                      // Header
                      Text('Stress Tracking', style: AppTextStyles.h2),
                      const SizedBox(height: 4),
                      Text(
                        'Monitor your stress biomarkers',
                        style: AppTextStyles.bodyMedium,
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Stress Gauge Card
                      _buildStressGaugeCard(),
                      const SizedBox(height: AppSpacing.lg),

                      // Analysis Section
                      Text(
                        'Analysis',
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _buildAnalysisHeader(),
                      if (_analysisExpanded) _buildAnalysisContent(),
                      const SizedBox(height: AppSpacing.lg),

                      // Trend Chart Card
                      _buildTrendCard(),
                      const SizedBox(height: AppSpacing.xl),

                      // Disclaimer
                      Center(
                        child: Text(
                          'This data is for informational purposes only and is not a medical diagnosis.',
                          style: AppTextStyles.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildStressGaugeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: AppRadius.lgBorder,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Stress Gauge
          AnimatedBuilder(
            animation: _gaugeAnimation,
            builder: (context, child) {
              return _StressGauge(
                level: (_gaugeAnimation.value * 100).toInt(),
                maxLevel: 100,
                color: _getStressColor(_stressLevel),
                label: _getStressLabel(_stressLevel),
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),

          // Trend indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Trend:',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                _trend,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          // Confidence Meter
          _buildConfidenceMeter(),
        ],
      ),
    );
  }

  Widget _buildConfidenceMeter() {
    final color = _getConfidenceColor(_confidence);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'AI Confidence',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              '$_confidence %',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                // Background
                Container(
                  height: 8,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                // Progress - properly calculated width
                AnimatedContainer(
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  height: 8,
                  width: constraints.maxWidth * (_confidence / 100),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color.withValues(alpha: 0.7), color],
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildAnalysisHeader() {
    return GestureDetector(
      onTap: () {
        setState(() => _analysisExpanded = !_analysisExpanded);
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: _analysisExpanded
              ? const BorderRadius.vertical(top: Radius.circular(12))
              : AppRadius.lgBorder,
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: AppColors.primary, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Why is this detected?',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            AnimatedRotation(
              turns: _analysisExpanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.keyboard_arrow_down,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisContent() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
        border: Border(
          left: BorderSide(color: AppColors.border),
          right: BorderSide(color: AppColors.border),
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Our multimodal AI analyzes several biomarkers to estimate stress levels.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // HRV Factor
          _buildFactorRow(
            icon: Icons.show_chart,
            iconColor: const Color(0xFFE89B9B),
            label: 'Heart Rate Variability (HRV)',
            percentage: 45,
            color: AppColors.primary,
            description:
                'Low variability detected, suggesting sympathetic nervous system activation.',
          ),
          const SizedBox(height: AppSpacing.lg),

          // RR Factor
          _buildFactorRow(
            icon: Icons.air,
            iconColor: AppColors.primary,
            label: 'Respiratory Rate',
            percentage: 30,
            color: AppColors.primary,
            description: 'Slightly elevated breathing rate observed.',
          ),
          const SizedBox(height: AppSpacing.lg),

          // EEG Factor
          _buildFactorRow(
            icon: Icons.psychology,
            iconColor: const Color(0xFFB4A7D6),
            label: 'EEG Patterns',
            percentage: 25,
            color: AppColors.primary,
            description:
                'Beta wave dominance indicating active thinking or focus.',
          ),
        ],
      ),
    );
  }

  Widget _buildFactorRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required int percentage,
    required Color color,
    required String description,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              '$percentage %',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        // Progress bar
        Stack(
          children: [
            Container(
              height: 6,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                return Container(
                  height: 6,
                  width: constraints.maxWidth * (percentage / 100),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          description,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildTrendCard() {
    final dataPoints = _getDataPoints();
    final labels = _getLabels();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: AppRadius.lgBorder,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trend',
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Time Range Selector
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _timeRanges.map((range) {
                final isSelected = _selectedRange == range['value'];
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _selectedRange = range['value']!);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF6B9BD1).withValues(alpha: 0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: isSelected
                            ? Border.all(
                                color: const Color(
                                  0xFF6B9BD1,
                                ).withValues(alpha: 0.3),
                              )
                            : null,
                      ),
                      child: Text(
                        range['label']!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isSelected
                              ? const Color(0xFF6B9BD1)
                              : AppColors.textSecondary,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Chart
          SizedBox(
            height: 180,
            child: _StressChart(
              dataPoints: dataPoints,
              labels: labels,
              selectedRange: _selectedRange,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Description
          Center(
            child: Text(
              _getRangeDescription(),
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textHint,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Stress Gauge Widget
class _StressGauge extends StatelessWidget {
  final int level;
  final int maxLevel;
  final Color color;
  final String label;

  const _StressGauge({
    required this.level,
    required this.maxLevel,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          SizedBox(
            width: 160,
            height: 160,
            child: CircularProgressIndicator(
              value: 1,
              strokeWidth: 16,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.border),
            ),
          ),
          // Progress arc - starts from top (12 o'clock)
          SizedBox(
            width: 160,
            height: 160,
            child: CircularProgressIndicator(
              value: level / maxLevel,
              strokeWidth: 16,
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
                '$level',
                style: AppTextStyles.h1.copyWith(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                label,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Custom Chart Widget
class _StressChart extends StatelessWidget {
  final List<int> dataPoints;
  final List<String> labels;
  final String selectedRange;

  const _StressChart({
    required this.dataPoints,
    required this.labels,
    required this.selectedRange,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: _ChartPainter(
            dataPoints: dataPoints,
            labels: labels,
            selectedRange: selectedRange,
          ),
        );
      },
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<int> dataPoints;
  final List<String> labels;
  final String selectedRange;

  _ChartPainter({
    required this.dataPoints,
    required this.labels,
    required this.selectedRange,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.isEmpty) return;

    const paddingLeft = 30.0;
    const paddingRight = 10.0;
    const paddingTop = 10.0;
    const paddingBottom = 25.0;

    final chartWidth = size.width - paddingLeft - paddingRight;
    final chartHeight = size.height - paddingTop - paddingBottom;

    // Draw Y-axis labels and grid lines
    final yAxisValues = [100, 75, 50, 25, 0];

    for (int i = 0; i < yAxisValues.length; i++) {
      final y = paddingTop + (i / (yAxisValues.length - 1)) * chartHeight;

      // Draw dashed grid line
      _drawDashedLine(
        canvas,
        Offset(paddingLeft, y),
        Offset(size.width - paddingRight, y),
        Paint()
          ..color = const Color(0xFFE8E8E8)
          ..strokeWidth = 1,
      );

      // Draw Y-axis label
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${yAxisValues[i]}',
          style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(5, y - textPainter.height / 2));
    }

    // Calculate points
    final stepX = dataPoints.length > 1
        ? chartWidth / (dataPoints.length - 1)
        : chartWidth;
    final points = <Offset>[];

    for (int i = 0; i < dataPoints.length; i++) {
      final x = paddingLeft + i * stepX;
      final normalizedValue = dataPoints[i] / 100;
      final y = paddingTop + chartHeight - (normalizedValue * chartHeight);
      points.add(Offset(x, y));
    }

    // Draw gradient fill
    if (points.length > 1) {
      final fillPath = Path();
      fillPath.moveTo(points.first.dx, paddingTop + chartHeight);
      fillPath.lineTo(points.first.dx, points.first.dy);

      for (int i = 0; i < points.length - 1; i++) {
        final current = points[i];
        final next = points[i + 1];
        final controlX = (current.dx + next.dx) / 2;

        fillPath.quadraticBezierTo(
          controlX,
          current.dy,
          controlX,
          (current.dy + next.dy) / 2,
        );
        fillPath.quadraticBezierTo(controlX, next.dy, next.dx, next.dy);
      }

      fillPath.lineTo(points.last.dx, paddingTop + chartHeight);
      fillPath.close();

      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF6B9BD1).withValues(alpha: 0.3),
            const Color(0xFF6B9BD1).withValues(alpha: 0.05),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

      canvas.drawPath(fillPath, fillPaint);
    }

    // Draw line
    if (points.length > 1) {
      final linePath = Path();
      linePath.moveTo(points.first.dx, points.first.dy);

      for (int i = 0; i < points.length - 1; i++) {
        final current = points[i];
        final next = points[i + 1];
        final controlX = (current.dx + next.dx) / 2;

        linePath.quadraticBezierTo(
          controlX,
          current.dy,
          controlX,
          (current.dy + next.dy) / 2,
        );
        linePath.quadraticBezierTo(controlX, next.dy, next.dx, next.dy);
      }

      final linePaint = Paint()
        ..color = const Color(0xFF6B9BD1)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      canvas.drawPath(linePath, linePaint);
    }

    // Draw data points
    final dotFillPaint = Paint()..color = Colors.white;
    final dotStrokePaint = Paint()
      ..color = const Color(0xFF6B9BD1)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (final point in points) {
      canvas.drawCircle(point, 4, dotFillPaint);
      canvas.drawCircle(point, 4, dotStrokePaint);
    }

    // Draw X-axis labels
    _drawXAxisLabels(canvas, size, points, paddingLeft, chartWidth);
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashWidth = 4.0;
    const dashSpace = 4.0;
    double distance = (end - start).distance;
    double drawn = 0;

    while (drawn < distance) {
      final segmentLength = min(dashWidth, distance - drawn);
      final t1 = drawn / distance;
      final t2 = (drawn + segmentLength) / distance;

      canvas.drawLine(
        Offset.lerp(start, end, t1)!,
        Offset.lerp(start, end, t2)!,
        paint,
      );
      drawn += dashWidth + dashSpace;
    }
  }

  void _drawXAxisLabels(
    Canvas canvas,
    Size size,
    List<Offset> points,
    double paddingLeft,
    double chartWidth,
  ) {
    List<String> displayLabels;
    List<int> labelIndices;

    if (selectedRange == '30d') {
      displayLabels = ['30d', '20d', '10d', 'Today'];
      labelIndices = [0, 9, 19, 29];
    } else {
      displayLabels = labels;
      if (points.isEmpty) return;

      final step = points.length > 1
          ? (points.length - 1) / (displayLabels.length - 1)
          : 0;
      labelIndices = List.generate(
        displayLabels.length,
        (i) => (i * step).round().clamp(0, points.length - 1),
      );
    }

    for (int i = 0; i < displayLabels.length; i++) {
      if (labelIndices[i] >= points.length) continue;

      final x = points[labelIndices[i]].dx;
      final textPainter = TextPainter(
        text: TextSpan(
          text: displayLabels[i],
          style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 9),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, size.height - 12),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) {
    return oldDelegate.dataPoints != dataPoints ||
        oldDelegate.selectedRange != selectedRange;
  }
}
