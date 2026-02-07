import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../network/api_client.dart';

class StreakService {
  final ApiClient _api = ApiClient();

  /// Get current streak data (call on app launch/login)
  Future<StreakData> getStreakData() async {
    try {
      final response = await _api.get('/streak');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return StreakData.fromJson(data);
      } else {
        throw Exception('Failed to get streak: ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting streak: $e');
      }
      return StreakData(streakCount: 0);
    }
  }

  /// Get current streak count
  Future<int> getStreakCount() async {
    final data = await getStreakData();
    return data.streakCount;
  }

  /// Check and update streak (validates and resets if broken)
  /// Call this on app launch
  Future<int> checkAndUpdateStreak() async {
    final data = await getStreakData();
    return data.streakCount;
  }

  /// Complete a goal and update streak
  Future<StreakResult> completeGoal() async {
    try {
      final response = await _api.post('/streak/complete');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return StreakResult.fromJson(data);
      } else {
        throw Exception('Failed to complete goal: ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error completing goal: $e');
      }
      return StreakResult(
        streakCount: 0,
        isNewStreak: false,
        shouldCelebrate: false,
      );
    }
  }

  /// Check if user has seen today's celebration
  Future<bool> hasSeenTodaysCelebration() async {
    try {
      final response = await _api.get('/streak/celebration/seen');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['hasSeenToday'] ?? false;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking celebration: $e');
      }
      return false;
    }
  }

  /// Mark celebration as seen
  Future<void> markCelebrationSeen() async {
    try {
      final response = await _api.post('/streak/celebration/seen');

      if (response.statusCode != 200) {
        throw Exception('Failed to mark celebration seen: ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error marking celebration seen: $e');
      }
    }
  }

  /// Reset streak (for testing)
  Future<void> resetStreak() async {
    try {
      await _api.post('/streak/reset');
    } catch (e) {
      if (kDebugMode) {
        print('Error resetting streak: $e');
      }
    }
  }
}

class StreakData {
  final int streakCount;
  final DateTime? lastCompletionDate;
  final DateTime? lastCelebrationDate;
  final int longestStreak;

  StreakData({
    required this.streakCount,
    this.lastCompletionDate,
    this.lastCelebrationDate,
    this.longestStreak = 0,
  });

  factory StreakData.fromJson(Map<String, dynamic> json) {
    return StreakData(
      streakCount: json['streakCount'] ?? 0,
      lastCompletionDate: json['lastCompletionDate'] != null
          ? DateTime.parse(json['lastCompletionDate'])
          : null,
      lastCelebrationDate: json['lastCelebrationDate'] != null
          ? DateTime.parse(json['lastCelebrationDate'])
          : null,
      longestStreak: json['longestStreak'] ?? 0,
    );
  }
}

class StreakResult {
  final int streakCount;
  final bool isNewStreak;
  final bool shouldCelebrate;
  final String? message;
  final int? milestoneReached;

  StreakResult({
    required this.streakCount,
    required this.isNewStreak,
    required this.shouldCelebrate,
    this.message,
    this.milestoneReached,
  });

  factory StreakResult.fromJson(Map<String, dynamic> json) {
    return StreakResult(
      streakCount: json['streakCount'] ?? 0,
      isNewStreak: json['isNewStreak'] ?? false,
      shouldCelebrate: json['shouldCelebrate'] ?? false,
      message: json['message'],
      milestoneReached: json['milestoneReached'],
    );
  }
}
