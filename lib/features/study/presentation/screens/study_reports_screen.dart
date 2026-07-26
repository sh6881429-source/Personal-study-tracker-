import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:prep_tracker/core/constants/app_colors.dart';
import 'package:prep_tracker/features/auth/presentation/providers/auth_provider.dart';
import 'package:prep_tracker/features/study/data/models/study_session_model.dart';
import 'package:prep_tracker/features/study/data/services/pdf_report_service.dart';
import 'package:prep_tracker/features/study/presentation/providers/study_goal_provider.dart';
import 'package:prep_tracker/features/study/presentation/providers/study_timer_provider.dart';
import 'package:prep_tracker/features/syllabus/data/repositories/subject_repository_impl.dart';
import 'package:prep_tracker/features/syllabus/data/models/subject_model.dart';
import 'package:prep_tracker/shared/widgets/app_button.dart';
import 'package:prep_tracker/shared/widgets/app_snackbar.dart';

class StudyReportsScreen extends ConsumerStatefulWidget {
  const StudyReportsScreen({super.key});

  @override
  ConsumerState<StudyReportsScreen> createState() => _StudyReportsScreenState();
}

class _StudyReportsScreenState extends ConsumerState<StudyReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();
  bool _isGeneratingPdf = false;
  List<SubjectModel> _subjects = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    final auth = ref.read(authProvider);
    final userId = auth.profile?.userId ?? auth.supabaseUser?.id ?? '';
    if (userId.isNotEmpty) {
      try {
        final subs = await ref.read(subjectRepositoryProvider).getActiveSubjects(userId);
        if (mounted) setState(() => _subjects = subs);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.text;
    final asyncAllSessions = ref.watch(allSessionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Study Performance Reports', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        centerTitle: false,
        bottom: TabBar(
          controller: _tabController,
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: GoogleFonts.poppins(fontSize: 12),
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Today'),
            Tab(text: 'This Week'),
            Tab(text: 'This Month'),
            Tab(text: 'Custom'),
          ],
        ),
      ),
      body: asyncAllSessions.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading reports: $err')),
        data: (sessions) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildReportView('Today\'s Performance', DateTime.now(), DateTime.now(), sessions, isDark, textColor),
              _buildReportView('Weekly Performance', DateTime.now().subtract(const Duration(days: 7)), DateTime.now(), sessions, isDark, textColor),
              _buildReportView('Monthly Performance', DateTime.now().subtract(const Duration(days: 30)), DateTime.now(), sessions, isDark, textColor),
              _buildCustomReportView(sessions, isDark, textColor),
            ],
          );
        },
      ),
    );
  }

  Widget _buildReportView(String title, DateTime start, DateTime end, List<StudySessionModel> allSessions, bool isDark, Color textColor) {
    final startStr = start.toIso8601String().substring(0, 10);
    final endStr = end.toIso8601String().substring(0, 10);

    final filtered = allSessions.where((s) {
      final d = s.studyDate.toIso8601String().substring(0, 10);
      return d.compareTo(startStr) >= 0 && d.compareTo(endStr) <= 0;
    }).toList();

    final totalMins = filtered.fold<int>(0, (sum, s) => sum + s.durationMinutes);
    final totalHours = totalMins / 60.0;
    final sessionsCount = filtered.length;
    final avgDuration = sessionsCount > 0 ? (totalMins / sessionsCount).round() : 0;
    final longestDuration = filtered.isEmpty ? 0 : filtered.map((s) => s.durationMinutes).reduce((a, b) => a > b ? a : b);

    final goalsState = ref.watch(studyGoalProvider);
    final targetHours = goalsState.maybeWhen(
      data: (g) {
        if (title.contains('Today')) return g.dailyGoalHours;
        if (title.contains('Weekly')) return g.weeklyGoalHours;
        return g.monthlyGoalHours;
      },
      orElse: () => 6.0,
    );

    final goalPct = targetHours > 0 ? ((totalHours / targetHours) * 100).clamp(0.0, 100.0) : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stat Cards Summary Grid
          Row(
            children: [
              _buildMetricCard('Total Study Time', '${totalHours.toStringAsFixed(1)} hrs', Icons.timer_rounded, AppColors.primary, isDark, textColor),
              const SizedBox(width: 12),
              _buildMetricCard('Goal Progress', '${goalPct.toStringAsFixed(1)}%', Icons.stars_rounded, AppColors.secondary, isDark, textColor),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              _buildMetricCard('Completed Sessions', '$sessionsCount Logs', Icons.checklist_rounded, AppColors.accent, isDark, textColor),
              const SizedBox(width: 12),
              _buildMetricCard('Avg / Longest', '$avgDuration / $longestDuration mins', Icons.bar_chart_rounded, AppColors.warning, isDark, textColor),
            ],
          ),

          const SizedBox(height: 24),

          // Export PDF Section
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF262626) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white : AppColors.border, width: 3),
              boxShadow: const [BoxShadow(color: AppColors.shadow, offset: Offset(3, 3))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.picture_as_pdf_rounded, color: AppColors.error, size: 24),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Export PDF Report', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13, color: textColor), maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text('Download a high-quality PDF report', style: GoogleFonts.inter(fontSize: 10, color: isDark ? Colors.white60 : AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  icon: _isGeneratingPdf
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.download_rounded, size: 18),
                  label: Text(
                    _isGeneratingPdf ? 'Generating...' : 'Download PDF',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: AppColors.border, width: 2),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _isGeneratingPdf ? null : () => _generateAndSharePdf(title, start, end, filtered),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Sessions Timeline Preview Table
          Text('Sessions in this Period', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15, color: textColor)),
          const SizedBox(height: 10),
          if (filtered.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              width: double.infinity,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF222222) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('No study sessions logged for this period.', style: GoogleFonts.inter(color: isDark ? Colors.white60 : AppColors.textSecondary)),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, idx) {
                final s = filtered[idx];
                final subName = _subjects.firstWhere((sub) => sub.id == s.subjectId, orElse: () => SubjectModel(id: '', userId: '', subjectName: 'Subject', color: '5B5FEF', icon: 'book')).subjectName;
                return ListTile(
                  dense: true,
                  tileColor: isDark ? const Color(0xFF222222) : Colors.grey.shade100,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  title: Text(subName, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: textColor)),
                  subtitle: Text('${s.sessionType} • ${DateFormat('MMM dd, hh:mm a').format(s.startTime)}', style: GoogleFonts.inter(fontSize: 11)),
                  trailing: Text('${s.durationMinutes} mins', style: GoogleFonts.poppins(fontWeight: FontWeight.w900, color: AppColors.primary)),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildCustomReportView(List<StudySessionModel> sessions, bool isDark, Color textColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Custom Date Range Picker Tile
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF262626) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white : AppColors.border, width: 3),
              boxShadow: const [BoxShadow(color: AppColors.shadow, offset: Offset(3, 3))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Custom Date Range Selection', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: textColor)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today_rounded, size: 16),
                        label: Text(DateFormat('MMM dd, yyyy').format(_startDate)),
                        onPressed: () async {
                          final picked = await showDatePicker(context: context, initialDate: _startDate, firstDate: DateTime(2025), lastDate: DateTime.now());
                          if (picked != null) setState(() => _startDate = picked);
                        },
                      ),
                    ),
                    const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('to')),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today_rounded, size: 16),
                        label: Text(DateFormat('MMM dd, yyyy').format(_endDate)),
                        onPressed: () async {
                          final picked = await showDatePicker(context: context, initialDate: _endDate, firstDate: DateTime(2025), lastDate: DateTime.now());
                          if (picked != null) setState(() => _endDate = picked);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          _buildReportView('Custom Range', _startDate, _endDate, sessions, isDark, textColor),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color, bool isDark, Color textColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF262626) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? Colors.white : AppColors.border, width: 2.5),
          boxShadow: const [BoxShadow(color: AppColors.shadow, offset: Offset(2.5, 2.5))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.inter(fontSize: 10, color: isDark ? Colors.white60 : AppColors.textSecondary)),
                  const SizedBox(height: 2),
                  Text(value, style: GoogleFonts.poppins(fontWeight: FontWeight.w900, fontSize: 13, color: textColor), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateAndSharePdf(String reportTitle, DateTime start, DateTime end, List<StudySessionModel> sessions) async {
    setState(() => _isGeneratingPdf = true);
    try {
      final auth = ref.read(authProvider);
      final userName = auth.profile?.name ?? auth.supabaseUser?.email ?? 'Student';
      final goals = await ref.read(studyGoalProvider.future);

      final Uint8List pdfBytes = await PdfReportService.generateStudyReport(
        userName: userName,
        reportTitle: reportTitle,
        startDate: start,
        endDate: end,
        sessions: sessions,
        goals: goals,
        subjects: _subjects,
      );

      final fileName = 'PrepTracker_Study_Report_${reportTitle.replaceAll(' ', '_')}';
      await PdfReportService.printOrShareReport(fileName: fileName, pdfBytes: pdfBytes);

      if (mounted) AppSnackbar.showSuccess(context, 'PDF report ready!');
    } catch (e) {
      if (mounted) AppSnackbar.showError(context, 'PDF export error: $e');
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }
}
