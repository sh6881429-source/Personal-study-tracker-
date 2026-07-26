import 'package:flutter/material.dart';

/// ── Score Level Classification ──
enum ConsistencyLevel {
  needsImprovement('Needs Improvement', Color(0xFFEF4444), 300, 499),
  gettingStarted('Getting Started', Color(0xFFF97316), 500, 649),
  consistent('Consistent', Color(0xFFEAB308), 650, 749),
  excellent('Excellent', Color(0xFF10B981), 750, 849),
  eliteDiscipline('Elite Discipline', Color(0xFF6366F1), 850, 900);

  const ConsistencyLevel(this.label, this.color, this.minScore, this.maxScore);

  final String label;
  final Color color;
  final int minScore;
  final int maxScore;

  static ConsistencyLevel fromScore(int score) {
    if (score >= 850) return ConsistencyLevel.eliteDiscipline;
    if (score >= 750) return ConsistencyLevel.excellent;
    if (score >= 650) return ConsistencyLevel.consistent;
    if (score >= 500) return ConsistencyLevel.gettingStarted;
    return ConsistencyLevel.needsImprovement;
  }
}

/// ── Consistency Score Model ──
class ConsistencyScoreModel {
  final int currentScore; // 300 -> 900
  final int previousScore;
  final int highestScore;
  final int lowestScore;
  final ConsistencyLevel level;

  // Breakdown Contributions (Percentages 0% -> 100%)
  final double studyConsistencyPercent;
  final double gymConsistencyPercent;
  final double goalCompletionPercent;
  final double streakConsistencyPercent;
  final double overallConsistencyPercent;

  // Monthly Score History (Date -> Score)
  final List<MapEntry<DateTime, int>> monthlyScoreHistory;

  const ConsistencyScoreModel({
    required this.currentScore,
    required this.previousScore,
    required this.highestScore,
    required this.lowestScore,
    required this.level,
    required this.studyConsistencyPercent,
    required this.gymConsistencyPercent,
    required this.goalCompletionPercent,
    required this.streakConsistencyPercent,
    required this.overallConsistencyPercent,
    required this.monthlyScoreHistory,
  });

  factory ConsistencyScoreModel.initial() {
    return const ConsistencyScoreModel(
      currentScore: 350,
      previousScore: 350,
      highestScore: 350,
      lowestScore: 350,
      level: ConsistencyLevel.needsImprovement,
      studyConsistencyPercent: 0,
      gymConsistencyPercent: 0,
      goalCompletionPercent: 0,
      streakConsistencyPercent: 0,
      overallConsistencyPercent: 0,
      monthlyScoreHistory: [],
    );
  }
}
