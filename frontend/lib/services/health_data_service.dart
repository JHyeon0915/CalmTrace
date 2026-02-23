import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import 'device_feedback_service.dart';
import 'package:flutter/material.dart';

/// Health data point with timestamp
class HealthDataPoint {
  final double value;
  final DateTime timestamp;
  final String source;

  HealthDataPoint({
    required this.value,
    required this.timestamp,
    required this.source,
  });

  @override
  String toString() =>
      'HealthDataPoint(value: $value, time: $timestamp, source: $source)';
}

/// HRV and RR data bundle
class StressHealthData {
  final List<HealthDataPoint> hrvData;
  final List<HealthDataPoint> rrData;
  final List<HealthDataPoint> hrData;
  final DateTime fetchedAt;
  final bool hasGarminData;
  final bool isMockData;

  StressHealthData({
    required this.hrvData,
    required this.rrData,
    required this.hrData,
    required this.fetchedAt,
    this.hasGarminData = false,
    this.isMockData = false,
  });

  double? get latestHrv => hrvData.isNotEmpty ? hrvData.last.value : null;
  double? get latestRr => rrData.isNotEmpty ? rrData.last.value : null;
  double? get latestHr => hrData.isNotEmpty ? hrData.last.value : null;
  bool get hasValidData => hrvData.isNotEmpty || rrData.isNotEmpty;

  Map<String, dynamic> toModelInput() {
    return {
      'hrv_sdnn': latestHrv,
      'respiratory_rate': latestRr,
      'heart_rate': latestHr,
      'hrv_data_points': hrvData.length,
      'rr_data_points': rrData.length,
      'fetched_at': fetchedAt.toIso8601String(),
      'has_garmin_data': hasGarminData,
      'is_mock_data': isMockData,
    };
  }

  @override
  String toString() {
    return '''
StressHealthData:
  HRV (${hrvData.length} points): latest = $latestHrv ms
  RR (${rrData.length} points): latest = $latestRr breaths/min
  HR (${hrData.length} points): latest = $latestHr bpm
  Has Garmin Data: $hasGarminData
  Is Mock Data: $isMockData
  Fetched: $fetchedAt
''';
  }
}

/// Connection status for health services
enum HealthConnectionStatus {
  disconnected,
  connecting,
  connected,
  connectedMock, // For simulator testing
  permissionDenied,
  notAvailable,
  error,
}

extension HealthConnectionStatusExtension on HealthConnectionStatus {
  String get label {
    switch (this) {
      case HealthConnectionStatus.disconnected:
        return 'Disconnected';
      case HealthConnectionStatus.connecting:
        return 'Connecting...';
      case HealthConnectionStatus.connected:
        return 'Connected';
      case HealthConnectionStatus.connectedMock:
        return 'Connected (Mock)';
      case HealthConnectionStatus.permissionDenied:
        return 'Permission Denied';
      case HealthConnectionStatus.notAvailable:
        return 'Not Available';
      case HealthConnectionStatus.error:
        return 'Error';
    }
  }

  bool get isConnected =>
      this == HealthConnectionStatus.connected ||
      this == HealthConnectionStatus.connectedMock;
}

/// Service to manage health data from smartwatch
class HealthDataService {
  static final HealthDataService _instance = HealthDataService._internal();
  factory HealthDataService() => _instance;
  HealthDataService._internal();

  final Health _health = Health();
  final DeviceFeedbackService _feedbackService = DeviceFeedbackService();

  HealthConnectionStatus _status = HealthConnectionStatus.disconnected;
  HealthConnectionStatus get status => _status;

  final _statusController =
      StreamController<HealthConnectionStatus>.broadcast();
  Stream<HealthConnectionStatus> get statusStream => _statusController.stream;

  final _dataController = StreamController<StressHealthData>.broadcast();
  Stream<StressHealthData> get dataStream => _dataController.stream;

  // Flag to use mock data (for simulator)
  bool _useMockData = false;
  bool get useMockData => _useMockData;

  List<HealthDataType> get _requiredTypes {
    return [
      HealthDataType.HEART_RATE_VARIABILITY_SDNN,
      HealthDataType.RESPIRATORY_RATE,
      HealthDataType.HEART_RATE,
    ];
  }

  List<HealthDataAccess> get _permissions {
    return _requiredTypes.map((_) => HealthDataAccess.READ).toList();
  }

  /// Check if running on simulator
  bool get _isSimulator {
    // On iOS simulator or Android emulator, health services are limited
    // This is a simple heuristic - you might need to adjust
    return kDebugMode;
  }

