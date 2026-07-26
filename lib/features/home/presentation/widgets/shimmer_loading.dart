import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:prep_tracker/core/constants/app_colors.dart';
import 'package:prep_tracker/core/constants/app_constants.dart';
import 'package:prep_tracker/core/constants/app_spacing.dart';

/// ── Dashboard Shimmer Skeleton Loader ──
class DashboardShimmerLoading extends StatelessWidget {
  const DashboardShimmerLoading({super.key});

  @override
  Widget build(BuildContext context) {
    final baseColor = Colors.grey[300]!;
    final highlightColor = Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header skeleton
            Row(
              children: [
                const CircleAvatar(radius: 28, backgroundColor: Colors.white),
                const SizedBox(width: AppSpacing.md),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 140, height: 16, color: Colors.white),
                    const SizedBox(height: AppSpacing.xs),
                    Container(width: 80, height: 12, color: Colors.white),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            // Giant Study Time card skeleton
            Container(
              width: double.infinity,
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppConstants.cardRadius),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Grid of 4 small cards skeleton
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: AppSpacing.md,
              crossAxisSpacing: AppSpacing.md,
              childAspectRatio: 1.3,
              children: List.generate(4, (_) => Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppConstants.cardRadius),
                ),
              )),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Quick actions title skeleton
            Container(width: 120, height: 18, color: Colors.white),
            const SizedBox(height: AppSpacing.md),

            // Quick actions buttons skeleton
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(3, (_) => Container(
                width: 100,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppConstants.buttonRadius),
                ),
              )),
            ),
          ],
        ),
      ),
    );
  }
}
