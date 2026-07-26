import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:prep_tracker/core/constants/app_colors.dart';
import 'package:prep_tracker/features/auth/presentation/providers/auth_provider.dart';
import 'package:prep_tracker/features/analytics/presentation/providers/analytics_provider.dart';
import 'package:prep_tracker/features/analytics/presentation/widgets/analytics_filter_bar.dart';
import 'package:prep_tracker/features/analytics/presentation/widgets/overview_cards_grid.dart';
import 'package:prep_tracker/features/analytics/presentation/widgets/consistency_score_widget.dart';
import 'package:prep_tracker/features/analytics/presentation/widgets/study_charts_widget.dart';
import 'package:prep_tracker/features/analytics/presentation/widgets/gym_analytics_widget.dart';
import 'package:prep_tracker/features/analytics/presentation/widgets/goal_pdf_bookmark_widget.dart';
import 'package:prep_tracker/features/analytics/presentation/widgets/productivity_insights_widget.dart';
import 'package:prep_tracker/features/analytics/presentation/widgets/achievements_grid_widget.dart';
import 'package:prep_tracker/features/analytics/data/services/analytics_pdf_service.dart';
import 'package:prep_tracker/features/analytics/data/services/analytics_csv_service.dart';
import 'package:prep_tracker/features/study/data/repositories/study_session_repository_impl.dart';
import 'package:prep_tracker/shared/widgets/app_drawer.dart';
import 'package:prep_tracker/shared/widgets/app_snackbar.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  final int initialTabIndex;
  const AnalyticsScreen({super.key, this.initialTabIndex = 0});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 5,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 4),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _exportPdf() async {
    setState(() => _isExporting = true);
    try {
      final auth = ref.read(authProvider);
      final userName = auth.profile?.name ?? auth.supabaseUser?.email?.split('@').first ?? 'User';
      final analyticsData = await ref.read(analyticsDataProvider.future);
      final scoreModel = await ref.read(consistencyScoreProvider.future);
      final achievements = await ref.read(achievementsProvider.future);
      final filter = ref.read(analyticsDateFilterProvider);

      await AnalyticsPdfService.generateAndDownloadPdfReport(
        userName: userName,
        data: analyticsData,
        scoreModel: scoreModel,
        achievements: achievements,
        dateFilter: filter,
      );
      if (mounted) AppSnackbar.showSuccess(context, 'PDF report downloaded successfully!');
    } catch (err) {
      if (mounted) AppSnackbar.showError(context, 'Failed to generate PDF report: $err');
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _exportCsv() async {
    setState(() => _isExporting = true);
    try {
      final auth = ref.read(authProvider);
      final userId = auth.profile?.userId ?? auth.supabaseUser?.id ?? '';
      final analyticsData = await ref.read(analyticsDataProvider.future);
      final scoreModel = await ref.read(consistencyScoreProvider.future);
      final achievements = await ref.read(achievementsProvider.future);
      final sessions = await ref.read(studySessionRepositoryProvider).getSessions(userId);

      await AnalyticsCsvService.exportAnalyticsCsv(
        data: analyticsData,
        scoreModel: scoreModel,
        achievements: achievements,
        sessions: sessions,
      );
      if (mounted) AppSnackbar.showSuccess(context, 'CSV dataset downloaded successfully!');
    } catch (err) {
      if (mounted) AppSnackbar.showError(context, 'Failed to export CSV: $err');
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final analyticsAsync = ref.watch(analyticsDataProvider);
    final scoreAsync = ref.watch(consistencyScoreProvider);
    final achievementsAsync = ref.watch(achievementsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Text('Analytics & Discipline Hub', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        centerTitle: false,
        actions: [
          IconButton(
            icon: _isExporting
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                : const Icon(Icons.picture_as_pdf_rounded, color: AppColors.error),
            tooltip: 'Export PDF Report',
            onPressed: _isExporting ? null : _exportPdf,
          ),
          IconButton(
            icon: const Icon(Icons.table_chart_rounded, color: Color(0xFF10B981)),
            tooltip: 'Export CSV Data',
            onPressed: _isExporting ? null : _exportCsv,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: isDark ? Colors.white60 : AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12),
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Consistency Score'),
            Tab(text: 'Study & Subjects'),
            Tab(text: 'Gym & Goals'),
            Tab(text: 'Achievements'),
          ],
        ),
      ),
      body: SafeArea(
        child: analyticsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error loading analytics: $err')),
          data: (analyticsData) {
            return scoreAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error score: $err')),
              data: (scoreModel) {
                return achievementsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(child: Text('Error badges: $err')),
                  data: (achievements) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Filter Bar
                          const AnalyticsFilterBar(),
                          const SizedBox(height: 16),

                          // Tab Body Content
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.72,
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                // Tab 1: Overview
                                SingleChildScrollView(
                                  physics: const BouncingScrollPhysics(),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      OverviewCardsGrid(data: analyticsData, scoreModel: scoreModel),
                                      const SizedBox(height: 16),
                                      ProductivityInsightsWidget(insights: analyticsData.insights),
                                    ],
                                  ),
                                ),

                                // Tab 2: Consistency Score
                                SingleChildScrollView(
                                  physics: const BouncingScrollPhysics(),
                                  child: ConsistencyScoreWidget(scoreModel: scoreModel),
                                ),

                                // Tab 3: Study & Subjects
                                SingleChildScrollView(
                                  physics: const BouncingScrollPhysics(),
                                  child: StudyChartsWidget(data: analyticsData),
                                ),

                                // Tab 4: Gym & Goals
                                SingleChildScrollView(
                                  physics: const BouncingScrollPhysics(),
                                  child: Column(
                                    children: [
                                      GymAnalyticsWidget(data: analyticsData),
                                      const SizedBox(height: 16),
                                      GoalPdfBookmarkWidget(data: analyticsData),
                                    ],
                                  ),
                                ),

                                // Tab 5: Achievements
                                SingleChildScrollView(
                                  physics: const BouncingScrollPhysics(),
                                  child: AchievementsGridWidget(achievements: achievements),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