  /// Initialize and check health service availability
  Future<bool> initialize() async {
    debugPrint('🏥 [HealthDataService] Initializing...');
    debugPrint('🏥 [HealthDataService] Platform: ${Platform.operatingSystem}');
    debugPrint('🏥 [HealthDataService] Debug mode: $kDebugMode');

    try {
      await _health.configure();
      debugPrint('🏥 [HealthDataService] Health configured');
      return true;
    } catch (e) {
      debugPrint('❌ [HealthDataService] Initialization error: $e');
      // Don't set error status - we might use mock data
      return false;
    }
  }

  /// Connect to health services (or mock for simulator)
  Future<bool> connect(BuildContext? context, {bool forceMock = false}) async {
    debugPrint('🏥 [HealthDataService] Connecting...');
    _updateStatus(HealthConnectionStatus.connecting);

    // Use mock data if forced or on simulator with no real health access
    if (forceMock) {
      _useMockData = true;
      _updateStatus(HealthConnectionStatus.connectedMock);

      if (context != null && context.mounted) {
        await _feedbackService.triggerFeedback(context);
      }

      debugPrint('✅ [HealthDataService] Connected with MOCK data');
      return true;
    }

    try {
      // Try real health connection
      final granted = await _health.requestAuthorization(
        _requiredTypes,
        permissions: _permissions,
      );

      debugPrint('🏥 [HealthDataService] Permissions granted: $granted');

      if (granted) {
        _useMockData = false;
        _updateStatus(HealthConnectionStatus.connected);

        if (context != null && context.mounted) {
          await _feedbackService.triggerFeedback(context);
        }

        debugPrint('✅ [HealthDataService] Connected to real health services');
        return true;
      } else {
        // Permission denied - offer mock mode in debug
        if (kDebugMode) {
          debugPrint(
            '⚠️ [HealthDataService] Permission denied, falling back to mock',
          );
          _useMockData = true;
          _updateStatus(HealthConnectionStatus.connectedMock);

          if (context != null && context.mounted) {
            await _feedbackService.triggerFeedback(context);
          }

          return true;
        }

        _updateStatus(HealthConnectionStatus.permissionDenied);
        return false;
      }
    } catch (e) {
      debugPrint('❌ [HealthDataService] Connection error: $e');

      // On error (like simulator), fall back to mock in debug mode
      if (kDebugMode) {
        debugPrint('⚠️ [HealthDataService] Error, falling back to mock data');
        _useMockData = true;
        _updateStatus(HealthConnectionStatus.connectedMock);

        if (context != null && context.mounted) {
          await _feedbackService.triggerFeedback(context);
        }

        return true;
      }

      _updateStatus(HealthConnectionStatus.error);
      return false;
    }
  }

  /// Disconnect from health services
  void disconnect() {
    debugPrint('🏥 [HealthDataService] Disconnecting...');
    _useMockData = false;
    _updateStatus(HealthConnectionStatus.disconnected);
  }

  /// Fetch HRV and RR data for stress analysis
  Future<StressHealthData?> fetchHealthData({int hours = 24}) async {
    if (!_status.isConnected) {
      debugPrint('⚠️ [HealthDataService] Not connected, cannot fetch data');
      return null;
    }

    debugPrint(
      '🏥 [HealthDataService] Fetching health data (mock: $_useMockData)...',
    );

    if (_useMockData) {
      return _generateMockData(hours);
    }

    return _fetchRealData(hours);
  }

  /// Fetch real data from health services
  Future<StressHealthData?> _fetchRealData(int hours) async {
    try {
      final now = DateTime.now();
      final startTime = now.subtract(Duration(hours: hours));

      final healthData = await _health.getHealthDataFromTypes(
        types: _requiredTypes,
        startTime: startTime,
        endTime: now,
      );

      debugPrint(
        '🏥 [HealthDataService] Raw data points: ${healthData.length}',
      );

      final hrvData = <HealthDataPoint>[];
      final rrData = <HealthDataPoint>[];
      final hrData = <HealthDataPoint>[];
      bool hasGarminData = false;

      for (final point in healthData) {
        final value = _extractNumericValue(point.value);
        if (value == null) continue;

        final dataPoint = HealthDataPoint(
          value: value,
          timestamp: point.dateFrom,
          source: point.sourceName,
        );

        if (point.sourceName.toLowerCase().contains('garmin')) {
          hasGarminData = true;
        }

        switch (point.type) {
          case HealthDataType.HEART_RATE_VARIABILITY_SDNN:
            hrvData.add(dataPoint);
            break;
          case HealthDataType.RESPIRATORY_RATE:
            rrData.add(dataPoint);
            break;
          case HealthDataType.HEART_RATE:
            hrData.add(dataPoint);
            break;
          default:
            break;
        }
      }

      hrvData.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      rrData.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      hrData.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      final result = StressHealthData(
        hrvData: hrvData,
        rrData: rrData,
        hrData: hrData,
        fetchedAt: now,
        hasGarminData: hasGarminData,
        isMockData: false,
      );

      debugPrint('✅ [HealthDataService] Fetch complete:');
      debugPrint(result.toString());

      _dataController.add(result);
      return result;
    } catch (e) {
      debugPrint('❌ [HealthDataService] Fetch error: $e');
      return null;
    }
  }

