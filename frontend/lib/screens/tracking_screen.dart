import 'dart:math';
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../services/goals_service.dart';
import '../services/stress_prediction_service.dart';
import '../services/biometric_health_service.dart';
import '../models/stress_data_source.dart';
import '../widgets/stress_gauge.dart';
import '../widgets/tracking/tracking_stress_gauge_card.dart';
import '../widgets/tracking/analysis_panel.dart';
import '../widgets/tracking/trend_card.dart';
import '../widgets/tracking/no_data_banner.dart';

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

  bool _isLoading = true;
  String _selectedRange = '1d';
  bool _analysisExpanded = false;

  StressReading? _currentReading;
  List<HRVSample> _hrvSeries = [];

  final List<Map<String, String>> _timeRanges = [
    {'value': '1d', 'label': '1 day'},
    {'value': '2d', 'label': '2 days'},
    {'value': '3d', 'label': '3 days'},
    {'value': '7d', 'label': '7 days'},
    {'value': '30d', 'label': '30 days'},
  ];

  GaugeDataState get _gaugeState {
    if (_isLoading) return GaugeDataState.loading;
    if (_currentReading == null ||
        _currentReading!.source == DataSource.none ||
        _currentReading!.stressLevel == null) {
      return GaugeDataState.noData;
    }
    return GaugeDataState.hasData;
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (mounted) setState(() => _isLoading = true);

    // 1. Ensure HealthKit / Health Connect is authorized
    await _biometricService.requestAuthorization();

    // 2. Fetch the latest biometric snapshot (HRV, HR, RR)
    final bio = await _biometricService.fetchLatest(hours: 6);

    // 3. Fetch HRV time series for the trend chart
    final hrvSeries = await _biometricService.fetchHRVTimeSeries(hours: 24);

    // 4. Call the ML backend — only when we actually have data to send
    StressReading? reading;

    if (bio.hasData) {
      try {
        final prediction = await _predictionService.predictStress(
          hrvValues: bio.hrv != null ? [bio.hrv!] : null,
          hrValues: bio.heartRate != null ? [bio.heartRate!] : null,
          rrValues: bio.respiratoryRate != null ? [bio.respiratoryRate!] : null,
        );
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
        // reading stays null → gauge shows noData
        debugPrint('❌ [TrackingScreen] ML prediction failed: $e');
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

  String _trendLabel() {
    final level = _currentReading?.stressLevel;
    if (level == null) return '—';
    if (level <= 40) return 'Stable ↓';
    if (level <= 70) return 'Moderate';
    return 'Elevated ↑';
  }

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
                  TrackingStressGaugeCard(
                    reading: _currentReading,
                    gaugeState: _gaugeState,
                    trendLabel: _trendLabel(),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Analysis',
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AnalysisPanel(
                    reading: _currentReading,
                    isExpanded: _analysisExpanded,
                    onToggle: () =>
                        setState(() => _analysisExpanded = !_analysisExpanded),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TrendCard(
                    chartData: _getChartDataPoints(),
                    labels: _getLabels(),
                    selectedRange: _selectedRange,
                    rangeDescription: _getRangeDescription(),
                    timeRanges: _timeRanges,
                    onRangeChanged: (range) =>
                        setState(() => _selectedRange = range),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  if (_currentReading == null ||
                      _currentReading!.source == DataSource.none)
                    const NoDataBanner(),
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
}
