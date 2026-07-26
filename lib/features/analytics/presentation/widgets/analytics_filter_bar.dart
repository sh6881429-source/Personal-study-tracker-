import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:prep_tracker/core/constants/app_colors.dart';
import 'package:prep_tracker/features/analytics/data/models/analytics_data_model.dart';
import 'package:prep_tracker/features/analytics/presentation/providers/analytics_provider.dart';

class AnalyticsFilterBar extends ConsumerWidget {
  const AnalyticsFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedFilter = ref.watch(analyticsDateFilterProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: AnalyticsDateFilter.values.map((filter) {
          final isSelected = selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8, bottom: 4),
            child: GestureDetector(
              onTap: () {
                ref.read(analyticsDateFilterProvider.notifier).state = filter;
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF5B5FEF)
                      : (isDark ? const Color(0xFF2A2A2A) : Colors.white),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.black, width: 2.5),
                  boxShadow: isSelected
                      ? const [BoxShadow(color: Colors.black, offset: Offset(2.5, 2.5))]
                      : const [BoxShadow(color: Colors.black26, offset: Offset(1.5, 1.5))],
                ),
                child: Text(
                  filter.label,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: isSelected ? Colors.white : (isDark ? Colors.white70 : AppColors.text),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
