import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/stress_prediction_model.dart';
import '../network/api_client.dart';

/// Service for stress level prediction via ML backend
class StressPredictionService {
  final ApiClient _apiClient = ApiClient();

  // ==================== Prediction ====================

  /// Predict stress level from sensor data
  Future<StressPrediction> predictStress({
    Map<String, List<double>>? eegChannels,
    int eegSamplingRate = 128,
    List<double>? hrvValues,
    List<double>? rrValues,
    List<double>? hrValues,
    EmotivMetricsData? emotivMetrics,
  }) async {
    try {
      final body = <String, dynamic>{};

      // Add EEG data if available
      if (eegChannels != null && eegChannels.isNotEmpty) {
        body['eeg_data'] = {
          'channels': eegChannels,
          'sampling_rate': eegSamplingRate,
        };
      }

      // Add health data if available
      if (hrvValues != null || rrValues != null || hrValues != null) {
        body['health_data'] = {
          if (hrvValues != null) 'hrv_values': hrvValues,
          if (rrValues != null) 'rr_values': rrValues,
          if (hrValues != null) 'hr_values': hrValues,
        };
      }

      // Add EMOTIV metrics if available
      if (emotivMetrics != null) {
        body['emotiv_metrics'] = emotivMetrics.toJson();
      }

      final response = await _apiClient.post(
        '/stress/predict',
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return StressPrediction.fromJson(data);
      } else {
        debugPrint('❌ Stress prediction failed: ${response.body}');
        throw Exception('Failed to predict stress: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Error predicting stress: $e');
      rethrow;
    }
  }

  /// Predict stress with explainability (feature contributions)
  Future<StressPredictionWithExplanation> predictStressWithExplanation({
    Map<String, List<double>>? eegChannels,
    int eegSamplingRate = 128,
    List<double>? hrvValues,
    List<double>? rrValues,
    List<double>? hrValues,
    EmotivMetricsData? emotivMetrics,
  }) async {
    try {
      final body = <String, dynamic>{};

      if (eegChannels != null && eegChannels.isNotEmpty) {
        body['eeg_data'] = {
          'channels': eegChannels,
          'sampling_rate': eegSamplingRate,
        };
      }

      if (hrvValues != null || rrValues != null || hrValues != null) {
        body['health_data'] = {
          if (hrvValues != null) 'hrv_values': hrvValues,
          if (rrValues != null) 'rr_values': rrValues,
          if (hrValues != null) 'hr_values': hrValues,
        };
      }

      if (emotivMetrics != null) {
        body['emotiv_metrics'] = emotivMetrics.toJson();
      }

      final response = await _apiClient.post(
        '/stress/predict/explain',
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return StressPredictionWithExplanation.fromJson(data);
      } else {
        debugPrint(
          '❌ Stress prediction with explanation failed: ${response.body}',
        );
        throw Exception('Failed to predict stress: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Error predicting stress with explanation: $e');
      rethrow;
    }
  }

  // ==================== History ====================

  /// Get stress prediction history
  Future<StressHistory> getStressHistory({int days = 7}) async {
    try {
      final response = await _apiClient.get('/stress/history?days=$days');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return StressHistory.fromJson(data);
      } else {
        debugPrint('❌ Failed to get stress history: ${response.body}');
        throw Exception('Failed to get stress history');
      }
    } catch (e) {
      debugPrint('❌ Error getting stress history: $e');
      rethrow;
    }
  }

  /// Get latest stress prediction
  Future<StressPrediction?> getLatestPrediction() async {
    try {
      final response = await _apiClient.get('/stress/latest');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return StressPrediction.fromJson(data);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        debugPrint('❌ Failed to get latest prediction: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error getting latest prediction: $e');
      return null;
    }
  }

  // ==================== Model Status ====================

  /// Check if ML models are loaded
  Future<ModelStatus> getModelStatus() async {
    try {
      final response = await _apiClient.get('/stress/status');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ModelStatus.fromJson(data);
      } else {
        return ModelStatus(modelsLoaded: false, availableModels: []);
      }
    } catch (e) {
      debugPrint('❌ Error checking model status: $e');
      return ModelStatus(modelsLoaded: false, availableModels: []);
    }
  }

  // ==================== Mock Prediction ====================

  /// Generate mock prediction for testing
  Future<StressPrediction> mockPredict({
    int stressLevel = 35,
    int confidence = 92,
  }) async {
    try {
      final response = await _apiClient.post(
        '/stress/mock-predict?stress_level=$stressLevel&confidence=$confidence',
        body: '{}',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return StressPrediction.fromJson(data);
      } else {
        throw Exception('Failed to create mock prediction');
      }
    } catch (e) {
      debugPrint('❌ Error creating mock prediction: $e');
      rethrow;
    }
  }

  // ==================== Helper Methods ====================

  /// Convert health data service output to prediction input
  Future<StressPrediction> predictFromHealthData({
    required List<double> hrvValues,
    required List<double> rrValues,
    List<double>? hrValues,
  }) async {
    return predictStress(
      hrvValues: hrvValues,
      rrValues: rrValues,
      hrValues: hrValues,
    );
  }

  /// Convert EMOTIV service output to prediction input
  Future<StressPrediction> predictFromEmotivData({
    required Map<String, List<double>> eegChannels,
    EmotivMetricsData? metrics,
  }) async {
    return predictStress(eegChannels: eegChannels, emotivMetrics: metrics);
  }

  /// Combined prediction from all available sources
  Future<StressPrediction> predictFromAllSources({
    Map<String, List<double>>? eegChannels,
    List<double>? hrvValues,
    List<double>? rrValues,
    List<double>? hrValues,
    EmotivMetricsData? emotivMetrics,
  }) async {
    return predictStress(
      eegChannels: eegChannels,
      hrvValues: hrvValues,
      rrValues: rrValues,
      hrValues: hrValues,
      emotivMetrics: emotivMetrics,
    );
  }
}
