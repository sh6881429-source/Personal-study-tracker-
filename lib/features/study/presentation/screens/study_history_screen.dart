import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:prep_tracker/core/constants/app_colors.dart';
import 'package:prep_tracker/features/study/data/models/study_session_model.dart';
import 'package:prep_tracker/features/study/presentation/providers/study_history_provider.dart';
import 'package:prep_tracker/features/study/presentation/providers/study_timer_provider.dart';
import 'package:prep_tracker/features/syllabus/data/repositories/subject_repository_impl.dart';
import 'package:prep_tracker/features/syllabus/data/models/subject_model.dart';
import 'package:prep_tracker/features/auth/presentation/providers/auth_provider.dart';
import 'package:prep_tracker/shared/widgets/app_empty_state.dart';
import 'package:prep_tracker/shared/widgets/app_snackbar.dart';

class StudyHistoryScreen extends ConsumerStatefulWidget {
  const StudyHistoryScreen({super.key});

  @override
  ConsumerState<StudyHistoryScreen> createState() => _StudyHistoryScreenState();
}

class _StudyHistoryScreenState extends ConsumerState<StudyHistoryScreen> {
  List<SubjectModel> _subjects = [];

  @override
  void initState() {
    super.initState();
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
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.text;
    final filter = ref.watch(studyHistoryFilterProvider);
    final filterNotifier = ref.read(studyHistoryFilterProvider.notifier);
    final filteredSessions = ref.watch(filteredSessionsProvider);
    final asyncAllSessions = ref.watch(allSessionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Study Session History', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(allSessionsProvider),
            tooltip: 'Refresh History',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF222222) : Colors.white,
              border: Border(bottom: BorderSide(color: isDark ? Colors.white24 : AppColors.border, width: 2)),
            ),
            child: Column(
              children: [
                // Search Field
                TextField(
                  onChanged: filterNotifier.setSearchQuery,
                  decoration: InputDecoration(
                    hintText: 'Search by notes or type...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: filter.searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () => filterNotifier.setSearchQuery(''),
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(width: 2)),
                  ),
                ),

                const SizedBox(height: 12),

                // Filter Chips Row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Subject Filter Dropdown Chip
                      _buildDropdownChip<String?>(
                        label: filter.selectedSubjectId == null
                            ? 'All Subjects'
                            : _subjects.firstWhere((s) => s.id == filter.selectedSubjectId, orElse: () => SubjectModel(id: '', userId: '', subjectName: 'Subject', color: '5B5FEF', icon: 'book')).subjectName,
                        value: filter.selectedSubjectId,
                        items: [
                          const DropdownMenuItem<String?>(value: null, child: Text('All Subjects')),
                          ..._subjects.map((s) => DropdownMenuItem<String?>(value: s.id, child: Text(s.subjectName))),
                        ],
                        onChanged: filterNotifier.setSubjectId,
                        isDark: isDark,
                      ),

                      const SizedBox(width: 8),

                      // Study Type Chip
                      _buildDropdownChip<String?>(
                        label: filter.selectedSessionType ?? 'All Modes',
                        value: filter.selectedSessionType,
                        items: const [
                          DropdownMenuItem<String?>(value: null, child: Text('All Modes')),
                          DropdownMenuItem<String?>(value: 'Self Study', child: Text('Self Study')),
                          DropdownMenuItem<String?>(value: 'Revision', child: Text('Revision')),
                          DropdownMenuItem<String?>(value: 'Practice', child: Text('Practice')),
                          DropdownMenuItem<String?>(value: 'Mock Test', child: Text('Mock Test')),
                        ],
                        onChanged: filterNotifier.setSessionType,
                        isDark: isDark,
                      ),

                      const SizedBox(width: 8),

                      // Reset Filters Button
                      if (filter.selectedSubjectId != null || filter.selectedSessionType != null || filter.searchQuery.isNotEmpty)
                        ActionChip(
                          avatar: const Icon(Icons.close_rounded, size: 16, color: Colors.white),
                          label: const Text('Clear Filters', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                          backgroundColor: AppColors.error,
                          onPressed: filterNotifier.resetFilters,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Session Count Summary Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${filteredSessions.length} Sessions Found',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13, color: textColor),
                ),
                Text(
                  'Total: ${(filteredSessions.fold<int>(0, (sum, s) => sum + s.durationMinutes) / 60.0).toStringAsFixed(1)} hrs',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Sessions List
          Expanded(
            child: asyncAllSessions.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error loading history: $err')),
              data: (_) {
                if (filteredSessions.isEmpty) {
                  return const AppEmptyState(
                    icon: Icons.history_toggle_off_rounded,
                    title: 'No Sessions Found',
                    message: 'No study logs match your selected search or filter criteria.',
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredSessions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (ctx, idx) {
                    final session = filteredSessions[idx];
                    final subjectName = _subjects.firstWhere(
                      (s) => s.id == session.subjectId,
                      orElse: () => SubjectModel(id: session.subjectId, userId: '', subjectName: 'Study Session', color: '5B5FEF', icon: 'book'),
                    ).subjectName;

                    return _buildSessionCard(
                      context: context,
                      ref: ref,
                      session: session,
                      subjectName: subjectName,
                      isDark: isDark,
                      textColor: textColor,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownChip<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF333333) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white30 : AppColors.border, width: 1.5),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold)),
          items: items,
          onChanged: onChanged,
          isDense: true,
          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.text),
        ),
      ),
    );
  }

