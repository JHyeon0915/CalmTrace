import 'dart:math';
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../services/goals_service.dart';
import '../services/stress_prediction_service.dart';
import '../services/biometric_health_service.dart';
import '../models/stress_data_source.dart';
import '../widgets/stress_gauge.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen>
    with TickerProviderStateMixin {
  final GoalsService _goalsService = GoalsService();
  final BiometricHealthService _biometricService = BiometricHealthService();
  final StressPredictionService _predictionService = StressPredictionService();

  // ── UI state ──────────────────────────────────────────────
  bool _isLoading = true;
  String _selectedRange = '1d';
  bool _analysisExpanded = false;

  // ── Data ─────────────────────────────────────────────────
  // StressReading holds the ML result + the raw biometric values
  // so the analysis panel can display which sensors contributed.
  StressReading? _currentReading;
  List<HRVSample> _hrvSeries = [];

  GaugeDataState get _gaugeState {
    if (_isLoading) return GaugeDataState.loading;
    if (_currentReading == null ||
        _currentReading!.source == DataSource.none ||
        _currentReading!.stressLevel == null) {
      return GaugeDataState.noData;
    }
    return GaugeDataState.hasData;
  }

  final List<Map<String, String>> _timeRanges = [
    {'value': '1d', 'label': '1 day'},
    {'value': '2d', 'label': '2 days'},
    {'value': '3d', 'label': '3 days'},
    {'value': '7d', 'label': '7 days'},
    {'value': '30d', 'label': '30 days'},
  ];

  // ──────────────────────────────────────────────────────────
  // Lifecycle
  // ──────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (mounted) setState(() => _isLoading = true);

    // 1. Ensure HealthKit / Health Connect is authorised
    await _biometricService.requestAuthorization();

    // 2. Fetch the latest biometric snapshot (HRV, HR, RR)
    final bio = await _biometricService.fetchLatest(hours: 6);

    // 3. Fetch HRV time series for the trend chart
    final hrvSeries = await _biometricService.fetchHRVTimeSeries(hours: 24);

    // 4. Call the ML backend — only when we actually have data to send
    StressReading? reading;

    if (bio.hasData) {
      try {
        // HealthKit gives single scalar values per reading.
        // Wrap them in a list — the backend accepts variable-length arrays.
        final hrvValues = bio.hrv != null ? [bio.hrv!] : null;
        final hrValues = bio.heartRate != null ? [bio.heartRate!] : null;
        final rrValues = bio.respiratoryRate != null
            ? [bio.respiratoryRate!]
            : null;

        final prediction = await _predictionService.predictStress(
          hrvValues: hrvValues,
          hrValues: hrValues,
          rrValues: rrValues,
          // eegChannels: emotivService.latestEEGChannels  ← add when EMOTIV wired up
        );

        // Map ML result + raw biometrics into our display model
        reading = StressReading(
          stressLevel: prediction.stressLevel,
          confidence: prediction.confidence.toInt(),
          hrv: bio.hrv,
          heartRate: bio.heartRate,
          respiratoryRate: bio.respiratoryRate,
          source: PlatformCapabilities.supportsHealthKit
              ? DataSource.healthKit
              : DataSource.healthConnect,
          timestamp: DateTime.now(),
        );
      } catch (e) {
        debugPrint('❌ [TrackingScreen] ML prediction failed: $e');
        // reading stays null → gauge shows noData, no crash
      }
    }

    if (mounted) {
      setState(() {
        _currentReading = reading;
        _hrvSeries = hrvSeries;
        _isLoading = false;
      });
    }

    await _completeGoalIfNeeded();
  }

  Future<void> _completeGoalIfNeeded() async {
    try {
      final goalsData = await _goalsService.getDailyGoals();
      final match = goalsData.goals.where(
        (g) => g.goalType == 'stress_check' && !g.isCompleted,
      );
      if (match.isNotEmpty) await _goalsService.completeGoal('stress_check');
    } catch (e) {
      debugPrint('❌ [TrackingScreen] Goal completion error: $e');
    }
  }

  // ──────────────────────────────────────────────────────────
  // Chart helpers
  // ──────────────────────────────────────────────────────────

  List<double> _getChartDataPoints() {
    if (_hrvSeries.isEmpty) return [];
    final now = DateTime.now();
    final cutoff = _cutoffForRange(_selectedRange, now);
    final filtered = _hrvSeries
        .where((s) => s.timestamp.isAfter(cutoff))
        .toList();
    if (filtered.isEmpty) return [];
    // Invert HRV → stress scale: high HRV = low stress
    return filtered.map((s) {
      final hrv = s.value.clamp(10.0, 80.0);
      return ((1 - (hrv - 10) / 70) * 100).clamp(0.0, 100.0);
    }).toList();
  }

  DateTime _cutoffForRange(String range, DateTime now) {
    switch (range) {
      case '1d':
        return now.subtract(const Duration(hours: 24));
      case '2d':
        return now.subtract(const Duration(hours: 48));
      case '3d':
        return now.subtract(const Duration(hours: 72));
      case '7d':
        return now.subtract(const Duration(days: 7));
      case '30d':
        return now.subtract(const Duration(days: 30));
      default:
        return now.subtract(const Duration(hours: 24));
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

  Color _getConfidenceColor(int confidence) {
    if (confidence > 70) return const Color(0xFF68D391);
    if (confidence > 30) return const Color(0xFFF6B93B);
    return const Color(0xFFE57373);
  }

  String _trendLabel() {
    final level = _currentReading?.stressLevel;
    if (level == null) return '—';
    if (level <= 40) return 'Stable ↓';
    if (level <= 70) return 'Moderate';
    return 'Elevated ↑';
  }

  // ──────────────────────────────────────────────────────────
  // Build
  // ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.lg),
                  Text('Stress Tracking', style: AppTextStyles.h2),
                  const SizedBox(height: 4),
                  Text(
                    'Monitor your stress biomarkers',
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _buildStressGaugeCard(),
                  const SizedBox(height: AppSpacing.lg),
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
                  _buildTrendCard(),
                  const SizedBox(height: AppSpacing.xl),
                  if (_currentReading == null ||
                      _currentReading!.source == DataSource.none)
                    _buildNoDataBanner(),
                  const SizedBox(height: AppSpacing.md),
                  Center(
                    child: Text(
                      'For informational purposes only. Not a medical diagnosis.',
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
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // Cards
  // ──────────────────────────────────────────────────────────

  Widget _buildStressGaugeCard() {
    final reading = _currentReading;
    final confidence = reading?.confidence ?? 0;
    final confidenceColor = _getConfidenceColor(confidence);

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
          StressGauge(
            level: reading?.stressLevel,
            maxLevel: 100,
            dataState: _gaugeState,
            dataSourceLabel: reading?.source.label,
          ),
          const SizedBox(height: AppSpacing.lg),
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
                _trendLabel(),
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          if (_gaugeState == GaugeDataState.hasData)
            _buildConfidenceMeter(confidence, confidenceColor),
        ],
      ),
    );
  }

  Widget _buildConfidenceMeter(int confidence, Color color) {
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
              '$confidence%',
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
                Container(
                  height: 8,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  height: 8,
                  width: constraints.maxWidth * (confidence / 100),
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

  Widget _buildNoDataBanner() {
    final msg = PlatformCapabilities.supportsHealthKit
        ? 'Open Apple Health and grant CalmTrace access, or sync your Garmin watch.'
        : PlatformCapabilities.supportsHealthConnect
        ? 'Open Health Connect and grant CalmTrace access, or sync your Garmin watch.'
        : 'Connect your EMOTIV headset via the EMOTIV Cortex app.';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgBorder,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              msg,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisHeader() {
    return GestureDetector(
      onTap: () => setState(() => _analysisExpanded = !_analysisExpanded),
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
    final reading = _currentReading;

    final hasHRV = reading?.hrv != null;
    final hasHR = reading?.heartRate != null;
    final hasRR = reading?.respiratoryRate != null;
    final hasEEG =
        reading?.eegStressIndex != null || reading?.emotivStressDirect != null;

    if (!hasHRV && !hasHR && !hasRR && !hasEEG) return _buildAnalysisNoData();

    // Proportional weights for the percentage bars
    final double totalWeight =
        (hasHRV ? 0.45 : 0) +
        (hasHR ? 0.30 : 0) +
        (hasRR ? 0.15 : 0) +
        (hasEEG ? 0.10 : 0);

    int pct(double w) => totalWeight > 0 ? (w / totalWeight * 100).round() : 0;

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
            'Biomarkers used by the ML model:',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          if (hasHRV) ...[
            _buildFactorRow(
              icon: Icons.show_chart,
              iconColor: const Color(0xFFE89B9B),
              label: 'HRV  •  ${reading!.hrv!.toStringAsFixed(1)} ms',
              percentage: pct(0.45),
              description: reading.hrv! < 25
                  ? 'Low variability — sympathetic activation likely.'
                  : 'Healthy variability — good parasympathetic activity.',
            ),
            if (hasHR || hasRR || hasEEG) const SizedBox(height: AppSpacing.lg),
          ],

          if (hasHR) ...[
            _buildFactorRow(
              icon: Icons.favorite_outline,
              iconColor: const Color(0xFFE89B9B),
              label:
                  'Heart Rate  •  ${reading!.heartRate!.toStringAsFixed(0)} bpm',
              percentage: pct(0.30),
              description: reading.heartRate! >= 85
                  ? 'Elevated — may indicate physical or emotional stress.'
                  : reading.heartRate! >= 75
                  ? 'Slightly above resting baseline.'
                  : 'Within normal resting range.',
            ),
            if (hasRR || hasEEG) const SizedBox(height: AppSpacing.lg),
          ],

          if (hasRR) ...[
            _buildFactorRow(
              icon: Icons.air,
              iconColor: AppColors.primary,
              label:
                  'Respiratory Rate  •  ${reading!.respiratoryRate!.toStringAsFixed(1)} br/min',
              percentage: pct(0.15),
              description: reading.respiratoryRate! > 20
                  ? 'Elevated breathing rate observed.'
                  : 'Within normal range.',
            ),
            if (hasEEG) const SizedBox(height: AppSpacing.lg),
          ],

          if (hasEEG)
            _buildFactorRow(
              icon: Icons.psychology,
              iconColor: const Color(0xFFB4A7D6),
              label: 'EEG Patterns (EMOTIV)',
              percentage: pct(0.10),
              description: (reading?.emotivStressDirect ?? 0) > 0.6
                  ? 'Beta wave dominance — cognitive load detected.'
                  : 'EEG indicates moderate engagement.',
            ),
        ],
      ),
    );
  }

  Widget _buildAnalysisNoData() {
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
      child: Text(
        'No sensor data available yet. Connect your Garmin watch or EMOTIV headset to see a breakdown.',
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.textSecondary,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildFactorRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required int percentage,
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
              '$percentage%',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
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
              builder: (context, constraints) => Container(
                height: 6,
                width: constraints.maxWidth * (percentage / 100),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
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
    final chartData = _getChartDataPoints();
    final labels = _getLabels();
    final hasChartData = chartData.isNotEmpty;

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
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _timeRanges.map((range) {
                final isSelected = _selectedRange == range['value'];
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => _selectedRange = range['value']!),
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
          SizedBox(
            height: 180,
            child: hasChartData
                ? _StressChart(
                    dataPoints: chartData.map((d) => d.round()).toList(),
                    labels: labels,
                    selectedRange: _selectedRange,
                  )
                : _buildChartEmpty(),
          ),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: Text(
              hasChartData ? _getRangeDescription() : 'No trend data yet',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textHint,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.show_chart,
            size: 40,
            color: AppColors.textHint.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 8),
          Text(
            'Trend data will appear once\nyour device syncs readings.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textHint,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Chart
// ─────────────────────────────────────────────────────────────────────────────

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
      builder: (context, constraints) => CustomPaint(
        size: Size(constraints.maxWidth, constraints.maxHeight),
        painter: _ChartPainter(
          dataPoints: dataPoints,
          labels: labels,
          selectedRange: selectedRange,
        ),
      ),
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

    const paddingLeft = 30.0,
        paddingRight = 10.0,
        paddingTop = 10.0,
        paddingBottom = 25.0;
    final chartWidth = size.width - paddingLeft - paddingRight;
    final chartHeight = size.height - paddingTop - paddingBottom;

    for (int i = 0; i < 5; i++) {
      final y = paddingTop + (i / 4) * chartHeight;
      _drawDashedLine(
        canvas,
        Offset(paddingLeft, y),
        Offset(size.width - paddingRight, y),
        Paint()
          ..color = const Color(0xFFE8E8E8)
          ..strokeWidth = 1,
      );
      final tp = TextPainter(
        text: TextSpan(
          text: '${100 - i * 25}',
          style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(5, y - tp.height / 2));
    }

    final stepX = dataPoints.length > 1
        ? chartWidth / (dataPoints.length - 1)
        : chartWidth;
    final points = <Offset>[
      for (int i = 0; i < dataPoints.length; i++)
        Offset(
          paddingLeft + i * stepX,
          paddingTop + chartHeight - dataPoints[i] / 100 * chartHeight,
        ),
    ];

    if (points.length > 1) {
      final fill = Path()
        ..moveTo(points.first.dx, paddingTop + chartHeight)
        ..lineTo(points.first.dx, points.first.dy);
      final line = Path()..moveTo(points.first.dx, points.first.dy);
      for (int i = 0; i < points.length - 1; i++) {
        final cp = (points[i].dx + points[i + 1].dx) / 2;
        fill.quadraticBezierTo(
          cp,
          points[i].dy,
          cp,
          (points[i].dy + points[i + 1].dy) / 2,
        );
        fill.quadraticBezierTo(
          cp,
          points[i + 1].dy,
          points[i + 1].dx,
          points[i + 1].dy,
        );
        line.quadraticBezierTo(
          cp,
          points[i].dy,
          cp,
          (points[i].dy + points[i + 1].dy) / 2,
        );
        line.quadraticBezierTo(
          cp,
          points[i + 1].dy,
          points[i + 1].dx,
          points[i + 1].dy,
        );
      }
      fill.lineTo(points.last.dx, paddingTop + chartHeight);
      fill.close();
      canvas.drawPath(
        fill,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x4D6B9BD1), Color(0x0D6B9BD1)],
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
      );
      canvas.drawPath(
        line,
        Paint()
          ..color = const Color(0xFF6B9BD1)
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    for (final p in points) {
      canvas.drawCircle(p, 4, Paint()..color = Colors.white);
      canvas.drawCircle(
        p,
        4,
        Paint()
          ..color = const Color(0xFF6B9BD1)
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
      );
    }

    if (points.isNotEmpty && labels.isNotEmpty) {
      final step = points.length > 1
          ? (points.length - 1) / (labels.length - 1)
          : 0.0;
      for (int i = 0; i < labels.length; i++) {
        final idx = (i * step).round().clamp(0, points.length - 1);
        final tp = TextPainter(
          text: TextSpan(
            text: labels[i],
            style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 9),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(
          canvas,
          Offset(points[idx].dx - tp.width / 2, size.height - 12),
        );
      }
    }
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashWidth = 4.0, dashSpace = 4.0;
    final distance = (end - start).distance;
    double drawn = 0;
    while (drawn < distance) {
      final seg = min(dashWidth, distance - drawn);
      canvas.drawLine(
        Offset.lerp(start, end, drawn / distance)!,
        Offset.lerp(start, end, (drawn + seg) / distance)!,
        paint,
      );
      drawn += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _ChartPainter old) =>
      old.dataPoints != dataPoints || old.selectedRange != selectedRange;
}
