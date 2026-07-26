import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:prep_tracker/core/constants/app_colors.dart';
import 'package:prep_tracker/core/theme/theme_provider.dart';
import 'package:prep_tracker/features/auth/presentation/providers/auth_provider.dart';
import 'package:prep_tracker/features/settings/presentation/providers/settings_provider.dart';
import 'package:prep_tracker/features/profile/presentation/providers/profile_provider.dart';
import 'package:prep_tracker/features/settings/data/models/settings_model.dart';
import 'package:prep_tracker/features/home/data/models/daily_goal_model.dart';
import 'package:prep_tracker/features/gym/presentation/providers/gym_provider.dart';
import 'package:prep_tracker/features/syllabus/data/models/subject_model.dart';
import 'package:prep_tracker/features/syllabus/data/models/chapter_model.dart';
import 'package:prep_tracker/features/study/data/models/study_session_model.dart';
import 'package:prep_tracker/features/study/data/models/study_goal_model.dart';
import 'package:prep_tracker/features/study/presentation/providers/study_goal_provider.dart';
import 'package:prep_tracker/features/bookmark/data/models/bookmark_model.dart';
import 'package:prep_tracker/features/gym/data/models/gym_attendance_model.dart';
import 'package:prep_tracker/core/services/backup_service.dart';
import 'package:prep_tracker/core/services/export_service.dart';
import 'package:prep_tracker/core/services/notification_service.dart';
import 'package:prep_tracker/core/services/supabase_service.dart';
import 'package:prep_tracker/shared/widgets/app_button.dart';
import 'package:prep_tracker/shared/widgets/app_snackbar.dart';

BoxDecoration _brutalDecoration(BuildContext context, Color lightBgColor, {Color? darkBgColor}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final surface = isDark ? (darkBgColor ?? const Color(0xFF262626)) : lightBgColor;
  final borderColor = isDark ? Colors.white : AppColors.border;
  final shadowColor = isDark ? Colors.black.withValues(alpha: 0.5) : AppColors.shadow;

  return BoxDecoration(
    color: surface,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: borderColor, width: 3),
    boxShadow: [
      BoxShadow(
        color: shadowColor,
        offset: const Offset(4, 4),
      ),
    ],
  );
}

