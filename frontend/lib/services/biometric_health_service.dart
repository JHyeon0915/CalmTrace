import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import '../models/stress_data_source.dart';

// pub.dev: health: ^12.x.x
// Supports HealthKit (iOS/macOS) and Health Connect (Android) under one API.

class BiometricHealthService {
  static final BiometricHealthService _instance =
      BiometricHealthService._internal();
  factory BiometricHealthService() => _instance;
  BiometricHealthService._internal();

  bool _authorized = false;

  // Data types we care about. Both HealthKit and Health Connect
  // expose these — the `health` package maps them automatically.
  static const List<HealthDataType> _types = [
    HealthDataType.HEART_RATE_VARIABILITY_SDNN, // HRV (ms)
    HealthDataType.HEART_RATE, // bpm
    HealthDataType.RESPIRATORY_RATE, // breaths/min
    HealthDataType.RESTING_HEART_RATE,
  ];

  // ──────────────────────────────────────────────────────────
  // Authorization
  // ──────────────────────────────────────────────────────────

  Future<bool> requestAuthorization() async {
    if (!PlatformCapabilities.supportsHealthKit &&
        !PlatformCapabilities.supportsHealthConnect) {
      debugPrint(
        '⚠️ [BiometricHealthService] Platform does not support health APIs',
      );
      return false;
    }

    try {
      final permissions = _types.map((_) => HealthDataAccess.READ).toList();

      _authorized = await Health().requestAuthorization(
        _types,
        permissions: permissions,
      );

      debugPrint('🏥 [BiometricHealthService] Authorization: $_authorized');
      return _authorized;
    } catch (e) {
      debugPrint('❌ [BiometricHealthService] Authorization error: $e');
      return false;
    }
  }

  // ──────────────────────────────────────────────────────────
  // Fetch latest biometrics (last N hours)
  // ──────────────────────────────────────────────────────────

  /// Returns null for any field that has no recent data.
  Future<BiometricSnapshot> fetchLatest({int hours = 6}) async {
    if (!_authorized) {
      final granted = await requestAuthorization();
      if (!granted) return BiometricSnapshot.empty();
    }

    final now = DateTime.now();
    final from = now.subtract(Duration(hours: hours));

    try {
      final dataPoints = await Health().getHealthDataFromTypes(
        startTime: from,
        endTime: now,
        types: _types,
      );

      return _aggregate(dataPoints);
    } catch (e) {
      debugPrint('❌ [BiometricHealthService] Fetch error: $e');
      return BiometricSnapshot.empty();
    }
  }

  /// Fetch a list of HRV readings for a trend chart (last N hours, bucketed).
  Future<List<HRVSample>> fetchHRVTimeSeries({int hours = 24}) async {
    if (!_authorized) {
      final granted = await requestAuthorization();
      if (!granted) return [];
    }

    final now = DateTime.now();
    final from = now.subtract(Duration(hours: hours));

    try {
      final points = await Health().getHealthDataFromTypes(
        startTime: from,
        endTime: now,
        types: [HealthDataType.HEART_RATE_VARIABILITY_SDNN],
      );

      return points
          .map(
            (p) => HRVSample(
              value: (p.value as NumericHealthValue).numericValue.toDouble(),
              timestamp: p.dateFrom,
            ),
          )
          .toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    } catch (e) {
      debugPrint('❌ [BiometricHealthService] HRV series fetch error: $e');
      return [];
    }
  }

  // ──────────────────────────────────────────────────────────
  // Aggregation helpers
  // ──────────────────────────────────────────────────────────

  BiometricSnapshot _aggregate(List<HealthDataPoint> points) {
    final hrv = _latestNumeric(
      points,
      HealthDataType.HEART_RATE_VARIABILITY_SDNN,
    );
    final hr = _latestNumeric(points, HealthDataType.HEART_RATE);
    final rr = _latestNumeric(points, HealthDataType.RESPIRATORY_RATE);
    final restingHR = _latestNumeric(points, HealthDataType.RESTING_HEART_RATE);

    return BiometricSnapshot(
      hrv: hrv,
      heartRate: hr ?? restingHR,
      respiratoryRate: rr,
      sampledAt: DateTime.now(),
      hasData: hrv != null || hr != null || rr != null,
    );
  }

  double? _latestNumeric(List<HealthDataPoint> points, HealthDataType type) {
    final filtered = points.where((p) => p.type == type).toList()
      ..sort((a, b) => b.dateFrom.compareTo(a.dateFrom));

    if (filtered.isEmpty) return null;
    return (filtered.first.value as NumericHealthValue).numericValue.toDouble();
  }
}

// ──────────────────────────────────────────────────────────
// Value objects
// ──────────────────────────────────────────────────────────

class BiometricSnapshot {
  final double? hrv; // ms — higher = less stressed
  final double? heartRate; // bpm
  final double? respiratoryRate; // breaths/min
  final DateTime sampledAt;
  final bool hasData;

  const BiometricSnapshot({
    this.hrv,
    this.heartRate,
    this.respiratoryRate,
    required this.sampledAt,
    required this.hasData,
  });

  factory BiometricSnapshot.empty() =>
      BiometricSnapshot(sampledAt: DateTime.now(), hasData: false);
}

class HRVSample {
  final double value;
  final DateTime timestamp;
  const HRVSample({required this.value, required this.timestamp});
}