  Widget _buildSessionCard({
    required BuildContext context,
    required WidgetRef ref,
    required StudySessionModel session,
    required String subjectName,
    required bool isDark,
    required Color textColor,
  }) {
    final dateStr = DateFormat('EEE, MMM dd, yyyy').format(session.studyDate);
    final startTimeStr = DateFormat('hh:mm a').format(session.startTime);
    final endTimeStr = DateFormat('hh:mm a').format(session.endTime);

    Color badgeColor = AppColors.primary;
    if (session.sessionType == 'Revision') badgeColor = AppColors.secondary;
    if (session.sessionType == 'Practice') badgeColor = AppColors.warning;
    if (session.sessionType == 'Mock Test') badgeColor = AppColors.error;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF262626) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? Colors.white : AppColors.border, width: 2.5),
        boxShadow: const [
          BoxShadow(color: AppColors.shadow, offset: Offset(2.5, 2.5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.black, width: 1.5),
                    ),
                    child: Text(
                      session.sessionType,
                      style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    dateStr,
                    style: GoogleFonts.inter(fontSize: 11, color: isDark ? Colors.white60 : AppColors.textSecondary),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                onPressed: () => _confirmDeleteSession(context, ref, session.id),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Delete Session',
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            subjectName,
            style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 15, color: textColor),
          ),

          const SizedBox(height: 6),

          Row(
            children: [
              const Icon(Icons.timer_outlined, size: 14, color: AppColors.primary),
              const SizedBox(width: 4),
              Text(
                '${session.durationMinutes} Minutes',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.schedule_rounded, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                '$startTimeStr - $endTimeStr',
                style: GoogleFonts.inter(fontSize: 12, color: isDark ? Colors.white70 : AppColors.textSecondary),
              ),
            ],
          ),

          if (session.sessionNotes != null && session.sessionNotes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '📝 ${session.sessionNotes}',
                style: GoogleFonts.inter(fontSize: 12, fontStyle: FontStyle.italic, color: textColor),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _confirmDeleteSession(BuildContext context, WidgetRef ref, String sessionId) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Study Log?', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to delete this study session? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(ctx);
              await deleteStudySession(ref, sessionId);
              if (context.mounted) {
                AppSnackbar.showSuccess(context, 'Study session deleted!');
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
