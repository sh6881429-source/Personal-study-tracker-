import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:prep_tracker/core/constants/app_colors.dart';
import 'package:prep_tracker/features/reminders/presentation/providers/reminder_provider.dart';
import 'package:prep_tracker/features/reminders/data/models/reminder_model.dart';
import 'package:prep_tracker/features/reminders/domain/models/reminder_type.dart';
import 'package:prep_tracker/core/theme/theme_provider.dart';
import 'package:prep_tracker/features/ask_yash_bot/presentation/providers/overlay_manager_provider.dart';
import 'package:prep_tracker/shared/widgets/app_button.dart';

/// ── Home Top Bar ──
/// Hamburger menu, central title, and active notifications button.
class HomeTopBar extends ConsumerStatefulWidget {
  const HomeTopBar({super.key});

  @override
  ConsumerState<HomeTopBar> createState() => _HomeTopBarState();
}

class _HomeTopBarState extends ConsumerState<HomeTopBar> {
  @override
  Widget build(BuildContext context) {
    final reminderState = ref.watch(reminderProvider);
    final count = reminderState.reminders.length;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.text;
    final cardBgColor = isDark ? const Color(0xFF1E293B) : Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Hamburger menu button
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: cardBgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? Colors.white70 : AppColors.border, width: 3),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadow,
                  offset: Offset(2.5, 2.5),
                ),
              ],
            ),
            child: Builder(
              builder: (ctx) => IconButton(
                icon: Icon(Icons.menu_rounded, color: textColor, size: 22),
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            ),
          ),

          // Central title & subtitle
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PrepTracker',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: textColor,
                      height: 1.1,
                    ),
                  ),
                  Text(
                    'Plan. Focus. Achieve.',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white70 : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Yash Bot AI Assistant Button
          GestureDetector(
            onTap: () {
              ref.read(overlayManagerProvider.notifier).toggleWindow();
            },
            child: Container(
              width: 44,
              height: 44,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD60A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border, width: 3),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.shadow,
                    offset: Offset(2.5, 2.5),
                  ),
                ],
              ),
              child: const Tooltip(
                message: 'Ask Yash Bot AI Assistant',
                child: Icon(
                  Icons.smart_toy_rounded,
                  color: Colors.black,
                  size: 22,
                ),
              ),
            ),
          ),

          // Dark / Light Mode Toggle Button
          GestureDetector(
            onTap: () {
              ref.read(themeModeProvider.notifier).toggleTheme(context);
            },
            child: Container(
              width: 44,
              height: 44,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFFFFD60A) : const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border, width: 3),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.shadow,
                    offset: Offset(2.5, 2.5),
                  ),
                ],
              ),
              child: Tooltip(
                message: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                child: Icon(
                  isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  color: isDark ? Colors.black : Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),

          // Notification bell button (Interactive)
          GestureDetector(
            onTap: () => _showNotificationHistoryModal(context),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: cardBgColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? Colors.white70 : AppColors.border, width: 3),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.shadow,
                        offset: Offset(2.5, 2.5),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.notifications_active_rounded,
                    color: textColor,
                    size: 22,
                  ),
                ),
                if (count > 0)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF5C8A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border, width: 2),
                      ),
                      child: Text(
                        '$count',
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showNotificationHistoryModal(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.text;
    final reminderState = ref.read(reminderProvider);
    final reminders = reminderState.reminders;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1F1F1F) : const Color(0xFFFAF6E8),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        side: BorderSide(color: AppColors.border, width: 3),
      ),
      builder: (modalCtx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (ctx, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Modal handle indicator
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white38 : AppColors.border,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  // Header title & Manage Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.notifications_active_rounded, color: AppColors.primary, size: 26),
                          const SizedBox(width: 10),
                          Text(
                            'Notifications History',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w900, fontSize: 18, color: textColor),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(modalCtx),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Manage Reminders button
                  SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      label: 'Manage Scheduled Reminders',
                      icon: Icons.settings_suggest_rounded,
                      size: AppButtonSize.sm,
                      onPressed: () {
                        Navigator.pop(modalCtx);
                        context.push('/reminders');
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Active Notifications (${reminders.length})',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13, color: textColor),
                      ),
                      if (reminders.isNotEmpty)
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          icon: const Icon(Icons.delete_sweep_rounded, size: 18, color: AppColors.error),
                          label: Text(
                            'Clear All',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.error),
                          ),
                          onPressed: () => _confirmClearAll(context, reminders),
                        ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Reminders List / Empty State
                  Expanded(
                    child: reminders.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.notifications_off_rounded, size: 48, color: Colors.grey),
                                const SizedBox(height: 12),
                                Text(
                                  'No Notifications Set',
                                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: textColor),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Create custom reminders for study sessions, gym workouts, or revisions.',
                                  style: GoogleFonts.inter(fontSize: 12, color: isDark ? Colors.white60 : AppColors.textSecondary),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            controller: scrollController,
                            itemCount: reminders.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (listCtx, idx) {
                              final item = reminders[idx];
                              return _buildNotificationTile(
                                context: modalCtx,
                                item: item,
                                isDark: isDark,
                                textColor: textColor,
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _confirmClearAll(BuildContext context, List<ReminderModel> list) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Clear All Notifications?', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to delete all scheduled notifications?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(ctx);
              final notifier = ref.read(reminderProvider.notifier);
              for (final item in list) {
                await notifier.deleteReminder(item.id);
              }
            },
            child: const Text('Clear All', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationTile({
    required BuildContext context,
    required ReminderModel item,
    required bool isDark,
    required Color textColor,
  }) {
    final scheduledTimeStr = DateFormat('hh:mm a').format(item.scheduledAt);
    final isDaily = item.isRecurring;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white30 : AppColors.border, width: 2),
        boxShadow: const [
          BoxShadow(color: AppColors.shadow, offset: Offset(2, 2)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: item.type.color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(item.type.icon, color: item.type.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13, color: textColor),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Delete Notification',
                      onPressed: () {
                        ref.read(reminderProvider.notifier).deleteReminder(item.id);
                      },
                    ),
                  ],
                ),
                Text(
                  item.message,
                  style: GoogleFonts.inter(fontSize: 11, color: isDark ? Colors.white70 : AppColors.textSecondary),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: item.type.color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.type.displayName,
                        style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.access_time_rounded, size: 12, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '$scheduledTimeStr ${isDaily ? '(Daily)' : ''}',
                      style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Yellow Welcome Banner ───────────────────────────────────────────────────

class WelcomeBanner extends StatelessWidget {
  const WelcomeBanner({super.key, required this.userName});
  final String userName;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 125,
      decoration: BoxDecoration(
        color: const Color(0xFFFFD93D), // Yellow accent
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 3),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            offset: Offset(4, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Greeting content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Text(
                      'Hey $userName!',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '👋',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Stay consistent today and\nmake it count.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),

          // Cartoon character vector drawing on right
          Positioned(
            right: 12,
            bottom: 0,
            child: SizedBox(
              width: 110,
              height: 120,
              child: CustomPaint(
                painter: _CartoonCharacterPainter(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CartoonCharacterPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final outlinePaint = Paint()
      ..color = AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final cx = size.width / 2;
    final cy = size.height / 2 + 10; // Shift down slightly

    // ── 1. Yellow Background Dot Grid Matrix ──
    final dotPaint = Paint()
      ..color = AppColors.border.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;
    for (double x = cx + 18; x < size.width; x += 8) {
      for (double y = cy - 45; y < cy + 15; y += 8) {
        // Draw circular dots
        canvas.drawCircle(Offset(x, y), 1.5, dotPaint);
      }
    }

    // ── 2. Action Spark Lines on Left (Our left, his right: \ | /) ──
    final sparkPaint = Paint()
      ..color = AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx - 30, cy - 20), Offset(cx - 38, cy - 16), sparkPaint);
    canvas.drawLine(Offset(cx - 34, cy - 10), Offset(cx - 44, cy - 10), sparkPaint);
    canvas.drawLine(Offset(cx - 31, cy), Offset(cx - 39, cy + 4), sparkPaint);

    // ── 3. Draw Purple Hoodie body (with shoulders) ──
    final bodyPath = Path()
      ..moveTo(cx - 45, size.height)
      ..lineTo(cx - 40, cy + 30)
      ..quadraticBezierTo(cx - 24, cy + 22, cx - 18, cy + 20)
      ..lineTo(cx + 18, cy + 20)
      ..quadraticBezierTo(cx + 24, cy + 22, cx + 40, cy + 30)
      ..lineTo(cx + 45, size.height)
      ..close();
    paint.color = const Color(0xFF7C3AED); // Deep Purple Hoodie
    canvas.drawPath(bodyPath, paint);
    canvas.drawPath(bodyPath, outlinePaint);

    // ── 4. Draw Neck ──
    final neckPath = Path()
      ..moveTo(cx - 8, cy + 12)
      ..lineTo(cx - 8, cy + 20)
      ..lineTo(cx + 8, cy + 20)
      ..lineTo(cx + 8, cy + 12)
      ..close();
    paint.color = const Color(0xFFFFD5B4); // Peachy Skin color
    canvas.drawPath(neckPath, paint);
    canvas.drawPath(neckPath, outlinePaint);

    // ── 5. Draw Ears ──
    paint.color = const Color(0xFFFFD5B4);
    canvas.drawCircle(Offset(cx - 20, cy - 2), 5, paint);
    canvas.drawCircle(Offset(cx - 20, cy - 2), 5, outlinePaint);
    canvas.drawCircle(Offset(cx + 20, cy - 2), 5, paint);
    canvas.drawCircle(Offset(cx + 20, cy - 2), 5, outlinePaint);

    // ── 6. Draw Face Head Circle ──
    final headCenter = Offset(cx, cy - 2);
    const headRadius = 20.0;
    paint.color = const Color(0xFFFFD5B4);
    canvas.drawCircle(headCenter, headRadius, paint);
    canvas.drawCircle(headCenter, headRadius, outlinePaint);

    // ── 7. Draw Combed/Styled Hair (Black swoop to left) ──
    final hairPath = Path()
      ..moveTo(cx - 21, cy - 6)
      // swoop left profile
      ..quadraticBezierTo(cx - 22, cy - 24, cx, cy - 25)
      ..quadraticBezierTo(cx + 22, cy - 24, cx + 21, cy - 6)
      ..quadraticBezierTo(cx + 12, cy - 18, cx, cy - 14)
      ..quadraticBezierTo(cx - 10, cy - 18, cx - 21, cy - 6)
      ..close();
    paint.color = AppColors.border; // Black/border color
    canvas.drawPath(hairPath, paint);
    canvas.drawPath(hairPath, outlinePaint);

    // Side swoop detail line
    final detailHairPath = Path()
      ..moveTo(cx - 6, cy - 20)
      ..quadraticBezierTo(cx, cy - 17, cx + 8, cy - 21);
    canvas.drawPath(detailHairPath, outlinePaint);

    // ── 8. Draw Eyes & Eyebrows ──
    paint.color = AppColors.border;
    canvas.drawCircle(Offset(cx - 7, cy - 4), 2, paint);
    canvas.drawCircle(Offset(cx + 7, cy - 4), 2, paint);

    canvas.drawLine(Offset(cx - 11, cy - 9), Offset(cx - 4, cy - 8), outlinePaint);
    canvas.drawLine(Offset(cx + 4, cy - 8), Offset(cx + 11, cy - 9), outlinePaint);

    // Nose line
    canvas.drawLine(Offset(cx, cy - 2), Offset(cx - 2, cy + 2), outlinePaint);

    // ── 9. Draw Smile ──
    final smilePath = Path()
      ..moveTo(cx - 5, cy + 6)
      ..quadraticBezierTo(cx, cy + 9, cx + 5, cy + 6);
    canvas.drawPath(smilePath, outlinePaint);

    // ── 10. Draw Hoodie Collar V detail & drawstrings ──
    final collarPath = Path()
      ..moveTo(cx - 14, cy + 20)
      ..lineTo(cx, cy + 30)
      ..lineTo(cx + 14, cy + 20);
    canvas.drawPath(collarPath, outlinePaint);

    // Left drawstring line
    canvas.drawLine(Offset(cx - 4, cy + 24), Offset(cx - 5, cy + 32), outlinePaint);
    canvas.drawCircle(Offset(cx - 5, cy + 32), 1.5, paint);

    // Right drawstring line
    canvas.drawLine(Offset(cx + 4, cy + 24), Offset(cx + 5, cy + 32), outlinePaint);
    canvas.drawCircle(Offset(cx + 5, cy + 32), 1.5, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
