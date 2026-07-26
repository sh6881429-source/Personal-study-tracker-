import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:prep_tracker/core/constants/app_colors.dart';
import 'package:prep_tracker/core/constants/app_text_styles.dart';
import 'package:prep_tracker/features/gym/data/models/gym_attendance_model.dart';
import 'package:prep_tracker/features/gym/presentation/providers/gym_provider.dart';
import 'package:prep_tracker/shared/widgets/app_button.dart';

// Helper decoration for Neo Brutalism style
BoxDecoration _brutalDecoration({
  required Color color,
  double radius = 16,
  double borderWidth = 3,
}) {
  return BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: AppColors.border, width: borderWidth),
    boxShadow: const [
      BoxShadow(
        color: AppColors.shadow,
        offset: Offset(4, 4),
      ),
    ],
  );
}

/// ── TODAY SUMMARY CARD ──
class GymTodayCard extends ConsumerWidget {
  const GymTodayCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(gymStatsProvider);
    final monthMap = ref.watch(gymAttendanceMapProvider);
    final todayKey = DateTime.now().toIso8601String().substring(0, 10);
    final todayRecord = monthMap[todayKey];

    return statsAsync.when(
      loading: () => const SizedBox(height: 140, child: Center(child: CircularProgressIndicator())),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (stats) {
        String statusText = 'Not logged yet';
        Color statusColor = Colors.grey.shade400;
        IconData statusIcon = Icons.help_outline_rounded;

        if (todayRecord != null) {
          if (todayRecord.status == 'Present') {
            statusText = 'Present';
            statusColor = AppColors.secondary;
            statusIcon = Icons.check_circle_rounded;
          } else if (todayRecord.status == 'Absent') {
            statusText = 'Absent';
            statusColor = AppColors.error;
            statusIcon = Icons.cancel_rounded;
          } else if (todayRecord.status == 'Rest Day') {
            statusText = 'Rest Day';
            statusColor = AppColors.primary;
            statusIcon = Icons.coffee_rounded;
          }
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: _brutalDecoration(color: const Color(0xFFFFD60A)), // Accent Yellow
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('EEEE, d MMMM').format(DateTime.now()),
                    style: AppTextStyles.labelLG(color: AppColors.border),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: AppColors.border, width: 2),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, color: statusColor, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          statusText,
                          style: AppTextStyles.labelSM(color: AppColors.border).copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Streak',
                          style: AppTextStyles.bodySM(color: Colors.black87),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.local_fire_department_rounded, color: AppColors.warning, size: 28),
                            const SizedBox(width: 4),
                            Text(
                              '${stats.currentStreak} Days',
                              style: AppTextStyles.headingLG(color: AppColors.border).copyWith(fontSize: 22),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 2,
                    height: 40,
                    color: AppColors.border,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Monthly Target',
                          style: AppTextStyles.bodySM(color: Colors.black87),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, color: AppColors.study, size: 28),
                            const SizedBox(width: 4),
                            Text(
                              '${stats.monthlyAttendancePercentage.toStringAsFixed(0)}%',
                              style: AppTextStyles.headingLG(color: AppColors.border).copyWith(fontSize: 22),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// ── CALENDAR VIEW WIDGET ──
class GymCalendarWidget extends ConsumerWidget {
  const GymCalendarWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMonth = ref.watch(selectedMonthProvider);
    final monthMap = ref.watch(gymAttendanceMapProvider);

    // Calculate grid properties
    final firstDay = DateTime(currentMonth.year, currentMonth.month, 1);
    final totalDays = DateTime(currentMonth.year, currentMonth.month + 1, 0).day;
    
    // weekday is 1 for Mon, 7 for Sun.
    // We want the grid cell starting offset matching Monday = 0, Sunday = 6.
    final startingOffset = firstDay.weekday - 1;

    final monthName = DateFormat('MMMM yyyy').format(currentMonth);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _brutalDecoration(color: AppColors.surface),
      child: Column(
        children: [
          // Header with navigation arrows
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.border, size: 20),
                onPressed: () {
                  ref.read(selectedMonthProvider.notifier).state =
                      DateTime(currentMonth.year, currentMonth.month - 1, 1);
                },
              ),
              Text(
                monthName,
                style: AppTextStyles.headingMD(color: AppColors.border),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.border, size: 20),
                onPressed: () {
                  ref.read(selectedMonthProvider.notifier).state =
                      DateTime(currentMonth.year, currentMonth.month + 1, 1);
                },
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Weekday Labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((day) {
              return SizedBox(
                width: 36,
                child: Center(
                  child: Text(
                    day,
                    style: AppTextStyles.labelMD(color: AppColors.border).copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),

          // Monthly Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: startingOffset + totalDays,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemBuilder: (context, index) {
              if (index < startingOffset) {
                return const SizedBox.shrink(); // Empty cells before the 1st of the month
              }

              final dayNum = index - startingOffset + 1;
              final cellDate = DateTime(currentMonth.year, currentMonth.month, dayNum);
              final key = cellDate.toIso8601String().substring(0, 10);
              final record = monthMap[key];

              return _CalendarDayCell(
                date: cellDate,
                record: record,
                onTap: () {
                  _showAttendanceBottomSheet(context, ref, cellDate, record);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  void _showAttendanceBottomSheet(
    BuildContext context,
    WidgetRef ref,
    DateTime date,
    GymAttendanceModel? record,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return GymAttendanceBottomSheet(date: date, record: record);
      },
    );
  }
}

/// ── INDIVIDUAL CALENDAR DAY CELL ──
class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
    required this.date,
    required this.record,
    required this.onTap,
  });

  final DateTime date;
  final GymAttendanceModel? record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final isToday = date.year == today.year && date.month == today.month && date.day == today.day;
    final isFuture = date.isAfter(today);

    Color cellColor = Colors.transparent;
    Color textCol = AppColors.border;

    if (record != null) {
      if (record!.status == 'Present') {
        cellColor = AppColors.secondary;
      } else if (record!.status == 'Absent') {
        cellColor = AppColors.error;
      } else if (record!.status == 'Rest Day') {
        cellColor = AppColors.primary;
        textCol = Colors.white;
      }
    }

    if (isFuture) {
      textCol = Colors.grey.shade400;
    }

    return GestureDetector(
      onTap: isFuture ? null : onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cellColor,
          borderRadius: BorderRadius.circular(10),
          border: isToday
              ? Border.all(color: AppColors.border, width: 3)
              : (record != null
                  ? Border.all(color: AppColors.border, width: 2)
                  : Border.all(color: Colors.grey.shade300, width: 1)),
          boxShadow: record != null
              ? const [BoxShadow(color: AppColors.border, offset: Offset(2, 2))]
              : null,
        ),
        child: Center(
          child: Text(
            '${date.day}',
            style: AppTextStyles.labelMD(color: textCol).copyWith(
              fontWeight: isToday || record != null ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

/// ── ATTENDANCE EDIT SHEET ──
class GymAttendanceBottomSheet extends ConsumerStatefulWidget {
  const GymAttendanceBottomSheet({
    super.key,
    required this.date,
    this.record,
  });

  final DateTime date;
  final GymAttendanceModel? record;

  @override
  ConsumerState<GymAttendanceBottomSheet> createState() => _GymAttendanceBottomSheetState();
}

class _GymAttendanceBottomSheetState extends ConsumerState<GymAttendanceBottomSheet> {
  late String _selectedStatus;
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.record?.status ?? 'Present';
    _notesController.text = widget.record?.notes ?? '';
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final dateStr = DateFormat('EEEE, d MMMM yyyy').format(widget.date);

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
                    'Log Attendance',
                    style: AppTextStyles.headingMD(color: AppColors.border),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.border, size: 24),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Text(
                dateStr,
                style: AppTextStyles.bodySM(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 20),

              // Custom Select Buttons
              Row(
                children: [
                  Expanded(
                    child: _statusButton(
                      label: 'Present',
                      status: 'Present',
                      color: AppColors.secondary,
                      icon: Icons.fitness_center_rounded,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _statusButton(
                      label: 'Absent',
                      status: 'Absent',
                      color: AppColors.error,
                      icon: Icons.close_rounded,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _statusButton(
                      label: 'Rest Day',
                      status: 'Rest Day',
                      color: AppColors.primary,
                      icon: Icons.coffee_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Notes TextField
              Text(
                'Notes / Remarks',
                style: AppTextStyles.labelMD(color: AppColors.border).copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _notesController,
                style: AppTextStyles.bodyMD(color: AppColors.border),
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Add notes about workout, recovery, diet...',
                  hintStyle: AppTextStyles.bodySM(color: Colors.grey.shade500),
                  fillColor: Colors.white,
                  filled: true,
                  contentPadding: const EdgeInsets.all(12),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: AppColors.border, width: 2.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: AppColors.border, width: 3.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  if (widget.record != null) ...[
                    Expanded(
                      flex: 1,
                      child: AppButton(
                        label: '',
                        icon: Icons.delete_outline_rounded,
                        variant: AppButtonVariant.danger,
                        onPressed: () async {
                          final navigator = Navigator.of(context);
                          await ref.read(gymControllerProvider.notifier).deleteAttendance(widget.record!.id);
                          navigator.pop();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    flex: 3,
                    child: AppButton(
                      label: 'Save log',
                      variant: AppButtonVariant.primary,
                      onPressed: () async {
                        final navigator = Navigator.of(context);
                        await ref.read(gymControllerProvider.notifier).logAttendance(
                              date: widget.date,
                              status: _selectedStatus,
                              notes: _notesController.text.trim().isEmpty
                                  ? null
                                  : _notesController.text.trim(),
                            );
                        navigator.pop();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusButton({
    required String label,
    required String status,
    required Color color,
    required IconData icon,
  }) {
    final isSelected = _selectedStatus == status;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedStatus = status;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: isSelected ? 3.5 : 2.5),
          boxShadow: isSelected
              ? const [BoxShadow(color: AppColors.border, offset: Offset(2, 2))]
              : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? (status == 'Rest Day' ? Colors.white : AppColors.border)
                  : color,
              size: 24,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: AppTextStyles.labelSM(
                color: isSelected
                    ? (status == 'Rest Day' ? Colors.white : AppColors.border)
                    : AppColors.border,
              ).copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ── STATISTICS GRID SECTION ──
class GymStatsSection extends ConsumerWidget {
  const GymStatsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(gymStatsProvider);

    return statsAsync.when(
      loading: () => const SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (stats) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Statistics',
              style: AppTextStyles.headingMD(color: AppColors.border),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
                final childAspectRatio = constraints.maxWidth > 600 ? 2.2 : 1.85;
                return GridView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: childAspectRatio,
                  ),
                  children: [
                    _StatCard(
                      label: 'Present Days',
                      value: '${stats.presentCount}',
                      icon: Icons.check_circle_rounded,
                      color: AppColors.secondary,
                    ),
                    _StatCard(
                      label: 'Absent Days',
                      value: '${stats.absentCount}',
                      icon: Icons.cancel_rounded,
                      color: AppColors.error,
                    ),
                    _StatCard(
                      label: 'Rest Days',
                      value: '${stats.restDaysCount}',
                      icon: Icons.coffee_rounded,
                      color: AppColors.primary,
                      textColor: Colors.white,
                    ),
                    _StatCard(
                      label: 'Longest Streak',
                      value: '${stats.longestStreak} Days',
                      icon: Icons.emoji_events_rounded,
                      color: const Color(0xFFFF8C42), // Accent Orange
                    ),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }
}

/// ── INDIVIDUAL STAT CARD ──
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.textColor = AppColors.border,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: _brutalDecoration(color: color),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: AppTextStyles.labelSM(
                  color: textColor.withValues(alpha: 0.85),
                ).copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(icon, color: textColor, size: 20),
            ],
          ),
          Text(
            value,
            style: AppTextStyles.headingLG(color: textColor).copyWith(
              fontSize: 24,
            ),
          ),
        ],
      ),
    );
  }
}
