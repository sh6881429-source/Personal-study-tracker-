import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:prep_tracker/core/constants/app_colors.dart';
import 'package:prep_tracker/features/study/presentation/providers/study_goal_provider.dart';
import 'package:prep_tracker/shared/widgets/app_button.dart';
import 'package:prep_tracker/shared/widgets/app_snackbar.dart';

class GoalConfigScreen extends ConsumerStatefulWidget {
  const GoalConfigScreen({super.key});

  @override
  ConsumerState<GoalConfigScreen> createState() => _GoalConfigScreenState();
}

class _GoalConfigScreenState extends ConsumerState<GoalConfigScreen> {
  double _dailyHours = 6.0;
  double _weeklyHours = 42.0;
  double _monthlyHours = 180.0;
  bool _isSaving = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
  }

  void _loadExistingGoals() {
    final goalState = ref.read(studyGoalProvider);
    goalState.whenData((goals) {
      if (!_initialized) {
        setState(() {
          _dailyHours = goals.dailyGoalHours;
          _weeklyHours = goals.weeklyGoalHours;
          _monthlyHours = goals.monthlyGoalHours;
          _initialized = true;
        });
      }
    });
  }

  Future<void> _saveGoals() async {
    setState(() => _isSaving = true);
    try {
      final dailyMins = (_dailyHours * 60).round();
      final weeklyMins = (_weeklyHours * 60).round();
      final monthlyMins = (_monthlyHours * 60).round();

      await ref.read(studyGoalProvider.notifier).updateGoals(
            dailyGoalMinutes: dailyMins,
            weeklyGoalMinutes: weeklyMins,
            monthlyGoalMinutes: monthlyMins,
          );

      if (mounted) {
        AppSnackbar.showSuccess(context, 'Study goals updated successfully!');
        context.pop();
      }
    } catch (e) {
      if (mounted) AppSnackbar.showError(context, 'Failed to save goals: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    _loadExistingGoals();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.text;

    return Scaffold(
      appBar: AppBar(
        title: Text('Study Goal Settings', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary, width: 2),
              ),
              child: Row(
                children: [
                  const Icon(Icons.stars_rounded, color: AppColors.primary, size: 36),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Set Target Study Hours',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 16, color: textColor),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Configure daily, weekly, and monthly targets to keep yourself accountable.',
                          style: GoogleFonts.inter(fontSize: 12, color: isDark ? Colors.white70 : AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Daily Goal Slider Card
            _buildGoalSliderCard(
              title: 'Daily Study Target',
              subtitle: 'Recommended: 6 to 8 Hours',
              icon: Icons.today_rounded,
              color: AppColors.primary,
              value: _dailyHours,
              min: 1.0,
              max: 16.0,
              divisions: 30,
              unit: 'Hours / Day',
              onChanged: (val) => setState(() => _dailyHours = val),
              isDark: isDark,
              textColor: textColor,
            ),

            const SizedBox(height: 20),

            // Weekly Goal Slider Card
            _buildGoalSliderCard(
              title: 'Weekly Study Target',
              subtitle: 'Recommended: 35 to 50 Hours',
              icon: Icons.date_range_rounded,
              color: AppColors.secondary,
              value: _weeklyHours,
              min: 5.0,
              max: 100.0,
              divisions: 95,
              unit: 'Hours / Week',
              onChanged: (val) => setState(() => _weeklyHours = val),
              isDark: isDark,
              textColor: textColor,
            ),

            const SizedBox(height: 20),

            // Monthly Goal Slider Card
            _buildGoalSliderCard(
              title: 'Monthly Study Target',
              subtitle: 'Recommended: 150 to 220 Hours',
              icon: Icons.calendar_month_rounded,
              color: AppColors.warning,
              value: _monthlyHours,
              min: 20.0,
              max: 350.0,
              divisions: 66,
              unit: 'Hours / Month',
              onChanged: (val) => setState(() => _monthlyHours = val),
              isDark: isDark,
              textColor: textColor,
            ),

            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: AppButton(
                label: 'Save Study Goals',
                icon: Icons.check_circle_rounded,
                isLoading: _isSaving,
                onPressed: _saveGoals,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalSliderCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String unit,
    required ValueChanged<double> onChanged,
    required bool isDark,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF262626) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white : AppColors.border, width: 3),
        boxShadow: const [
          BoxShadow(color: AppColors.shadow, offset: Offset(3, 3)),
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
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: textColor)),
                      Text(subtitle, style: GoogleFonts.inter(fontSize: 11, color: isDark ? Colors.white60 : AppColors.textSecondary)),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.black, width: 2),
                ),
                child: Text(
                  '${value.toStringAsFixed(1)} h',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w900, fontSize: 14, color: Colors.white),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: color,
              inactiveTrackColor: color.withValues(alpha: 0.2),
              thumbColor: color,
              overlayColor: color.withValues(alpha: 0.2),
              valueIndicatorTextStyle: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              label: '${value.toStringAsFixed(1)} Hours',
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
