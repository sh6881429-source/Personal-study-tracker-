class YashBotContextModel {
  final String userName;
  final double totalStudyHours;
  final double todayStudyHours;
  final double weeklyStudyHours;
  final double monthlyStudyHours;
  final int totalStudySessions;
  final double averageSessionMinutes;
  final double longestSessionMinutes;
  final String mostProductiveDay;
  final String mostProductiveTimeSlot;
  final int currentStudyStreak;
  final int dailyGoalMinutes;
  final int weeklyGoalHours;
  final int consistencyScore;
  final String consistencyLevel;
  final int totalSubjects;
  final int completedChapters;
  final int pendingChapters;
  final int completedRevisions;
  final int remainingRevisions;
  final int upcomingRevisions;
  final int gymPresentDays;
  final int gymAbsentDays;
  final int currentGymStreak;
  final double gymAttendancePercentage;
  final int totalBookmarks;
  final int pinnedBookmarks;
  final int pendingBookmarks;
  final int uploadedPdfs;
  final int favouritePdfs;
  final double pdfStorageUsedMb;
  final int unlockedAchievementsCount;
  final List<String> subjectNames;
  final List<String> subjectPerformance;
  final List<String> topStudiedChapters;
  final List<String> productivityInsights;

  YashBotContextModel({
    required this.userName,
    required this.totalStudyHours,
    required this.todayStudyHours,
    required this.weeklyStudyHours,
    required this.monthlyStudyHours,
    required this.totalStudySessions,
    required this.averageSessionMinutes,
    required this.longestSessionMinutes,
    required this.mostProductiveDay,
    required this.mostProductiveTimeSlot,
    required this.currentStudyStreak,
    required this.dailyGoalMinutes,
    required this.weeklyGoalHours,
    required this.consistencyScore,
    required this.consistencyLevel,
    required this.totalSubjects,
    required this.completedChapters,
    required this.pendingChapters,
    required this.completedRevisions,
    required this.remainingRevisions,
    required this.upcomingRevisions,
    required this.gymPresentDays,
    required this.gymAbsentDays,
    required this.currentGymStreak,
    required this.gymAttendancePercentage,
    required this.totalBookmarks,
    required this.pinnedBookmarks,
    required this.pendingBookmarks,
    required this.uploadedPdfs,
    required this.favouritePdfs,
    required this.pdfStorageUsedMb,
    required this.unlockedAchievementsCount,
    required this.subjectNames,
    required this.subjectPerformance,
    required this.topStudiedChapters,
    required this.productivityInsights,
  });

  String toFormattedPromptContext() {
    return '''
User Profile & PrepTracker State:
- Student Name: $userName
- Total Study Time: ${totalStudyHours.toStringAsFixed(1)} hours across $totalStudySessions sessions
- Today Study Time: ${todayStudyHours.toStringAsFixed(1)} hours (Daily Goal: ${(dailyGoalMinutes / 60).toStringAsFixed(1)} hrs)
- Weekly Study Time: ${weeklyStudyHours.toStringAsFixed(1)} hours (Weekly Goal: $weeklyGoalHours hrs)
- Monthly Study Time: ${monthlyStudyHours.toStringAsFixed(1)} hours
- Session Pattern: ${averageSessionMinutes.toStringAsFixed(0)} min average, ${longestSessionMinutes.toStringAsFixed(0)} min longest; best day: $mostProductiveDay; best time: $mostProductiveTimeSlot
- Study Streak: $currentStudyStreak Days
- Consistency Score: $consistencyScore / 900 (Level: $consistencyLevel)
- Syllabus Progress: $completedChapters Completed, $pendingChapters Pending across $totalSubjects Subjects (${subjectNames.join(', ')})
- Revisions: $completedRevisions completed, $remainingRevisions remaining, $upcomingRevisions upcoming
- Gym Attendance: $gymPresentDays Present, $gymAbsentDays Absent ($currentGymStreak Days Streak, ${gymAttendancePercentage.toStringAsFixed(0)}% Rate)
- Resource Library: $totalBookmarks Bookmarks ($pinnedBookmarks pinned, $pendingBookmarks pending), $uploadedPdfs PDF Documents ($favouritePdfs favourites, ${pdfStorageUsedMb.toStringAsFixed(1)} MB)
- Milestones Unlocked: $unlockedAchievementsCount Achievements
- Subject Performance: ${subjectPerformance.isEmpty ? 'No study sessions recorded yet.' : subjectPerformance.join('; ')}
- Top Studied Chapters: ${topStudiedChapters.isEmpty ? 'No chapter study data available.' : topStudiedChapters.join(', ')}
- Current Insights: ${productivityInsights.isEmpty ? 'No additional insights available.' : productivityInsights.join(' | ')}
''';
  }
}
