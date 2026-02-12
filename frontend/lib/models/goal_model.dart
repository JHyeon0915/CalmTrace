import 'package:flutter/material.dart';

/// Represents a goal type that users can select
class GoalOption {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color iconColor;
  final GoalDestination destination;

  const GoalOption({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.iconColor,
    required this.destination,
  });
}

/// Where completing/tapping a goal should navigate to
enum GoalDestination {
  breathing, // Guided Breathing Screen
  tracking, // Tracking page (Stress Levels)
  therapy, // Therapy Hub
  games, // Games page
  chat, // AI Coach chat
}

/// All available goals users can choose from
class AvailableGoals {
  static const List<GoalOption> all = [
    GoalOption(
      id: 'breathing',
      title: 'Practice Breathing',
      description: 'Complete a breathing exercise',
      icon: Icons.air,
      iconColor: Color(0xFF5B9BD5),
      destination: GoalDestination.breathing,
    ),
    GoalOption(
      id: 'stress_check',
      title: 'Check Stress Levels',
      description: 'Monitor your stress biomarkers',
      icon: Icons.show_chart,
      iconColor: Color(0xFFE57373),
      destination: GoalDestination.tracking,
    ),
    GoalOption(
      id: 'therapy',
      title: 'Try a Therapy Technique',
      description: 'Use mindfulness or grounding',
      icon: Icons.self_improvement,
      iconColor: Color(0xFF81C784),
      destination: GoalDestination.therapy,
    ),
    GoalOption(
      id: 'games',
      title: 'Play a Relaxing Game',
      description: 'Unwind with a calm activity',
      icon: Icons.sports_esports,
      iconColor: Color(0xFF64B5F6),
      destination: GoalDestination.games,
    ),
    GoalOption(
      id: 'chat',
      title: 'Chat with AI Coach',
      description: 'Reflect on your feelings',
      icon: Icons.chat_bubble_outline,
      iconColor: Color(0xFFFFB74D),
      destination: GoalDestination.chat,
    ),
  ];

  static GoalOption? getById(String id) {
    try {
      return all.firstWhere((goal) => goal.id == id);
    } catch (e) {
      return null;
    }
  }
}

/// Represents a user's selected goal with completion status
class UserGoal {
  final String id;
  final String goalType;
  final String title;
  final String? description;
  final bool isCompleted;
  final DateTime? completedAt;

  UserGoal({
    required this.id,
    required this.goalType,
    required this.title,
    this.description,
    this.isCompleted = false,
    this.completedAt,
  });

  factory UserGoal.fromJson(Map<String, dynamic> json) {
    return UserGoal(
      id: json['id'] ?? '',
      goalType: json['goalType'] ?? json['goal_type'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      isCompleted: json['isCompleted'] ?? json['is_completed'] ?? false,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
    );
  }

  /// Get the GoalOption details for this user goal
  GoalOption? get goalOption => AvailableGoals.getById(goalType);
}
