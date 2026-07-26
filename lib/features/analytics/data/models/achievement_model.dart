import 'package:flutter/material.dart';

enum AchievementCategory {
  study('Study'),
  gym('Gym'),
  streak('Streaks'),
  goals('Goals'),
  mastery('Mastery');

  const AchievementCategory(this.label);
  final String label;
}

enum AchievementDifficulty {
  bronze('Bronze', Color(0xFFCD7F32)),
  silver('Silver', Color(0xFFC0C0C0)),
  gold('Gold', Color(0xFFFFD700)),
  platinum('Platinum', Color(0xFFE5E4E2)),
  diamond('Diamond', Color(0xFFB9F2FF));

  const AchievementDifficulty(this.label, this.color);
  final String label;
  final Color color;
}

class AchievementModel {
  final String id;
  final String title;
  final String description;
  final AchievementCategory category;
  final AchievementDifficulty difficulty;
  final IconData icon;
  final Color color;
  final double currentValue;
  final double targetValue;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  const AchievementModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.difficulty,
    required this.icon,
    required this.color,
    required this.currentValue,
    required this.targetValue,
    required this.isUnlocked,
    this.unlockedAt,
  });

  double get progressRatio => targetValue > 0 ? (currentValue / targetValue).clamp(0.0, 1.0) : 0.0;
  int get progressPercent => (progressRatio * 100).round();
}
