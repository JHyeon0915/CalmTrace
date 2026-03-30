import 'dart:io';

// ─────────────────────────────────────────────────────────────
// Domain model — all fields nullable so "no data" is explicit
// ─────────────────────────────────────────────────────────────
class StressReading {
  /// 0–100, null = no data available
  final int? stressLevel;

  /// 0–100, null = confidence unknown
  final int? confidence;

  final double? hrv;
  final double? heartRate;
  final double? respiratoryRate;
  final double? eegStressIndex; // betaH / alpha from EMOTIV
  final double? emotivStressDirect; // met stream "stress" value

  final DataSource source;
  final DateTime timestamp;

  const StressReading({
    this.stressLevel,
    this.confidence,
    this.hrv,
    this.heartRate,
    this.respiratoryRate,
    this.eegStressIndex,
    this.emotivStressDirect,
    required this.source,
    required this.timestamp,
  });

  bool get hasAnyData =>
      stressLevel != null ||
      hrv != null ||
      heartRate != null ||
      eegStressIndex != null ||
      emotivStressDirect != null;

  StressReading copyWith({
    int? stressLevel,
    int? confidence,
    double? hrv,
    double? heartRate,
    double? respiratoryRate,
    double? eegStressIndex,
    double? emotivStressDirect,
    DataSource? source,
    DateTime? timestamp,
  }) {
    return StressReading(
      stressLevel: stressLevel ?? this.stressLevel,
      confidence: confidence ?? this.confidence,
      hrv: hrv ?? this.hrv,
      heartRate: heartRate ?? this.heartRate,
      respiratoryRate: respiratoryRate ?? this.respiratoryRate,
      eegStressIndex: eegStressIndex ?? this.eegStressIndex,
      emotivStressDirect: emotivStressDirect ?? this.emotivStressDirect,
      source: source ?? this.source,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}

enum DataSource { healthKit, healthConnect, emotiv, combined, mock, none }

extension DataSourceLabel on DataSource {
  String get label {
    switch (this) {
      case DataSource.healthKit:
        return 'Apple Health';
      case DataSource.healthConnect:
        return 'Health Connect';
      case DataSource.emotiv:
        return 'EMOTIV';
      case DataSource.combined:
        return 'Multi-sensor';
      case DataSource.mock:
        return 'Demo';
      case DataSource.none:
        return 'No source';
    }
  }
}

// ─────────────────────────────────────────────────────────────
// Platform capability detection
// ─────────────────────────────────────────────────────────────
class PlatformCapabilities {
  static bool get supportsHealthKit =>
      Platform.isIOS ||
      // macOS HealthKit exists but Garmin data won't be there —
      // only enable if you explicitly want basic macOS Health data.
      (Platform.isMacOS && _macOSHealthKitSupported);

  static bool get supportsHealthConnect => Platform.isAndroid;

  static bool get supportsEmotivCortex =>
      // Cortex WebSocket server only runs on macOS/Windows desktop
      Platform.isMacOS || Platform.isWindows || Platform.isLinux;

  // macOS 13+ required for HealthKit. Runtime check via dart:io is limited,
  // so we default to false and flip via feature detection at init.
  static bool _macOSHealthKitSupported = false;
  static void setMacOSHealthKitSupported(bool v) =>
      _macOSHealthKitSupported = v;
}
