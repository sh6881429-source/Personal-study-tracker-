import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:prep_tracker/core/constants/app_colors.dart';
import 'package:prep_tracker/core/constants/app_spacing.dart';
import 'package:prep_tracker/features/auth/presentation/providers/auth_provider.dart';
import 'package:prep_tracker/features/home/presentation/providers/home_provider.dart';
import 'package:prep_tracker/features/home/presentation/widgets/dashboard_header.dart';
import 'package:prep_tracker/features/home/presentation/widgets/dashboard_cards.dart';
import 'package:prep_tracker/features/home/presentation/widgets/quick_actions.dart';
import 'package:prep_tracker/features/study/presentation/providers/study_timer_provider.dart';
import 'package:prep_tracker/features/analytics/presentation/providers/analytics_provider.dart';
import 'package:prep_tracker/shared/widgets/app_drawer.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final dashboardState = ref.watch(homeControllerProvider);
    final timerState = ref.watch(studyTimerProvider);
    final weeklyDaysAsync = ref.watch(weeklyStudyDaysProvider);
    final studyStatsAsync = ref.watch(studyStatsProvider);

    final userName = authState.profile?.name ??
        authState.supabaseUser?.email?.split('@').first ??
        'Yash';

    final weeklyDays = weeklyDaysAsync.value ?? <int>{};
    final weeklyHours = studyStatsAsync.value?.weeklyHours ?? 0.0;
    final todayMinutes = studyStatsAsync.value?.todayMinutes ?? 0;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: const AppDrawer(),
      body: SafeArea(
        child: dashboardState.when(
          loading: () => const _HomeShimmerLoading(),
          error: (err, _) => Center(child: Text('Error: $err')),
          data: (data) {
            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                await ref.read(homeControllerProvider.notifier).refreshDashboard();
                ref.invalidate(weeklyStudyDaysProvider);
                ref.invalidate(studyStatsProvider);
                ref.invalidate(consistencyScoreProvider);
                ref.invalidate(achievementsProvider);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── 1. Top Bar ──
                    const HomeTopBar(),
                    const SizedBox(height: 14),

                    // ── 2. Yellow Welcome Banner ──
                    WelcomeBanner(userName: userName),
                    const SizedBox(height: 16),

                    // ── 3. First Row Grid (Today's Study Goal & Study Timer) ──
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TodayStudyGoalCard(
                            studyMinutes: data.studyMinutesToday,
                            goalMinutes: data.dailyGoal?.studyGoalMinutes ?? 120,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: StudyTimerCard(
                            timerState: timerState,
                            accumulatedSecondsToday: todayMinutes * 60,
                            onStartTap: () {
                              final notifier = ref.read(studyTimerProvider.notifier);
                              if (timerState.status == TimerStatus.running) {
                                final session = notifier.stopSession();
                                if (session != null) {
                                  ref
                                      .read(studyTimerProvider.notifier)
                                      .resetTimer();
                                  refreshDashboardAndStats(ref);
                                }
                              } else {
                                notifier.startTimer();
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // ── 4. Second Row Grid (Gym Progress & Daily Streak) ──
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: GymProgressCard(data: data),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DailyStreakCard(
                            streakCount: data.studyStreak,
                            weeklyDays: weeklyDays,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // ── 5. Third Row Grid (Syllabus, Analytics, Achievements) ──
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: SyllabusCard(
                            data: data,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: ConsistencyScoreCard(),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: AchievementsCard(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ── 6. Quick Actions Grid ──
                    const QuickActionsGrid(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// ── Home Screen Shimmer Skeleton Loading ──
class _HomeShimmerLoading extends StatelessWidget {
  const _HomeShimmerLoading();

  @override
  Widget build(BuildContext context) {
    // Premium soft colors for shimmer skeleton
    final baseColor = Colors.grey.shade300;
    final highlightColor = Colors.grey.shade100;

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Top Bar Shimmer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(width: 120, height: 16, color: Colors.white),
                        const SizedBox(height: 6),
                        Container(width: 80, height: 10, color: Colors.white),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // 2. Banner Shimmer
            Container(
              width: double.infinity,
              height: 125,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 16),

            // 3. First Row Cards Shimmer (Progress & Timer)
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 4. Second Row Cards Shimmer (Gym & Streak)
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 5. Third Row Cards Shimmer (Goal, Analytics, Achievements)
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 90,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    height: 90,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    height: 90,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 6. Quick Actions Shimmer
            Container(
              width: double.infinity,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
