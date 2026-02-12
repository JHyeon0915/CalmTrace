import 'package:flutter/material.dart';

/// A daily wellness tip to display on the dashboard
class DailyTip {
  final String id;
  final String description;
  final String actionPrefix;
  final String actionText;
  final String emoji;
  final Color? accentColor;

  const DailyTip({
    required this.id,
    required this.description,
    required this.actionPrefix,
    required this.actionText,
    this.emoji = '💡',
    this.accentColor,
  });
}

/// Collection of daily tips for the app
class DailyTips {
  static const List<DailyTip> all = [
    DailyTip(
      id: 'screen_break',
      description: 'Take a break from screens for 15 minutes.',
      actionPrefix: 'Try this:',
      actionText: 'Digital overload contributes to mental fatigue and stress.',
      emoji: '💡',
    ),
    DailyTip(
      id: 'deep_breathing',
      description: 'Practice deep breathing for 5 minutes.',
      actionPrefix: 'Why it helps:',
      actionText:
          'Deep breathing activates your parasympathetic nervous system, reducing stress hormones.',
      emoji: '🌬️',
    ),
    DailyTip(
      id: 'hydration',
      description: 'Drink a full glass of water right now.',
      actionPrefix: 'Did you know:',
      actionText:
          'Even mild dehydration can affect your mood and increase anxiety levels.',
      emoji: '💧',
    ),
    DailyTip(
      id: 'gratitude',
      description: 'Write down three things you\'re grateful for.',
      actionPrefix: 'The science:',
      actionText:
          'Gratitude practices can increase happiness and reduce symptoms of depression.',
      emoji: '🙏',
    ),
    DailyTip(
      id: 'movement',
      description: 'Take a short walk, even just 10 minutes.',
      actionPrefix: 'Fun fact:',
      actionText:
          'Walking releases endorphins and can improve your mood for hours afterward.',
      emoji: '🚶',
    ),
    DailyTip(
      id: 'nature',
      description: 'Spend a few minutes looking at nature or plants.',
      actionPrefix: 'Research shows:',
      actionText:
          'Exposure to nature, even through a window, can lower cortisol levels.',
      emoji: '🌿',
    ),
    DailyTip(
      id: 'stretch',
      description: 'Do a quick 2-minute stretching routine.',
      actionPrefix: 'Your body will thank you:',
      actionText:
          'Stretching releases muscle tension that builds up from stress and poor posture.',
      emoji: '🧘',
    ),
    DailyTip(
      id: 'connection',
      description: 'Send a kind message to someone you care about.',
      actionPrefix: 'Connection matters:',
      actionText:
          'Social bonds are one of the strongest predictors of mental well-being.',
      emoji: '💬',
    ),
    DailyTip(
      id: 'mindful_eating',
      description: 'Eat your next meal without any distractions.',
      actionPrefix: 'Mindful eating:',
      actionText:
          'Focusing on your food improves digestion and helps you feel more satisfied.',
      emoji: '🍽️',
    ),
    DailyTip(
      id: 'sleep_prep',
      description:
          'Set a reminder to start winding down 30 minutes before bed.',
      actionPrefix: 'Sleep hygiene:',
      actionText:
          'A consistent wind-down routine signals your brain that it\'s time to rest.',
      emoji: '🌙',
    ),
  ];

  /// Get the tip for today based on the current date
  /// This ensures the same tip shows all day, but changes each day
  static DailyTip getTodaysTip() {
    final now = DateTime.now();
    // Create a seed from the date (year + month + day)
    final dateSeed = now.year * 10000 + now.month * 100 + now.day;
    // Use modulo to get a consistent index for the day
    final index = dateSeed % all.length;
    return all[index];
  }

  /// Get a specific tip by ID
  static DailyTip? getTipById(String id) {
    try {
      return all.firstWhere((tip) => tip.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Get a random tip (for testing or variety)
  static DailyTip getRandomTip() {
    final index = DateTime.now().millisecondsSinceEpoch % all.length;
    return all[index];
  }
}
