/// Stress prediction result from ML backend
class StressPrediction {
  final int stressLevel; // 0-100
  final String stressClass; // 'normal' or 'stress'
  final String stressLabel; // 'Low Stress', 'Medium Stress', 'High Stress'
  final double confidence; // 0-100
  final String
  modelUsed; // 'fusion', 'eeg_only', 'ecg_only', 'emotiv_metrics', 'mock'
  final DataSourceStatus dataSources;
  final DateTime timestamp;

  StressPrediction({
    required this.stressLevel,
    required this.stressClass,
    required this.stressLabel,
    required this.confidence,
    required this.modelUsed,
    required this.dataSources,
    required this.timestamp,
  });

  factory StressPrediction.fromJson(Map<String, dynamic> json) {
    return StressPrediction(
      stressLevel: json['stress_level'] ?? 50,
      stressClass: json['stress_class'] ?? 'normal',
      stressLabel: json['stress_label'] ?? 'Unknown',
      confidence: (json['confidence'] ?? 0).toDouble(),
      modelUsed: json['model_used'] ?? 'unknown',
      dataSources: DataSourceStatus.fromJson(json['data_sources'] ?? {}),
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stress_level': stressLevel,
      'stress_class': stressClass,
      'stress_label': stressLabel,
      'confidence': confidence,
      'model_used': modelUsed,
      'data_sources': dataSources.toJson(),
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Check if stress level is low (0-40)
  bool get isLowStress => stressLevel <= 40;

  /// Check if stress level is medium (41-70)
  bool get isMediumStress => stressLevel > 40 && stressLevel <= 70;

  /// Check if stress level is high (71-100)
  bool get isHighStress => stressLevel > 70;

  /// Get stress color based on level
  StressColor get stressColor {
    if (isLowStress) return StressColor.green;
    if (isMediumStress) return StressColor.orange;
    return StressColor.red;
  }

  @override
  String toString() {
    return 'StressPrediction(level: $stressLevel, class: $stressClass, confidence: $confidence%, model: $modelUsed)';
  }
}

/// Status of data sources used in prediction
class DataSourceStatus {
  final bool eeg;
  final bool hrv;
  final bool rr;
  final bool hr;

  DataSourceStatus({
    this.eeg = false,
    this.hrv = false,
    this.rr = false,
    this.hr = false,
  });

  factory DataSourceStatus.fromJson(Map<String, dynamic> json) {
    return DataSourceStatus(
      eeg: json['eeg'] ?? false,
      hrv: json['hrv'] ?? false,
      rr: json['rr'] ?? false,
      hr: json['hr'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {'eeg': eeg, 'hrv': hrv, 'rr': rr, 'hr': hr};
  }

  /// Check if any data source is available
  bool get hasAnyData => eeg || hrv || rr || hr;

  /// Get list of active sources
  List<String> get activeSources {
    final sources = <String>[];
    if (eeg) sources.add('EEG');
    if (hrv) sources.add('HRV');
    if (rr) sources.add('RR');
    if (hr) sources.add('HR');
    return sources;
  }
}

/// Stress prediction with explainability
class StressPredictionWithExplanation {
  final int stressLevel;
  final String stressLabel;
  final double confidence;
  final FeatureContributions contributions;
  final Map<String, String> descriptions;
  final DateTime timestamp;

  StressPredictionWithExplanation({
    required this.stressLevel,
    required this.stressLabel,
    required this.confidence,
    required this.contributions,
    required this.descriptions,
    required this.timestamp,
  });

  factory StressPredictionWithExplanation.fromJson(Map<String, dynamic> json) {
    return StressPredictionWithExplanation(
      stressLevel: json['stress_level'] ?? 50,
      stressLabel: json['stress_label'] ?? 'Unknown',
      confidence: (json['confidence'] ?? 0).toDouble(),
      contributions: FeatureContributions.fromJson(json['contributions'] ?? {}),
      descriptions: Map<String, String>.from(json['descriptions'] ?? {}),
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }
}

/// Feature contributions for explainability (SHAP-style)
class FeatureContributions {
  final double? hrv;
  final double? rr;
  final double? hr;
  final double? eeg;

  FeatureContributions({this.hrv, this.rr, this.hr, this.eeg});

  factory FeatureContributions.fromJson(Map<String, dynamic> json) {
    return FeatureContributions(
      hrv: json['hrv']?.toDouble(),
      rr: json['rr']?.toDouble(),
      hr: json['hr']?.toDouble(),
      eeg: json['eeg']?.toDouble(),
    );
  }

  /// Get contributions as list for display
  List<ContributionItem> toList() {
    final items = <ContributionItem>[];

    if (hrv != null) {
      items.add(
        ContributionItem(
          name: 'Heart Rate Variability (HRV)',
          percentage: hrv!,
          key: 'hrv',
        ),
      );
    }
    if (rr != null) {
      items.add(
        ContributionItem(name: 'Respiratory Rate', percentage: rr!, key: 'rr'),
      );
    }
    if (hr != null) {
      items.add(
        ContributionItem(name: 'Heart Rate', percentage: hr!, key: 'hr'),
      );
    }
    if (eeg != null) {
      items.add(
        ContributionItem(name: 'EEG Patterns', percentage: eeg!, key: 'eeg'),
      );
    }

    // Sort by percentage descending
    items.sort((a, b) => b.percentage.compareTo(a.percentage));
    return items;
  }
}

/// Single contribution item
class ContributionItem {
  final String name;
  final double percentage;
  final String key;

  ContributionItem({
    required this.name,
    required this.percentage,
    required this.key,
  });
}

/// Stress history response
class StressHistory {
  final List<StressHistoryEntry> entries;
  final double averageStress;
  final String trend; // 'improving', 'stable', 'worsening'
  final int periodDays;

  StressHistory({
    required this.entries,
    required this.averageStress,
    required this.trend,
    required this.periodDays,
  });

  factory StressHistory.fromJson(Map<String, dynamic> json) {
    return StressHistory(
      entries: (json['entries'] as List? ?? [])
          .map((e) => StressHistoryEntry.fromJson(e))
          .toList(),
      averageStress: (json['average_stress'] ?? 50).toDouble(),
      trend: json['trend'] ?? 'stable',
      periodDays: json['period_days'] ?? 7,
    );
  }

  /// Get data points for chart
  List<int> getChartData() {
    return entries.map((e) => e.stressLevel).toList().reversed.toList();
  }

  /// Get labels for chart
  List<String> getChartLabels() {
    return entries
        .map((e) {
          final diff = DateTime.now().difference(e.timestamp).inDays;
          if (diff == 0) return 'Today';
          if (diff == 1) return 'Yesterday';
          return '${diff}d';
        })
        .toList()
        .reversed
        .toList();
  }
}

/// Single stress history entry
class StressHistoryEntry {
  final int stressLevel;
  final String stressLabel;
  final double confidence;
  final String modelUsed;
  final DateTime timestamp;

  StressHistoryEntry({
    required this.stressLevel,
    required this.stressLabel,
    required this.confidence,
    required this.modelUsed,
    required this.timestamp,
  });

  factory StressHistoryEntry.fromJson(Map<String, dynamic> json) {
    return StressHistoryEntry(
      stressLevel: json['stress_level'] ?? 50,
      stressLabel: json['stress_label'] ?? 'Unknown',
      confidence: (json['confidence'] ?? 0).toDouble(),
      modelUsed: json['model_used'] ?? 'unknown',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }
}

/// ML model status
class ModelStatus {
  final bool modelsLoaded;
  final List<String> availableModels;
  final double fusionModelAccuracy;
  final double eegModelAccuracy;
  final double ecgModelAccuracy;

  ModelStatus({
    required this.modelsLoaded,
    required this.availableModels,
    this.fusionModelAccuracy = 94.0,
    this.eegModelAccuracy = 50.0,
    this.ecgModelAccuracy = 70.0,
  });

  factory ModelStatus.fromJson(Map<String, dynamic> json) {
    return ModelStatus(
      modelsLoaded: json['models_loaded'] ?? false,
      availableModels: List<String>.from(json['available_models'] ?? []),
      fusionModelAccuracy: (json['fusion_model_accuracy'] ?? 94.0).toDouble(),
      eegModelAccuracy: (json['eeg_model_accuracy'] ?? 50.0).toDouble(),
      ecgModelAccuracy: (json['ecg_model_accuracy'] ?? 70.0).toDouble(),
    );
  }

  /// Check if fusion model is available (best accuracy)
  bool get hasFusionModel => availableModels.contains('fusion');
}

/// EMOTIV performance metrics for prediction
class EmotivMetricsData {
  final double? engagement;
  final double? excitement;
  final double? stress;
  final double? relaxation;
  final double? interest;
  final double? focus;

  EmotivMetricsData({
    this.engagement,
    this.excitement,
    this.stress,
    this.relaxation,
    this.interest,
    this.focus,
  });

  Map<String, dynamic> toJson() {
    return {
      if (engagement != null) 'engagement': engagement,
      if (excitement != null) 'excitement': excitement,
      if (stress != null) 'stress': stress,
      if (relaxation != null) 'relaxation': relaxation,
      if (interest != null) 'interest': interest,
      if (focus != null) 'focus': focus,
    };
  }

  factory EmotivMetricsData.fromJson(Map<String, dynamic> json) {
    return EmotivMetricsData(
      engagement: json['engagement']?.toDouble(),
      excitement: json['excitement']?.toDouble(),
      stress: json['stress']?.toDouble(),
      relaxation: json['relaxation']?.toDouble(),
      interest: json['interest']?.toDouble(),
      focus: json['focus']?.toDouble(),
    );
  }
}

/// Stress color enum
enum StressColor {
  green, // Low stress (0-40)
  orange, // Medium stress (41-70)
  red, // High stress (71-100)
}

extension StressColorExtension on StressColor {
  int get hexValue {
    switch (this) {
      case StressColor.green:
        return 0xFF8FB996;
      case StressColor.orange:
        return 0xFFF6B93B;
      case StressColor.red:
        return 0xFFE57373;
    }
  }
}