Widget _iconBadge(BuildContext context, IconData icon, Color color) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return Container(
    width: 32,
    height: 32,
    decoration: BoxDecoration(
      color: isDark ? const Color(0xFF333333) : Colors.white,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: isDark ? Colors.white70 : AppColors.border, width: 2),
    ),
    child: Icon(icon, color: color, size: 18),
  );
}

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _studyAlert = true;
  bool _revisionAlert = true;
  bool _gymAlert = true;
  bool _examAlert = true;
  bool _summaryAlert = true;
  String _alertTime = '09:00';

  String _selectedPreviewTheme = 'system';

  @override
  void initState() {
    super.initState();
    _selectedPreviewTheme = ref.read(settingsControllerProvider).themeMode;
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsControllerProvider);
    final dailyGoal = ref.watch(dailyGoalControllerProvider);
    final authState = ref.watch(authProvider);

    final userId = authState.profile?.userId ?? authState.supabaseUser?.id ?? '';
    final currentThemeMode = settings.themeMode;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.text;
    final secondaryTextColor = isDark ? Colors.grey.shade400 : AppColors.textSecondary;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Settings',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: textColor,
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── SECTION 1: Theme & Appearance ──
                _sectionHeader('Appearance & Theme', secondaryTextColor),
                Container(
                  decoration: _brutalDecoration(context, Colors.white),
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Theme Settings',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _themePickerOption(
                              label: 'Light Mode',
                              mode: 'light',
                              icon: Icons.light_mode_rounded,
                              color: const Color(0xFFFFD93D),
                              textColor: textColor,
                              context: context,
                              currentMode: currentThemeMode,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _themePickerOption(
                              label: 'Dark Mode',
                              mode: 'dark',
                              icon: Icons.dark_mode_rounded,
                              color: const Color(0xFF5B5FEF),
                              textColor: textColor,
                              context: context,
                              currentMode: currentThemeMode,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _themePickerOption(
                              label: 'System Default',
                              mode: 'system',
                              icon: Icons.settings_brightness_rounded,
                              color: const Color(0xFF34D399),
                              textColor: textColor,
                              context: context,
                              currentMode: currentThemeMode,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // ── SECTION 3: Gym Goals ──
                _sectionHeader('Gym Goals', secondaryTextColor),
                Container(
                  decoration: _brutalDecoration(context, Colors.white),
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      _numberGoalInput(
                        label: 'Weekly Gym Target (Days)',
                        value: ref.read(dailyGoalControllerProvider.notifier).weeklyGymGoalDays,
                        icon: Icons.fitness_center_rounded,
                        min: 1,
                        max: 7,
                        step: 1,
                        textColor: textColor,
                        onChanged: (val) => _updateLongTermGoals(weeklyGym: val.toInt()),
                      ),
                      Divider(height: 24, color: isDark ? Colors.white24 : AppColors.border),
                      _numberGoalInput(
                        label: 'Monthly Gym Target (Days)',
                        value: ref.read(dailyGoalControllerProvider.notifier).monthlyGymGoalDays,
                        icon: Icons.event_available_rounded,
                        min: 4,
                        max: 31,
                        step: 1,
                        textColor: textColor,
                        onChanged: (val) => _updateLongTermGoals(monthlyGym: val.toInt()),
                      ),
                      Divider(height: 20, color: isDark ? Colors.white24 : AppColors.border),
                      SwitchListTile(
                        title: Text(
                          'Workout reminder',
                          style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: textColor),
                        ),
                        value: ref.read(dailyGoalControllerProvider.notifier).workoutReminderEnabled,
                        activeThumbColor: AppColors.primary,
                        onChanged: (val) => _updateLongTermGoals(gymReminder: val),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // ── SECTION 4: Reminders & Notifications ──
                _sectionHeader('Notifications & Alerts', secondaryTextColor),
                Container(
                  decoration: _brutalDecoration(context, Colors.white),
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _alertCheckbox('Study Reminder', _studyAlert, textColor, (v) {
                        setState(() => _studyAlert = v!);
                        NotificationService.scheduleStudyReminder(time: _alertTime, enabled: _studyAlert);
                      }),
                      _alertCheckbox('Revision Reminder', _revisionAlert, textColor, (v) {
                        setState(() => _revisionAlert = v!);
                        NotificationService.scheduleRevisionReminder(enabled: _revisionAlert);
                      }),
                      _alertCheckbox('Gym Reminder', _gymAlert, textColor, (v) {
                        setState(() => _gymAlert = v!);
                        NotificationService.scheduleGymReminder(time: _alertTime, enabled: _gymAlert);
                      }),
                      _alertCheckbox('Exam Reminder', _examAlert, textColor, (v) {
                        setState(() => _examAlert = v!);
                        NotificationService.scheduleExamReminder(enabled: _examAlert);
                      }),
                      _alertCheckbox('Daily Summary Alert', _summaryAlert, textColor, (v) {
                        setState(() => _summaryAlert = v!);
                        NotificationService.scheduleDailySummary(enabled: _summaryAlert);
                      }),
                      Divider(height: 24, color: isDark ? Colors.white24 : AppColors.border),
                      SizedBox(
                        width: double.infinity,
                        child: AppButton(
                          label: 'Manage Scheduled Reminders',
                          icon: Icons.alarm_rounded,
                          size: AppButtonSize.sm,
                          onPressed: () => context.push('/reminders'),
                          variant: AppButtonVariant.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // ── SECTION 5: Data Management ──
                _sectionHeader('Data Management', secondaryTextColor),
                Container(
                  decoration: _brutalDecoration(context, Colors.white),
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: AppButton(
                              label: 'Backup',
                              icon: Icons.backup_rounded,
                              size: AppButtonSize.sm,
                              onPressed: () async {
                                try {
                                  await BackupService.backupSettings(userId, ref);
                                  if (mounted) {
                                    AppSnackbar.showSuccess(context, 'Settings backed up successfully!');
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    AppSnackbar.showError(context, 'Backup failed: $e');
                                  }
                                }
                              },
                              variant: AppButtonVariant.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: AppButton(
                              label: 'Restore',
                              icon: Icons.restore_rounded,
                              size: AppButtonSize.sm,
                              onPressed: () async {
                                try {
                                  await BackupService.restoreSettings(userId, ref);
                                  if (mounted) {
                                    AppSnackbar.showSuccess(context, 'Settings restored successfully!');
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    AppSnackbar.showError(context, 'Restore failed: $e');
                                  }
                                }
                              },
                              variant: AppButtonVariant.secondary,
                            ),
                          ),
                        ],
                      ),
                      Divider(height: 24, color: isDark ? Colors.white24 : AppColors.border),
                      Row(
                        children: [
                          Expanded(
                            child: AppButton(
                              label: 'Export JSON',
                              size: AppButtonSize.sm,
                              onPressed: () => _exportUserData(userId, 'json'),
                              variant: AppButtonVariant.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: AppButton(
                              label: 'Export CSV',
                              size: AppButtonSize.sm,
                              onPressed: () => _exportUserData(userId, 'csv'),
                              variant: AppButtonVariant.secondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: AppButton(
                          label: 'Export PDF Report',
                          size: AppButtonSize.sm,
                          onPressed: () => _exportUserData(userId, 'pdf'),
                          variant: AppButtonVariant.success,
                        ),
                      ),
                      Divider(height: 24, color: isDark ? Colors.white24 : AppColors.border),
                      SizedBox(
                        width: double.infinity,
                        child: AppButton(
                          label: 'Import JSON Backup',
                          size: AppButtonSize.sm,
                          onPressed: () => _importBackupData(userId),
                          variant: AppButtonVariant.outline,
                        ),
                      ),
                      Divider(height: 24, color: isDark ? Colors.white24 : AppColors.border),
                      Row(
                        children: [
                          Expanded(
                            child: AppButton(
                              label: 'Reset',
                              icon: Icons.restart_alt_rounded,
                              size: AppButtonSize.sm,
                              onPressed: () => _confirmResetSettings(userId),
                              variant: AppButtonVariant.danger,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: AppButton(
                              label: 'Clear Cache',
                              icon: Icons.cleaning_services_rounded,
                              size: AppButtonSize.sm,
                              onPressed: () async {
                                if (mounted) {
                                  AppSnackbar.showSuccess(context, 'Local cache cleared!');
                                }
                              },
                              variant: AppButtonVariant.outline,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // ── SECTION 6: Account Actions ──
                _sectionHeader('Account', secondaryTextColor),
                Container(
                  decoration: _brutalDecoration(context, Colors.white),
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: AppButton(
                          label: 'Sign Out',
                          onPressed: () => _confirmSignOut(),
                          variant: AppButtonVariant.outline,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: AppButton(
                          label: 'Delete Account',
                          onPressed: () => _confirmDeleteAccount(userId),
                          variant: AppButtonVariant.danger,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── SECTION 7: About ──
                _sectionHeader('About', secondaryTextColor),
                Container(
                  decoration: _brutalDecoration(context, const Color(0xFFA5F3FC), darkBgColor: const Color(0xFF164E63)),
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PrepTracker By Yash',
                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w900, color: textColor),
                      ),
                      Text('Version 1.0.0 (Build 1)', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: textColor)),
                      const SizedBox(height: 8),
                      Text(
                        'All-in-one personal productivity application designed for syllabus tracking and habit cultivation.',
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: textColor),
                      ),
                      Divider(height: 20, color: isDark ? Colors.white24 : AppColors.border),
                      Wrap(
                        spacing: 12,
                        runSpacing: 4,
                        children: [
                          Text('Privacy Policy', style: GoogleFonts.inter(fontSize: 10, decoration: TextDecoration.underline, fontWeight: FontWeight.bold, color: textColor)),
                          Text('Terms & Conditions', style: GoogleFonts.inter(fontSize: 10, decoration: TextDecoration.underline, fontWeight: FontWeight.bold, color: textColor)),
                          Text('Licenses', style: GoogleFonts.inter(fontSize: 10, decoration: TextDecoration.underline, fontWeight: FontWeight.bold, color: textColor)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 12),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.0,
          color: color,
        ),
      ),
    );
  }

  Widget _themePickerOption({
    required String label,
    required String mode,
    required IconData icon,
    required Color color,
    required Color textColor,
    required BuildContext context,
    required String currentMode,
  }) {
    final isSelected = currentMode == mode;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () async {
        ThemeMode themeMode;
        if (mode == 'light') {
          themeMode = ThemeMode.light;
        } else if (mode == 'dark') {
          themeMode = ThemeMode.dark;
        } else {
          themeMode = ThemeMode.system;
        }
        await ref.read(themeModeProvider.notifier).setThemeMode(themeMode);
        await ref.read(settingsControllerProvider.notifier).updateThemeMode(mode);
        if (context.mounted) {
          AppSnackbar.showSuccess(context, 'Theme switched to $label!');
        }
      },
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: color.withValues(alpha: isSelected ? 0.35 : 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? (isDark ? Colors.white : AppColors.border) : Colors.grey.shade400,
            width: isSelected ? 3.0 : 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w900, color: textColor),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _numberGoalInput({
    required String label,
    required int value,
    required IconData icon,
    required double min,
    required double max,
    required double step,
    required Color textColor,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _iconBadge(context, icon, AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w900, color: textColor),
              ),
            ),
            Text(
              '$value',
              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w900, color: textColor),
            ),
          ],
        ),
        Slider(
          value: value.toDouble().clamp(min, max),
          min: min,
          max: max,
          divisions: ((max - min) / step).round(),
          activeColor: AppColors.primary,
          inactiveColor: Colors.grey.shade400,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _doubleGoalInput({
    required String label,
    required double value,
    required IconData icon,
    required double min,
    required double max,
    required Color textColor,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _iconBadge(context, icon, AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w900, color: textColor),
              ),
            ),
            Text(
              value.toStringAsFixed(1),
              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w900, color: textColor),
            ),
          ],
        ),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          divisions: (max - min).round(),
          activeColor: AppColors.primary,
          inactiveColor: Colors.grey.shade400,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _alertCheckbox(String label, bool value, Color textColor, ValueChanged<bool?> onChanged) {
    return CheckboxListTile(
      title: Text(
        label,
        style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: textColor),
      ),
      value: value,
      activeColor: AppColors.primary,
      onChanged: onChanged,
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
    );
  }

  void _updateLongTermGoals({
    double? weeklyStudy,
    double? monthlyStudy,
    int? weeklyGym,
    int? monthlyGym,
    bool? gymReminder,
  }) {
    final notifier = ref.read(dailyGoalControllerProvider.notifier);
    notifier.updateLongTermGoals(
      weeklyStudyGoal: weeklyStudy ?? notifier.weeklyStudyGoalHours,
      monthlyStudyGoal: monthlyStudy ?? notifier.monthlyStudyGoalHours,
      weeklyGymGoal: weeklyGym ?? notifier.weeklyGymGoalDays,
      monthlyGymGoal: monthlyGym ?? notifier.monthlyGymGoalDays,
      workoutReminder: gymReminder ?? notifier.workoutReminderEnabled,
    );
  }

  Future<void> _exportUserData(String userId, String format) async {
    try {
      final supabase = SupabaseService.client;
      final results = await Future.wait([
        supabase.from('subjects').select().eq('user_id', userId),
        supabase.from('chapters').select().eq('user_id', userId),
        supabase.from('study_sessions').select().eq('user_id', userId),
        supabase.from('bookmarks').select().eq('user_id', userId),
        supabase.from('gym_attendance').select().eq('user_id', userId),
      ]);

      final subjectsList = (results[0] as List).map((e) => SubjectModel.fromJson(e as Map<String, dynamic>)).toList();
      final chaptersList = (results[1] as List).map((e) => ChapterModel.fromJson(e as Map<String, dynamic>)).toList();
      final sessionsList = (results[2] as List).map((e) => StudySessionModel.fromJson(e as Map<String, dynamic>)).toList();
      final bookmarksList = (results[3] as List).map((e) => BookmarkModel.fromJson(e as Map<String, dynamic>)).toList();
      final gymList = (results[4] as List).map((e) => GymAttendanceModel.fromJson(e as Map<String, dynamic>)).toList();

      final settings = ref.read(settingsControllerProvider);
      final dailyGoal = ref.read(dailyGoalControllerProvider);
      final profileStats = ref.read(profileStatsProvider).value ?? ProfileDashboardStats.empty();
      final authState = ref.read(authProvider);

      if (format == 'json') {
        final backupStr = ExportService.generateJsonBackup(
          subjects: subjectsList,
          chapters: chaptersList,
          sessions: sessionsList,
          bookmarks: bookmarksList,
          gymLogs: gymList,
          settings: settings,
          dailyGoal: dailyGoal,
        );
        final bytes = utf8.encode(backupStr);
        await ExportService.downloadFile(bytes, 'preptracker_backup.json', 'application/json');
        if (mounted) {
          AppSnackbar.showSuccess(context, 'JSON Backup downloaded successfully!');
        }
      } else if (format == 'csv') {
        final csvs = ExportService.generateCsvBackups(
          subjects: subjectsList,
          chapters: chaptersList,
          sessions: sessionsList,
          bookmarks: bookmarksList,
          gymLogs: gymList,
        );
        final combined = csvs.entries.map((e) => '=== ${e.key.toUpperCase()} ===\n${e.value}').join('\n\n');
        final bytes = utf8.encode(combined);
        await ExportService.downloadFile(bytes, 'preptracker_csv_export.csv', 'text/csv');
        if (mounted) {
          AppSnackbar.showSuccess(context, 'CSV Export downloaded successfully!');
        }
      } else if (format == 'pdf') {
        final bytes = await ExportService.generatePdfReport(
          userName: authState.profile?.name ?? 'Yash',
          userEmail: authState.profile?.email ?? 'yash@example.com',
          studyStreak: profileStats.totalStudySessions,
          gymStreak: ref.read(gymStatsProvider).value?.currentStreak ?? 0,
          totalStudyHours: profileStats.totalStudyHours,
          totalStudySessions: profileStats.totalStudySessions,
          subjectsCreated: profileStats.subjectsCreated,
          completedChapters: profileStats.completedChapters,
          pendingChapters: profileStats.pendingChapters,
          revisionProgress: profileStats.revisionProgress,
          gymAttendancePercentage: profileStats.gymAttendancePercentage,
          currentMonthStudyHours: profileStats.currentMonthStudyHours,
          subjects: subjectsList,
          bookmarks: bookmarksList,
        );
        await ExportService.downloadFile(bytes, 'preptracker_summary_report.pdf', 'application/pdf');
        if (mounted) {
          AppSnackbar.showSuccess(context, 'PDF Report downloaded successfully!');
        }
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(context, 'Export failed: $e');
      }
    }
  }

  Future<void> _importBackupData(String userId) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.bytes != null) {
        final content = utf8.decode(result.files.single.bytes!);
        await BackupService.importUserData(userId: userId, jsonString: content, ref: ref);
        if (mounted) {
          AppSnackbar.showSuccess(context, 'JSON Backup imported successfully!');
        }
      } else if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final content = await file.readAsString();
        await BackupService.importUserData(userId: userId, jsonString: content, ref: ref);
        if (mounted) {
          AppSnackbar.showSuccess(context, 'JSON Backup imported successfully!');
        }
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(context, 'Import failed: $e');
      }
    }
  }

  Future<void> _confirmResetSettings(String userId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Reset Settings', style: GoogleFonts.poppins(fontWeight: FontWeight.w900)),
        content: const Text('Are you sure you want to reset all goals and configuration settings to their default values?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Reset', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      final defaultSettings = UserSettingsModel(
        id: ref.read(settingsControllerProvider).id,
        userId: userId,
      );
      final defaultGoal = DailyGoalModel(
        id: ref.read(dailyGoalControllerProvider).id,
        userId: userId,
      );

      await ref.read(settingsControllerProvider.notifier).resetSettings(defaultSettings);
      await ref.read(dailyGoalControllerProvider.notifier).resetGoals(defaultGoal);

      if (mounted) {
        AppSnackbar.showSuccess(context, 'Settings reset to default!');
      }
    }
  }

  Future<void> _confirmSignOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Sign Out', style: GoogleFonts.poppins(fontWeight: FontWeight.w900)),
        content: const Text('Are you sure you want to log out of your account?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(authProvider.notifier).logout();
      if (mounted) {
        context.go('/login');
      }
    }
  }

  Future<void> _confirmDeleteAccount(String userId) async {
    final reauth = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Re-authenticate Deletion', style: GoogleFonts.poppins(fontWeight: FontWeight.w900)),
        content: const Text('For security purposes, you must confirm that you wish to permanently delete your account. This will completely wipe all subjects, syllabus progress, timer records, and gym logs.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete Permanently', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (reauth == true) {
      try {
        final supabase = SupabaseService.client;
        await supabase.from('profiles').delete().eq('user_id', userId);
        await ref.read(authProvider.notifier).logout();
        if (mounted) {
          context.go('/login');
          AppSnackbar.showSuccess(context, 'Account deleted successfully.');
        }
      } catch (e) {
        if (mounted) {
          AppSnackbar.showError(context, 'Deletion failed: $e');
        }
      }
    }
  }
}
