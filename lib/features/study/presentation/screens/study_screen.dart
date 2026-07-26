import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:prep_tracker/core/constants/app_colors.dart';
import 'package:prep_tracker/features/auth/presentation/providers/auth_provider.dart';
import 'package:prep_tracker/features/study/data/models/study_session_model.dart';
import 'package:prep_tracker/features/study/presentation/providers/study_goal_provider.dart';
import 'package:prep_tracker/features/study/presentation/providers/study_timer_provider.dart';
import 'package:prep_tracker/features/study/data/repositories/study_session_repository_impl.dart';
import 'package:prep_tracker/features/syllabus/data/repositories/subject_repository_impl.dart';
import 'package:prep_tracker/features/syllabus/data/repositories/chapter_repository_impl.dart';
import 'package:prep_tracker/features/syllabus/data/models/subject_model.dart';
import 'package:prep_tracker/features/syllabus/data/models/chapter_model.dart';
import 'package:prep_tracker/shared/widgets/app_button.dart';
import 'package:prep_tracker/shared/widgets/app_snackbar.dart';

class StudyScreen extends ConsumerStatefulWidget {
  const StudyScreen({super.key});

  @override
  ConsumerState<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends ConsumerState<StudyScreen> {
  List<SubjectModel> _subjects = [];
  List<ChapterModel> _chapters = [];
  bool _isLoadingSubjects = false;
  bool _isLoadingChapters = false;
  final TextEditingController _notesController = TextEditingController();

  final List<String> _studyTypes = ['Self Study', 'Revision', 'Practice', 'Mock Test'];

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadSubjects() async {
    final auth = ref.read(authProvider);
    final userId = auth.profile?.userId ?? auth.supabaseUser?.id ?? '';
    if (userId.isEmpty) return;

    setState(() => _isLoadingSubjects = true);
    try {
      final subs = await ref.read(subjectRepositoryProvider).getActiveSubjects(userId);
      if (mounted) setState(() => _subjects = subs);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoadingSubjects = false);
    }
  }

  Future<void> _loadChapters(String subjectId) async {
    setState(() => _isLoadingChapters = true);
    try {
      final chaps = await ref.read(chapterRepositoryProvider).getChapters(subjectId);
      if (mounted) setState(() => _chapters = chaps);
    } catch (_) {
      if (mounted) setState(() => _chapters = []);
    } finally {
      if (mounted) setState(() => _isLoadingChapters = false);
    }
  }

