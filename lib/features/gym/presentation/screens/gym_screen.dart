import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:prep_tracker/core/constants/app_colors.dart';
import 'package:prep_tracker/core/constants/app_strings.dart';
import 'package:prep_tracker/core/constants/app_text_styles.dart';
import 'package:prep_tracker/features/gym/presentation/providers/gym_provider.dart';
import 'package:prep_tracker/features/gym/presentation/widgets/gym_widgets.dart';
import 'package:prep_tracker/features/gym/presentation/widgets/gym_export_sheet.dart';
import 'package:prep_tracker/shared/widgets/app_drawer.dart';

class GymScreen extends ConsumerStatefulWidget {
  const GymScreen({super.key});

  @override
  ConsumerState<GymScreen> createState() => _GymScreenState();
}

class _GymScreenState extends ConsumerState<GymScreen> {
  @override
  void initState() {
    super.initState();
    // Auto-trigger sync on entry
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gymControllerProvider.notifier).syncOfflineQueue();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isSyncing = ref.watch(gymControllerProvider);
    final monthMap = ref.watch(gymAttendanceMapProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF6E8), // True Neo Brutalist Warm Sand/Cream page bg
      drawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF6E8),
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: AppColors.text, size: 24),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text(
          AppStrings.titleGym,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w900,
            fontSize: 22,
            color: AppColors.text,
          ),
        ),
        centerTitle: false,
        actions: [
          // Offline Sync Queue trigger
          IconButton(
            icon: isSyncing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.border,
                    ),
                  )
                : const Icon(Icons.cloud_sync_rounded, color: AppColors.text, size: 24),
            onPressed: isSyncing
                ? null
                : () {
                    ref.read(gymControllerProvider.notifier).syncOfflineQueue();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Processing offline sync queue...')),
                    );
                  },
          ),
          // Export PDF option
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.text, size: 24),
            onPressed: () {
              showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (ctx) => const GymExportSheet(),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            await ref.read(gymControllerProvider.notifier).syncOfflineQueue();
            ref.invalidate(gymStatsProvider);
            ref.invalidate(rawGymAttendanceProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Today's Summary Card
                const GymTodayCard(),
                const SizedBox(height: 16),

                // 2. Calendar Grid
                const GymCalendarWidget(),
                const SizedBox(height: 20),

                // 3. Stats Grid Section
                const GymStatsSection(),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFFF5D73), // Gym theme color (pink)
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border, width: 3),
        ),
        onPressed: () {
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final todayKey = today.toIso8601String().substring(0, 10);
          final record = monthMap[todayKey];
          
          showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (ctx) {
              return GymAttendanceBottomSheet(date: today, record: record);
            },
          );
        },
        icon: const Icon(Icons.fitness_center_rounded, size: 22),
        label: Text(
          'Log Today',
          style: AppTextStyles.labelMD(color: Colors.white).copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
