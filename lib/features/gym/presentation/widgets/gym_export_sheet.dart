import 'dart:io' show File;
import 'dart:convert' show base64Encode;
import 'dart:js' as js;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart' show getTemporaryDirectory;
import 'package:prep_tracker/core/constants/app_colors.dart';
import 'package:prep_tracker/core/constants/app_text_styles.dart';
import 'package:prep_tracker/features/auth/presentation/providers/auth_provider.dart';
import 'package:prep_tracker/features/gym/data/services/gym_report_service.dart';
import 'package:prep_tracker/features/gym/data/repositories/gym_attendance_repository_impl.dart';
import 'package:prep_tracker/features/gym/presentation/providers/gym_provider.dart';
import 'package:prep_tracker/shared/widgets/app_button.dart';

class GymExportSheet extends ConsumerStatefulWidget {
  const GymExportSheet({super.key});

  @override
  ConsumerState<GymExportSheet> createState() => _GymExportSheetState();
}

class _GymExportSheetState extends ConsumerState<GymExportSheet> {
  String _rangeOption = 'current_month'; // 'current_month', 'previous_month', 'custom'
  DateTime? _customStart;
  DateTime? _customEnd;
  bool _isGenerating = false;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final dateFormat = DateFormat('yyyy-MM-dd');

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFAF6E8),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(color: AppColors.border, width: 4),
            left: BorderSide(color: AppColors.border, width: 4),
            right: BorderSide(color: AppColors.border, width: 4),
          ),
        ),
        padding: EdgeInsets.fromLTRB(20, 20, 20, bottomPadding > 0 ? bottomPadding : 16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Export PDF Report',
                    style: AppTextStyles.headingMD(color: AppColors.border),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.border, size: 24),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Text(
                'Generate a professional PDF summary of your gym attendance history.',
                style: AppTextStyles.bodySM(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 16),

              // Report Range Radio List
              _buildRangeRadioTile(
                label: 'Current Month',
                value: 'current_month',
                subtitle: DateFormat('MMMM yyyy').format(DateTime.now()),
              ),
              _buildRangeRadioTile(
                label: 'Previous Month',
                value: 'previous_month',
                subtitle: DateFormat('MMMM yyyy').format(
                  DateTime(DateTime.now().year, DateTime.now().month - 1),
                ),
              ),
              _buildRangeRadioTile(
                label: 'Custom Range',
                value: 'custom',
                subtitle: 'Select start and end dates',
              ),

              if (_rangeOption == 'custom') ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _pickDate(isStart: true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: AppColors.border, width: 2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _customStart != null ? dateFormat.format(_customStart!) : 'Start Date',
                            style: AppTextStyles.labelSM(color: AppColors.border),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: () => _pickDate(isStart: false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: AppColors.border, width: 2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _customEnd != null ? dateFormat.format(_customEnd!) : 'End Date',
                            style: AppTextStyles.labelSM(color: AppColors.border),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 24),

              // Export Button
              AppButton(
                label: _isGenerating ? 'Generating PDF...' : 'Generate and Share PDF',
                variant: AppButtonVariant.primary,
                isLoading: _isGenerating,
                onPressed: _isGenerating ? null : _generateAndSharePDF,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRangeRadioTile({
    required String label,
    required String value,
    required String subtitle,
  }) {
    final isSelected = _rangeOption == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _rangeOption = value;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFD60A).withValues(alpha: 0.2) : Colors.white,
          border: Border.all(
            color: isSelected ? AppColors.border : Colors.grey.shade300,
            width: isSelected ? 3 : 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Radio<String>(
              value: value,
              groupValue: _rangeOption,
              activeColor: AppColors.border,
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _rangeOption = val;
                  });
                }
              },
            ),
            const SizedBox(width: 4),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.labelMD(color: AppColors.border).copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTextStyles.bodySM(color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.border,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: AppColors.border),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _customStart = picked;
        } else {
          _customEnd = picked;
        }
      });
    }
  }

  Future<void> _generateAndSharePDF() async {
    final auth = ref.read(authProvider);
    final userName = auth.profile?.name ?? auth.supabaseUser?.email?.split('@').first ?? 'Yash';
    final userId = auth.profile?.userId ?? auth.supabaseUser?.id ?? '';
    if (userId.isEmpty) return;

    DateTime start;
    DateTime end;

    final now = DateTime.now();
    if (_rangeOption == 'current_month') {
      start = DateTime(now.year, now.month, 1);
      end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    } else if (_rangeOption == 'previous_month') {
      start = DateTime(now.year, now.month - 1, 1);
      end = DateTime(now.year, now.month, 0, 23, 59, 59);
    } else {
      if (_customStart == null || _customEnd == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please specify a valid start and end date.')),
        );
        return;
      }
      start = _customStart!;
      end = _customEnd!.add(const Duration(hours: 23, minutes: 59, seconds: 59));
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      final repository = ref.read(gymAttendanceRepositoryProvider);
      
      // Fetch all attendance logs
      final allLogs = await repository.getAllAttendance(userId);
      final rangeLogs = allLogs.where((log) =>
          log.attendanceDate.isAfter(start.subtract(const Duration(seconds: 1))) &&
          log.attendanceDate.isBefore(end.add(const Duration(seconds: 1)))).toList();

      if (rangeLogs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No attendance logs found in this date range.')),
          );
        }
        return;
      }

      // Fetch computed statistics for the report header/overview
      final stats = await ref.read(gymStatsProvider.future);

      final pdfBytes = await GymReportService.generateReport(
        userName: userName,
        start: start,
        end: end,
        logs: rangeLogs,
        currentStreak: stats.currentStreak,
        longestStreak: stats.longestStreak,
        attendancePercentage: stats.monthlyAttendancePercentage,
      );

      if (kIsWeb) {
        final base64Pdf = base64Encode(pdfBytes);
        js.context.callMethod('eval', [
          '''
          var link = document.createElement('a');
          link.href = 'data:application/pdf;base64,$base64Pdf';
          link.download = 'gym_attendance_report.pdf';
          document.body.appendChild(link);
          link.click();
          document.body.removeChild(link);
          '''
        ]);
      } else {
        final output = await getTemporaryDirectory();
        final file = File("${output.path}/gym_report_${DateTime.now().millisecondsSinceEpoch}.pdf");
        await file.writeAsBytes(pdfBytes);
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'PrepTracker Gym Attendance Report (${DateFormat('yyyy-MM-dd').format(start)} to ${DateFormat('yyyy-MM-dd').format(end)})',
        );
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate report: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }
}