  String _formatHHMMSS(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.text;

    final timerState = ref.watch(studyTimerProvider);
    final timerNotifier = ref.read(studyTimerProvider.notifier);
    final asyncGoals = ref.watch(studyGoalProvider);
    final asyncTodaySessions = ref.watch(todaySessionsProvider);
    final asyncStats = ref.watch(studyStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Study Focus Hub', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Goal Settings',
            onPressed: () => context.push('/study/goals'),
          ),
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Study History',
            onPressed: () => context.push('/study/history'),
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            tooltip: 'Study Reports',
            onPressed: () => context.push('/study/reports'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Section 1: Study Goals Cards (Daily / Weekly / Monthly) ──
            asyncGoals.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const SizedBox(),
              data: (goals) {
                final todayMins = asyncStats.asData?.value.todayMinutes ?? 0;
                final weeklyHrs = asyncStats.asData?.value.weeklyHours ?? 0.0;
                final monthlyHrs = asyncStats.asData?.value.monthlyHours ?? 0.0;

                final dailyPct = goals.dailyGoalMinutes > 0 ? (todayMins / goals.dailyGoalMinutes).clamp(0.0, 1.0) : 0.0;
                final weeklyPct = goals.weeklyGoalHours > 0 ? (weeklyHrs / goals.weeklyGoalHours).clamp(0.0, 1.0) : 0.0;
                final monthlyPct = goals.monthlyGoalHours > 0 ? (monthlyHrs / goals.monthlyGoalHours).clamp(0.0, 1.0) : 0.0;

                return Column(
                  children: [
                    Row(
                      children: [
                        _buildGoalCard(
                          title: 'Daily Goal',
                          current: '${(todayMins / 60.0).toStringAsFixed(1)} / ${goals.dailyGoalHours.toStringAsFixed(1)} h',
                          progress: dailyPct,
                          color: AppColors.primary,
                          isDark: isDark,
                          textColor: textColor,
                        ),
                        const SizedBox(width: 10),
                        _buildGoalCard(
                          title: 'Weekly Goal',
                          current: '${weeklyHrs.toStringAsFixed(1)} / ${goals.weeklyGoalHours.toStringAsFixed(1)} h',
                          progress: weeklyPct,
                          color: AppColors.secondary,
                          isDark: isDark,
                          textColor: textColor,
                        ),
                        const SizedBox(width: 10),
                        _buildGoalCard(
                          title: 'Monthly Goal',
                          current: '${monthlyHrs.toStringAsFixed(1)} / ${goals.monthlyGoalHours.toStringAsFixed(1)} h',
                          progress: monthlyPct,
                          color: AppColors.warning,
                          isDark: isDark,
                          textColor: textColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              },
            ),

            // ── Section 2: Digital Study Timer Container ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF262626) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.white : AppColors.border, width: 3),
                boxShadow: const [
                  BoxShadow(color: AppColors.shadow, offset: Offset(4, 4)),
                ],
              ),
              child: Column(
                children: [
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: timerState.status == TimerStatus.running
                          ? AppColors.secondary
                          : timerState.status == TimerStatus.paused
                              ? AppColors.accent
                              : Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.black, width: 1.5),
                    ),
                    child: Text(
                      timerState.status == TimerStatus.running
                          ? 'FOCUSING NOW'
                          : timerState.status == TimerStatus.paused
                              ? 'TIMER PAUSED'
                              : 'READY TO STUDY',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w900, fontSize: 11, color: Colors.black),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Digital Clock Display
                  FittedBox(
                    child: Text(
                      _formatHHMMSS(timerState.durationSeconds),
                      style: GoogleFonts.poppins(
                        fontSize: 54,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        color: timerState.status == TimerStatus.running ? AppColors.primary : textColor,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Control Buttons Row (Start, Pause, Resume, Stop, Reset)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (timerState.status == TimerStatus.stopped)
                        Expanded(
                          child: AppButton(
                            label: 'Start Study Session',
                            icon: Icons.play_arrow_rounded,
                            onPressed: () {
                              try {
                                timerNotifier.startTimer();
                              } catch (e) {
                                AppSnackbar.showError(context, e.toString().replaceAll('Bad state: ', ''));
                              }
                            },
                          ),
                        )
                      else ...[
                        if (timerState.status == TimerStatus.running)
                          IconButton.filled(
                            style: IconButton.styleFrom(backgroundColor: AppColors.accent, padding: const EdgeInsets.all(16)),
                            icon: const Icon(Icons.pause_rounded, color: Colors.black, size: 28),
                            onPressed: timerNotifier.pauseTimer,
                            tooltip: 'Pause Timer',
                          )
                        else if (timerState.status == TimerStatus.paused)
                          IconButton.filled(
                            style: IconButton.styleFrom(backgroundColor: AppColors.secondary, padding: const EdgeInsets.all(16)),
                            icon: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
                            onPressed: timerNotifier.resumeTimer,
                            tooltip: 'Resume Timer',
                          ),
                        const SizedBox(width: 12),
                        IconButton.filled(
                          style: IconButton.styleFrom(backgroundColor: AppColors.error, padding: const EdgeInsets.all(16)),
                          icon: const Icon(Icons.stop_rounded, color: Colors.white, size: 28),
                          onPressed: () => _confirmStopSession(context, ref),
                          tooltip: 'Stop & Save Session',
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.border, width: 2),
                            padding: const EdgeInsets.all(16),
                          ),
                          onPressed: () => _confirmResetTimer(context, ref),
                          child: const Icon(Icons.refresh_rounded, color: AppColors.error),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Section 3: Session Configuration Panel ──
            if (timerState.status == TimerStatus.stopped) ...[
              Text('Session Setup', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
              const SizedBox(height: 10),

              // Subject Selection Dropdown (Required)
              _isLoadingSubjects
                  ? const LinearProgressIndicator()
                  : DropdownButtonFormField<SubjectModel>(
                      value: timerState.selectedSubject,
                      decoration: InputDecoration(
                        labelText: 'Select Subject *',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(width: 2)),
                        prefixIcon: const Icon(Icons.menu_book_rounded),
                      ),
                      items: _subjects.map((s) {
                        return DropdownMenuItem<SubjectModel>(
                          value: s,
                          child: Text(s.subjectName, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        timerNotifier.selectSubject(val);
                        if (val != null) _loadChapters(val.id);
                      },
                    ),

              const SizedBox(height: 12),

              // Chapter Selection Dropdown (Optional)
              if (timerState.selectedSubject != null) ...[
                _isLoadingChapters
                    ? const LinearProgressIndicator()
                    : DropdownButtonFormField<ChapterModel>(
                        value: timerState.selectedChapter,
                        decoration: InputDecoration(
                          labelText: 'Select Chapter (Optional)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(width: 2)),
                          prefixIcon: const Icon(Icons.bookmark_border_rounded),
                        ),
                        items: _chapters.map((c) {
                          return DropdownMenuItem<ChapterModel>(
                            value: c,
                            child: Text(c.chapterName),
                          );
                        }).toList(),
                        onChanged: timerNotifier.selectChapter,
                      ),
                const SizedBox(height: 12),
              ],

              // Study Type Chips Selection
              Text('Study Type', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13, color: textColor)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: _studyTypes.map((type) {
                  final isSelected = timerState.sessionType == type;
                  return ChoiceChip(
                    label: Text(type, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12, color: isSelected ? Colors.white : textColor)),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    onSelected: (_) => timerNotifier.setSessionType(type),
                  );
                }).toList(),
              ),

              const SizedBox(height: 12),

              // Notes Input Field
              TextField(
                controller: _notesController,
                onChanged: timerNotifier.setSessionNotes,
                decoration: InputDecoration(
                  labelText: 'Session Notes (Optional)',
                  hintText: 'e.g. Practiced 25 PYQs on Integration',
                  prefixIcon: const Icon(Icons.edit_note_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(width: 2)),
                ),
              ),

              const SizedBox(height: 20),
            ] else ...[
              // Live Active Session Summary Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary, width: 2.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Active Session Details', style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.primary)),
                    const SizedBox(height: 8),
                    _buildDetailRow('Subject', timerState.selectedSubject?.subjectName ?? 'Not selected', isDark, textColor),
                    if (timerState.selectedChapter != null)
                      _buildDetailRow('Chapter', timerState.selectedChapter!.chapterName, isDark, textColor),
                    _buildDetailRow('Study Mode', timerState.sessionType, isDark, textColor),
                    if (timerState.sessionNotes.isNotEmpty)
                      _buildDetailRow('Notes', timerState.sessionNotes, isDark, textColor),
                  ],
                ),
              ),

              const SizedBox(height: 20),
            ],

            // ── Section 4: Today's Summary Overview ──
            Text('Today\'s Overview', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
            const SizedBox(height: 10),

            asyncTodaySessions.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Text('Error loading today summary: $err'),
              data: (todaySessions) {
                final todayMinutes = asyncStats.asData?.value.todayMinutes ?? 0;
                final dailyGoalMins = asyncGoals.asData?.value.dailyGoalMinutes ?? 360;
                final remainingMins = (dailyGoalMins - todayMinutes).clamp(0, 10000);

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF262626) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? Colors.white : AppColors.border, width: 2.5),
                    boxShadow: const [BoxShadow(color: AppColors.shadow, offset: Offset(3, 3))],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSummaryStat('Today Time', '${(todayMinutes / 60.0).toStringAsFixed(1)} hrs', isDark, textColor),
                      _buildSummaryStat('Remaining', '${(remainingMins / 60.0).toStringAsFixed(1)} hrs', isDark, textColor),
                      _buildSummaryStat('Completed', '${todaySessions.length} Logs', isDark, textColor),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalCard({
    required String title,
    required String current,
    required double progress,
    required Color color,
    required bool isDark,
    required Color textColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF262626) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? Colors.white : AppColors.border, width: 2.5),
          boxShadow: const [BoxShadow(color: AppColors.shadow, offset: Offset(2, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : AppColors.textSecondary)),
            const SizedBox(height: 4),
            Text(current, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w900, color: color)),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: color.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDark, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 12, color: isDark ? Colors.white60 : AppColors.textSecondary)),
          Text(value, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: textColor)),
        ],
      ),
    );
  }

  Widget _buildSummaryStat(String label, String value, bool isDark, Color textColor) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.primary)),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: isDark ? Colors.white60 : AppColors.textSecondary)),
      ],
    );
  }

  void _confirmStopSession(BuildContext context, WidgetRef ref) {
    final timerNotifier = ref.read(studyTimerProvider.notifier);

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Finish & Save Study Log?', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to stop this study session and log your focus time?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
            onPressed: () async {
              Navigator.pop(ctx);
              final session = timerNotifier.stopSession();
              if (session != null) {
                final repo = ref.read(studySessionRepositoryProvider);
                await repo.logSession(session);
                refreshDashboardAndStats(ref);
                if (context.mounted) AppSnackbar.showSuccess(context, 'Study session logged successfully!');
              }
            },
            child: const Text('Save Session', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmResetTimer(BuildContext context, WidgetRef ref) {
    final timerNotifier = ref.read(studyTimerProvider.notifier);

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Reset Timer?', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: const Text('Resetting will discard the current running timer without saving. Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(ctx);
              timerNotifier.resetTimer();
              AppSnackbar.showInfo(context, 'Timer reset.');
            },
            child: const Text('Reset', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
