import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:prep_tracker/core/constants/app_colors.dart';
import 'package:prep_tracker/core/services/notification_service.dart';
import 'package:prep_tracker/features/reminders/data/models/reminder_model.dart';
import 'package:prep_tracker/features/reminders/domain/models/reminder_type.dart';
import 'package:prep_tracker/features/reminders/presentation/providers/reminder_provider.dart';
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

class RemindersScreen extends ConsumerStatefulWidget {
  const RemindersScreen({super.key});

  @override
  ConsumerState<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends ConsumerState<RemindersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!NotificationService.isPermissionGranted) {
        _showNotificationPermissionInAppModal(context);
      }
    });
  }

  void _showNotificationPermissionInAppModal(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.text;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.black, width: 3.5),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black,
                  offset: Offset(5, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header Icon Badge
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD60A),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 2.5),
                    boxShadow: const [
                      BoxShadow(color: Colors.black, offset: Offset(2.5, 2.5)),
                    ],
                  ),
                  child: const Icon(
                    Icons.notifications_active_rounded,
                    size: 30,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 14),

                // Title
                Text(
                  'Enable In-App Notifications',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 6),

                // Subtitle / Description
                Text(
                  'Never miss your study sessions, gym workouts, or daily goals! Enable notifications to receive timely alerts.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    height: 1.35,
                    color: isDark ? Colors.white70 : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),

                // Feature Checklist
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFFFFDF0),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                  child: Column(
                    children: [
                      _permissionFeatureRow(
                        Icons.alarm_on_rounded,
                        'Daily Study & Gym Reminders',
                        isDark,
                      ),
                      const SizedBox(height: 8),
                      _permissionFeatureRow(
                        Icons.emoji_events_rounded,
                        'Goal Achievement Milestones',
                        isDark,
                      ),
                      const SizedBox(height: 8),
                      _permissionFeatureRow(
                        Icons.bolt_rounded,
                        'Real-Time Discipline Alerts',
                        isDark,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.of(dialogContext).pop(),
                        child: Container(
                          height: 42,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.black, width: 2),
                          ),
                          child: Center(
                            child: Text(
                              'Not Now',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: GestureDetector(
                        onTap: () async {
                          Navigator.of(dialogContext).pop();
                          final granted = await NotificationService.requestPermission();
                          if (context.mounted) {
                            if (granted) {
                              AppSnackbar.showSuccess(
                                context,
                                'Notification permissions enabled successfully!',
                              );
                            } else {
                              AppSnackbar.showWarning(
                                context,
                                'Notification permission was denied in browser settings.',
                              );
                            }
                          }
                        },
                        child: Container(
                          height: 42,
                          decoration: BoxDecoration(
                            color: const Color(0xFF5B5FEF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.black, width: 2.5),
                            boxShadow: const [
                              BoxShadow(color: Colors.black, offset: Offset(2.5, 2.5)),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 15),
                              const SizedBox(width: 5),
                              Text(
                                'Allow Notifications',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _permissionFeatureRow(IconData icon, String text, bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFFFD60A),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black, width: 1.5),
          ),
          child: Icon(icon, size: 12, color: Colors.black),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reminderProvider);
    final notifier = ref.read(reminderProvider.notifier);

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
          'Reminders & Alerts',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: textColor,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Notification Permission',
            icon: const Icon(Icons.notifications_active_rounded, color: AppColors.primary),
            onPressed: () => _showNotificationPermissionInAppModal(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              // ── Top Action Header ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Active Schedule',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: textColor,
                            ),
                          ),
                          Text(
                            '${state.activeCount} active reminders scheduled',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AppButton(
                      label: 'Add Reminder',
                      icon: Icons.add_rounded,
                      size: AppButtonSize.sm,
                      onPressed: () => _showAddEditReminderDialog(context),
                      variant: AppButtonVariant.primary,
                    ),
                  ],
                ),
              ),

              // ── Category Filters ──
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    _filterChip(
                      label: 'All',
                      icon: Icons.all_inclusive_rounded,
                      isSelected: state.selectedFilter == null,
                      color: AppColors.primary,
                      onTap: () => notifier.setFilter(null),
                      textColor: textColor,
                    ),
                    const SizedBox(width: 8),
                    ...ReminderType.values.map((type) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _filterChip(
                          label: type.displayName,
                          icon: type.icon,
                          isSelected: state.selectedFilter == type,
                          color: type.color,
                          onTap: () => notifier.setFilter(type),
                          textColor: textColor,
                        ),
                      );
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // ── Reminders List ──
              Expanded(
                child: state.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : state.filteredReminders.isEmpty
                        ? _buildEmptyState(context, textColor, secondaryTextColor)
                        : RefreshIndicator(
                            onRefresh: () => notifier.loadReminders(),
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                              itemCount: state.filteredReminders.length,
                              itemBuilder: (ctx, index) {
                                final reminder = state.filteredReminders[index];
                                return _buildReminderCard(context, reminder, textColor, secondaryTextColor);
                              },
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
    required Color textColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? color
              : (isDark ? const Color(0xFF262626) : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? (isDark ? Colors.white : AppColors.border) : (isDark ? Colors.grey.shade700 : AppColors.border),
            width: isSelected ? 3 : 2,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: isDark ? Colors.black : AppColors.shadow, offset: const Offset(2, 2))]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : color),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: isSelected ? Colors.white : textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderCard(
    BuildContext context,
    ReminderModel reminder,
    Color textColor,
    Color secondaryTextColor,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final type = reminder.type;
    final formattedDate = DateFormat('EEE, MMM d • hh:mm a').format(reminder.scheduledAt);
    final recurrenceLabel = reminder.isRecurring
        ? (reminder.recurrencePattern?.toUpperCase() ?? 'DAILY REPEAT')
        : 'ONE-TIME';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: _brutalDecoration(context, Colors.white),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: type.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: type.color, width: 2),
                ),
                child: Icon(type.icon, color: type.color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            reminder.title,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: textColor,
                              decoration: reminder.isEnabled ? null : TextDecoration.lineThrough,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (reminder.isEnabled) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.secondary),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          type.displayName,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: type.color,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: reminder.isRecurring
                                ? AppColors.secondary.withValues(alpha: 0.2)
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: reminder.isRecurring ? AppColors.secondary : Colors.grey,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                reminder.isRecurring ? Icons.repeat_rounded : Icons.event_rounded,
                                size: 10,
                                color: reminder.isRecurring ? AppColors.secondary : Colors.grey.shade700,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                recurrenceLabel,
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: reminder.isRecurring ? AppColors.secondary : Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Switch(
                value: reminder.isEnabled,
                activeThumbColor: type.color,
                onChanged: (val) {
                  ref.read(reminderProvider.notifier).toggleReminder(reminder.id, val);
                },
              ),
            ],
          ),

          if (reminder.message.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              reminder.message,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: secondaryTextColor,
              ),
            ),
          ],

          const SizedBox(height: 10),
          Divider(height: 1, color: isDark ? Colors.white24 : Colors.grey.shade300),
          const SizedBox(height: 8),

          Row(
            children: [
              Icon(Icons.schedule_rounded, size: 14, color: secondaryTextColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  formattedDate,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: secondaryTextColor,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.notifications_active_rounded, size: 18, color: AppColors.primary),
                tooltip: 'Test Fire Now',
                onPressed: () {
                  NotificationService.showNotification(
                    title: reminder.title,
                    message: reminder.message.isNotEmpty ? reminder.message : 'Reminder trigger test!',
                    type: reminder.type,
                    targetRoute: reminder.targetRoute,
                    scheduledTime: reminder.scheduledAt,
                  );
                  AppSnackbar.showSuccess(context, 'Notification fired for testing!');
                },
              ),
              IconButton(
                icon: const Icon(Icons.edit_rounded, size: 18),
                color: type.color,
                tooltip: 'Edit',
                onPressed: () => _showAddEditReminderDialog(context, reminder: reminder),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                color: AppColors.error,
                tooltip: 'Delete',
                onPressed: () => _confirmDeleteReminder(context, reminder),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, Color textColor, Color secondaryTextColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 3),
            ),
            child: const Icon(Icons.alarm_on_rounded, size: 48, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          Text(
            'No Scheduled Reminders',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: textColor,
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Create a reminder for study, gym, revision, or exams to never miss a milestone!',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: secondaryTextColor,
              ),
            ),
          ),
          const SizedBox(height: 20),
          AppButton(
            label: 'Create First Reminder',
            icon: Icons.add_rounded,
            onPressed: () => _showAddEditReminderDialog(context),
            variant: AppButtonVariant.primary,
          ),
        ],
      ),
    );
  }

  void _showAddEditReminderDialog(BuildContext context, {ReminderModel? reminder}) {
    final isEditing = reminder != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.text;

    final titleController = TextEditingController(text: reminder?.title ?? '');
    final messageController = TextEditingController(text: reminder?.message ?? '');
    ReminderType selectedType = reminder?.type ?? ReminderType.study;
    String selectedRoute = reminder?.targetRoute ?? selectedType.defaultTargetRoute;
    DateTime selectedDateTime = reminder?.scheduledAt ?? DateTime.now().add(const Duration(hours: 1));
    String recurrencePattern = reminder?.recurrencePattern ?? 'daily'; // Default to daily repeat

    final formKey = GlobalKey<FormState>();

    showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF262626) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: isDark ? Colors.white : AppColors.border, width: 3),
              ),
              title: Row(
                children: [
                  Icon(
                    isEditing ? Icons.edit_calendar_rounded : Icons.notification_add_rounded,
                    color: selectedType.color,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isEditing ? 'Edit Reminder' : 'Add Reminder',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w900, color: textColor),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      TextFormField(
                        controller: titleController,
                        style: GoogleFonts.inter(color: textColor, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          labelText: 'Title *',
                          labelStyle: GoogleFonts.inter(color: textColor.withValues(alpha: 0.7)),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Title is required' : null,
                      ),
                      const SizedBox(height: 12),

                      // Message
                      TextFormField(
                        controller: messageController,
                        style: GoogleFonts.inter(color: textColor),
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Message (Optional)',
                          labelStyle: GoogleFonts.inter(color: textColor.withValues(alpha: 0.7)),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Reminder Category Type
                      Text(
                        'Category / Type',
                        style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: textColor),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: ReminderType.values.map((t) {
                          final isSel = selectedType == t;
                          return ChoiceChip(
                            label: Text(t.displayName),
                            avatar: Icon(t.icon, size: 16, color: isSel ? Colors.white : t.color),
                            selected: isSel,
                            selectedColor: t.color,
                            labelStyle: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isSel ? Colors.white : textColor,
                            ),
                            onSelected: (val) {
                              if (val) {
                                setDialogState(() {
                                  selectedType = t;
                                  selectedRoute = t.defaultTargetRoute;
                                });
                              }
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14),

                      // Repeat Frequency Selector (Daily, Once, Weekly, Weekdays)
                      Text(
                        'Repeat Schedule',
                        style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: textColor),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _repeatOptionChip(
                            label: 'Daily (Every Day)',
                            value: 'daily',
                            icon: Icons.replay_rounded,
                            currentValue: recurrencePattern,
                            onTap: (v) => setDialogState(() => recurrencePattern = v),
                            textColor: textColor,
                          ),
                          _repeatOptionChip(
                            label: 'Once (Single Alert)',
                            value: 'once',
                            icon: Icons.event_rounded,
                            currentValue: recurrencePattern,
                            onTap: (v) => setDialogState(() => recurrencePattern = v),
                            textColor: textColor,
                          ),
                          _repeatOptionChip(
                            label: 'Weekly',
                            value: 'weekly',
                            icon: Icons.calendar_view_week_rounded,
                            currentValue: recurrencePattern,
                            onTap: (v) => setDialogState(() => recurrencePattern = v),
                            textColor: textColor,
                          ),
                          _repeatOptionChip(
                            label: 'Weekdays (Mon-Fri)',
                            value: 'weekdays',
                            icon: Icons.work_history_rounded,
                            currentValue: recurrencePattern,
                            onTap: (v) => setDialogState(() => recurrencePattern = v),
                            textColor: textColor,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Date & Time Picker Row
                      Text(
                        'Scheduled Time',
                        style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: textColor),
                      ),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: () async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: selectedDateTime,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (pickedDate != null && context.mounted) {
                            final pickedTime = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.fromDateTime(selectedDateTime),
                            );
                            if (pickedTime != null) {
                              setDialogState(() {
                                selectedDateTime = DateTime(
                                  pickedDate.year,
                                  pickedDate.month,
                                  pickedDate.day,
                                  pickedTime.hour,
                                  pickedTime.minute,
                                );
                              });
                            }
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF333333) : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: isDark ? Colors.white70 : AppColors.border, width: 2),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  DateFormat('EEE, MMM d, yyyy • hh:mm a').format(selectedDateTime),
                                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12, color: textColor),
                                ),
                              ),
                              const Icon(Icons.edit_calendar_rounded, size: 18, color: AppColors.primary),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Cancel', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: textColor)),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle_rounded, size: 18),
                  label: Text(isEditing ? 'Update Reminder' : 'Save Reminder', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedType.color,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;

                    final title = titleController.text.trim();
                    final message = messageController.text.trim();
                    final isRecurring = recurrencePattern != 'once';

                    try {
                      if (isEditing) {
                        final updated = reminder.copyWith(
                          title: title,
                          message: message,
                          type: selectedType,
                          targetRoute: selectedRoute,
                          scheduledAt: selectedDateTime,
                          isRecurring: isRecurring,
                          recurrencePattern: recurrencePattern,
                          updatedAt: DateTime.now(),
                        );
                        await ref.read(reminderProvider.notifier).updateReminder(updated);
                      } else {
                        await ref.read(reminderProvider.notifier).addReminder(
                              title: title,
                              message: message,
                              type: selectedType,
                              targetRoute: selectedRoute,
                              scheduledAt: selectedDateTime,
                              isRecurring: isRecurring,
                              recurrencePattern: recurrencePattern,
                            );
                      }
                      if (context.mounted) {
                        Navigator.pop(ctx);
                        _showSaveSuccessDialog(context, title, recurrencePattern);
                      }
                    } catch (e) {
                      if (context.mounted) {
                        AppSnackbar.showError(context, 'Failed to save reminder: $e');
                      }
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _repeatOptionChip({
    required String label,
    required String value,
    required IconData icon,
    required String currentValue,
    required ValueChanged<String> onTap,
    required Color textColor,
  }) {
    final isSel = currentValue == value;
    return ChoiceChip(
      label: Text(label),
      avatar: Icon(icon, size: 14, color: isSel ? Colors.white : AppColors.primary),
      selected: isSel,
      selectedColor: AppColors.primary,
      labelStyle: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: isSel ? Colors.white : textColor,
      ),
      onSelected: (val) {
        if (val) onTap(value);
      },
    );
  }

  void _showSaveSuccessDialog(BuildContext context, String title, String repeatPattern) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.text;

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF262626) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.secondary, width: 3),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, size: 64, color: AppColors.secondary),
            const SizedBox(height: 12),
            Text(
              'Reminder Saved!',
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w900, color: textColor),
            ),
            const SizedBox(height: 6),
            Text(
              '"$title"\nis scheduled successfully (${repeatPattern.toUpperCase()} repeat).',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.grey.shade300 : AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: Text('Done ✓', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteReminder(BuildContext context, ReminderModel reminder) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Reminder?'),
        content: Text('Are you sure you want to delete "${reminder.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(reminderProvider.notifier).deleteReminder(reminder.id);
              if (context.mounted) {
                AppSnackbar.showSuccess(context, 'Reminder deleted.');
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
