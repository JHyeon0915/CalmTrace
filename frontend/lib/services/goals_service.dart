import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../network/api_client.dart';
import '../models/goal_model.dart';

class GoalsService {
  final ApiClient _apiClient = ApiClient();

  /// Get today's daily goals
  Future<DailyGoalsData> getDailyGoals() async {
    try {
      final response = await _apiClient.get('/goals/daily');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return DailyGoalsData.fromJson(data);
      } else {
        throw Exception('Failed to get goals: ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting goals: $e');
      }
      return DailyGoalsData(
        date: DateTime.now().toIso8601String().split('T')[0],
        goals: [],
        completedCount: 0,
        totalCount: 0,
      );
    }
  }

  /// Set/update user's daily goals
  Future<DailyGoalsData> setDailyGoals(List<String> goalTypes) async {
    try {
      final response = await _apiClient.post(
        '/goals/set',
        body: json.encode({'goalTypes': goalTypes}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return DailyGoalsData.fromJson(data);
      } else {
        throw Exception('Failed to set goals: ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error setting goals: $e');
      }
      rethrow;
    }
  }

  /// Complete a specific goal
  Future<GoalCompleteResult> completeGoal(String goalType) async {
    try {
      final response = await _apiClient.post(
        '/goals/complete',
        body: json.encode({'goalType': goalType}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return GoalCompleteResult.fromJson(data);
      } else {
        throw Exception('Failed to complete goal: ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error completing goal: $e');
      }
      return GoalCompleteResult(
        success: false,
        goalType: goalType,
        dailyProgress: 0,
        totalGoals: 0,
        streakUpdated: false,
      );
    }
  }

  /// Reset daily goals (for testing)
  Future<void> resetDailyGoals() async {
    try {
      await _apiClient.post('/goals/reset');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error resetting goals: $e');
      }
    }
  }
}

class DailyGoalsData {
  final String date;
  final List<UserGoal> goals;
  final int completedCount;
  final int totalCount;

  DailyGoalsData({
    required this.date,
    required this.goals,
    required this.completedCount,
    required this.totalCount,
  });

  factory DailyGoalsData.fromJson(Map<String, dynamic> json) {
    return DailyGoalsData(
      date: json['date'] ?? '',
      goals:
          (json['goals'] as List?)?.map((g) => UserGoal.fromJson(g)).toList() ??
          [],
      completedCount: json['completedCount'] ?? 0,
      totalCount: json['totalCount'] ?? 0,
    );
  }

  /// Get list of goal type IDs
  List<String> get goalTypeIds => goals.map((g) => g.goalType).toList();
}

class GoalCompleteResult {
  final bool success;
  final String goalType;
  final DateTime? completedAt;
  final int dailyProgress;
  final int totalGoals;
  final bool streakUpdated;
  final StreakUpdateData? streakData;

  GoalCompleteResult({
    required this.success,
    required this.goalType,
    this.completedAt,
    required this.dailyProgress,
    required this.totalGoals,
    required this.streakUpdated,
    this.streakData,
  });

  factory GoalCompleteResult.fromJson(Map<String, dynamic> json) {
    return GoalCompleteResult(
      success: json['success'] ?? false,
      goalType: json['goalType'] ?? '',
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      dailyProgress: json['dailyProgress'] ?? 0,
      totalGoals: json['totalGoals'] ?? 0,
      streakUpdated: json['streakUpdated'] ?? false,
      streakData: json['streakData'] != null
          ? StreakUpdateData.fromJson(json['streakData'])
          : null,
    );
  }
}

class StreakUpdateData {
  final int streakCount;
  final bool isNewStreak;
  final bool shouldCelebrate;
  final String? message;
  final int? milestoneReached;

  StreakUpdateData({
    required this.streakCount,
    required this.isNewStreak,
    required this.shouldCelebrate,
    this.message,
    this.milestoneReached,
  });

  factory StreakUpdateData.fromJson(Map<String, dynamic> json) {
    return StreakUpdateData(
      streakCount: json['streakCount'] ?? 0,
      isNewStreak: json['isNewStreak'] ?? false,
      shouldCelebrate: json['shouldCelebrate'] ?? false,
      message: json['message'],
      milestoneReached: json['milestoneReached'],
    );
  }
}