  /// Generate mock data for simulator testing
  StressHealthData _generateMockData(int hours) {
    debugPrint('🎭 [HealthDataService] Generating mock data for $hours hours');

    final now = DateTime.now();
    final random = Random();

    final hrvData = <HealthDataPoint>[];
    final rrData = <HealthDataPoint>[];
    final hrData = <HealthDataPoint>[];

    // Generate data points every 30 minutes
    final pointCount = hours * 2;

    for (int i = 0; i < pointCount; i++) {
      final timestamp = now.subtract(Duration(minutes: (pointCount - i) * 30));

      // Simulate stress patterns - higher stress during work hours
      final hour = timestamp.hour;
      final isWorkHour = hour >= 9 && hour <= 18;
      final stressFactor = isWorkHour ? 0.7 : 0.3;

      // HRV: Lower during stress (normal: 30-100ms, stressed: 20-50ms)
      final baseHrv = isWorkHour ? 35.0 : 55.0;
      hrvData.add(
        HealthDataPoint(
          value: baseHrv + random.nextDouble() * 20 - 10,
          timestamp: timestamp,
          source: 'Garmin Venu (Mock)',
        ),
      );

      // RR: Higher during stress (normal: 12-20, stressed: 16-24)
      final baseRr = isWorkHour ? 18.0 : 14.0;
      rrData.add(
        HealthDataPoint(
          value: baseRr + random.nextDouble() * 4 - 2,
          timestamp: timestamp,
          source: 'Garmin Venu (Mock)',
        ),
      );

      // HR: Higher during stress (normal: 60-80, stressed: 75-95)
      final baseHr = isWorkHour ? 82.0 : 68.0;
      hrData.add(
        HealthDataPoint(
          value: baseHr + random.nextDouble() * 15 - 7.5,
          timestamp: timestamp,
          source: 'Garmin Venu (Mock)',
        ),
      );
    }

    final result = StressHealthData(
      hrvData: hrvData,
      rrData: rrData,
      hrData: hrData,
      fetchedAt: now,
      hasGarminData: true,
      isMockData: true,
    );

    debugPrint('✅ [HealthDataService] Mock data generated:');
    debugPrint(result.toString());

    _dataController.add(result);
    return result;
  }

  /// Fetch only the most recent data points
  Future<StressHealthData?> fetchLatestData() async {
    return fetchHealthData(hours: 1);
  }

  double? _extractNumericValue(HealthValue value) {
    if (value is NumericHealthValue) {
      return value.numericValue.toDouble();
    }
    return null;
  }

  void _updateStatus(HealthConnectionStatus newStatus) {
    _status = newStatus;
    _statusController.add(newStatus);
    debugPrint('🏥 [HealthDataService] Status: ${newStatus.label}');
  }

  Future<bool> checkPermissions() async {
    try {
      final hasPermissions = await _health.hasPermissions(_requiredTypes);
      return hasPermissions ?? false;
    } catch (e) {
      debugPrint('❌ [HealthDataService] Permission check error: $e');
      return false;
    }
  }

  String getSetupInstructions() {
    if (Platform.isIOS) {
      return '''
To sync Garmin data:
1. Open Garmin Connect app
2. Go to Settings > Health Apps
3. Enable "Apple Health"
4. Select data to share (HRV, Respiratory Rate)
5. Data will sync automatically
''';
    } else {
      return '''
To sync Garmin data:
1. Open Garmin Connect app
2. Go to Settings > Health Apps  
3. Enable "Health Connect"
4. Select data to share (HRV, Respiratory Rate)
5. Data will sync automatically
''';
    }
  }

  void dispose() {
    _statusController.close();
    _dataController.close();
  }
}
