import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:prep_tracker/core/constants/app_colors.dart';
import 'package:prep_tracker/features/auth/presentation/providers/auth_provider.dart';
import 'package:prep_tracker/features/profile/presentation/providers/profile_provider.dart';
import 'package:prep_tracker/features/profile/data/services/profile_service.dart';
import 'package:prep_tracker/features/gym/presentation/providers/gym_provider.dart';
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

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isUploadingImage = false;

  Future<void> _pickAndUploadImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;
      final file = result.files.single;
      final bytes = file.bytes;
      if (bytes == null) {
        if (mounted) AppSnackbar.showError(context, 'Could not read image file. Please choose another photo.');
        return;
      }

      final ext = file.extension?.toLowerCase() ?? 'jpg';
      if (!ProfileService.supportedExtensions.contains(ext)) {
        if (mounted) AppSnackbar.showError(context, 'Unsupported image format (.$ext). Please select a JPG, PNG, or WEBP image.');
        return;
      }

      setState(() => _isUploadingImage = true);

      final authState = ref.read(authProvider);
      final userId = authState.profile?.userId ?? authState.supabaseUser?.id ?? '';
      if (userId.isEmpty) {
        if (mounted) AppSnackbar.showError(context, 'User session expired. Please sign in again.');
        return;
      }

      debugPrint('📸 [ProfileScreen] Selected file: ${file.name} ($ext, ${bytes.length} bytes)');

      // Step 5 & 6: Upload to Storage & Get Cache-Busted Public URL
      final profileService = ProfileService();
      final photoUrl = await profileService.uploadAvatar(userId, bytes, ext);

      // Step 7: Update Profiles table in Supabase DB
      await profileService.updateProfileRow(userId, {
        'photo_url': photoUrl,
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Step 9: Evict Flutter Image Cache so old image is not retained in memory
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();

      // Step 8: Update Riverpod state immediately
      if (authState.profile != null) {
        final updated = authState.profile!.copyWith(
          photoUrl: photoUrl,
          updatedAt: DateTime.now(),
        );
        ref.read(authProvider.notifier).updateLocalProfile(updated);
      }

      ref.invalidate(profileStatsProvider);

      if (mounted) {
        AppSnackbar.showSuccess(context, 'Profile picture updated successfully!');
      }
    } catch (e) {
      debugPrint('❌ [ProfileScreen] Profile picture upload error: $e');
      if (mounted) {
        AppSnackbar.showError(context, 'Failed to upload picture: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingImage = false);
      }
    }
  }

  Future<void> _removeImage() async {
    try {
      final authState = ref.read(authProvider);
      final userId = authState.profile?.userId ?? authState.supabaseUser?.id ?? '';
      if (userId.isEmpty) return;

      setState(() => _isUploadingImage = true);

      // Instant local state update
      if (authState.profile != null) {
        final updated = authState.profile!.copyWith(
          photoUrl: null,
          updatedAt: DateTime.now(),
        );
        ref.read(authProvider.notifier).updateLocalProfile(updated);
      }

      if (mounted) {
        AppSnackbar.showSuccess(context, 'Profile picture removed.');
      }

      // Background remote sync
      try {
        final profileService = ProfileService();
        await profileService.removeAvatar(userId);
        ref.invalidate(profileStatsProvider);
      } catch (_) {}
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(context, 'Failed to remove picture: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingImage = false);
      }
    }
  }

  void _showImageOptions() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: isDark ? const Color(0xFF262626) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final textColor = isDark ? Colors.white : AppColors.text;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Profile Picture',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.photo_library_rounded, color: AppColors.primary),
                  title: Text('Upload Image File', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: textColor)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickAndUploadImage();
                  },
                ),
                if (ref.watch(authProvider).profile?.photoUrl != null)
                  ListTile(
                    leading: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                    title: Text('Remove Photo', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.error)),
                    onTap: () {
                      Navigator.pop(ctx);
                      _removeImage();
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInitialsFallback(String name, Color textColor) {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    String initials = 'P';
    if (parts.length >= 2) {
      initials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty) {
      initials = parts[0][0].toUpperCase();
    }

    return Container(
      color: AppColors.primary.withValues(alpha: 0.15),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: GoogleFonts.poppins(
          fontSize: 24,
          fontWeight: FontWeight.w900,
          color: AppColors.primary,
        ),
      ),
    );
  }

  void _showEditProfileDialog() {
    final authState = ref.read(authProvider);
    final currentName = authState.profile?.name ?? '';
    final currentUsername = authState.profile?.username ?? '';
    final currentBio = authState.profile?.bio ?? '';

    final nameController = TextEditingController(text: currentName);
    final usernameController = TextEditingController(text: currentUsername);
    final bioController = TextEditingController(text: currentBio);
    final formKey = GlobalKey<FormState>();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.text;

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF262626) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: isDark ? Colors.white : AppColors.border, width: 3),
        ),
        title: Text(
          'Edit Profile',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w900, color: textColor),
        ),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  style: GoogleFonts.inter(color: textColor, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    labelText: 'Full Name *',
                    labelStyle: GoogleFonts.inter(color: textColor.withValues(alpha: 0.7)),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: usernameController,
                  style: GoogleFonts.inter(color: textColor),
                  decoration: InputDecoration(
                    labelText: 'Username (Optional)',
                    labelStyle: GoogleFonts.inter(color: textColor.withValues(alpha: 0.7)),
                    prefixText: '@',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: bioController,
                  style: GoogleFonts.inter(color: textColor),
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Bio (Optional)',
                    labelStyle: GoogleFonts.inter(color: textColor.withValues(alpha: 0.7)),
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
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              final userId = authState.profile?.userId ?? authState.supabaseUser?.id ?? '';
              final newName = nameController.text.trim();
              final newUsername = usernameController.text.trim().isEmpty ? null : usernameController.text.trim();
              final newBio = bioController.text.trim().isEmpty ? null : bioController.text.trim();

              // Instant local state update
              if (authState.profile != null) {
                final updated = authState.profile!.copyWith(
                  name: newName,
                  username: newUsername,
                  bio: newBio,
                  updatedAt: DateTime.now(),
                );
                ref.read(authProvider.notifier).updateLocalProfile(updated);
              }

              Navigator.pop(ctx);
              if (mounted) {
                AppSnackbar.showSuccess(context, 'Profile updated successfully!');
              }

              // Background remote database sync
              if (userId.isNotEmpty) {
                try {
                  final profileService = ProfileService();
                  await profileService.updateProfileRow(userId, {
                    'name': newName,
                    'username': newUsername,
                    'bio': newBio,
                    'updated_at': DateTime.now().toIso8601String(),
                  });
                  ref.invalidate(profileStatsProvider);
                } catch (_) {}
              }
            },
            child: Text('Save', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final statsAsync = ref.watch(profileStatsProvider);
    final gymStats = ref.watch(gymStatsProvider).value;
    final gymStreak = gymStats?.currentStreak ?? 0;

    final name = authState.profile?.name ?? 'Yash';
    final email = authState.profile?.email ?? authState.supabaseUser?.email ?? 'yash@example.com';
    final photoUrl = authState.profile?.photoUrl;
    final username = authState.profile?.username;
    final bio = authState.profile?.bio;
    
    final createdDate = authState.profile?.createdAt ?? DateTime.now();
    final memberSince = DateFormat('MMMM yyyy').format(createdDate);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.text;
    final secondaryTextColor = isDark ? Colors.grey.shade400 : AppColors.textSecondary;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'My Profile',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: textColor,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF262626) : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: isDark ? Colors.white : AppColors.border, width: 2),
              ),
              child: IconButton(
                icon: Icon(Icons.settings_rounded, color: textColor),
                onPressed: () => context.push('/settings'),
              ),
            ),
          ),
        ],
      ),
      body: statsAsync.when(
        loading: () => const _ProfileShimmerLoading(),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
              const SizedBox(height: 8),
              Text(
                'Failed to load stats: $err',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: textColor),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.refresh(profileStatsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (stats) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(profileStatsProvider);
            },
            color: AppColors.primary,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── 1. Profile Header Card ──
                      Container(
                        decoration: _brutalDecoration(context, const Color(0xFFFFD93D), darkBgColor: const Color(0xFF332B00)),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                // Avatar with camera overlay
                                GestureDetector(
                                  onTap: _showImageOptions,
                                  child: Stack(
                                    children: [
                                      Container(
                                        width: 72,
                                        height: 72,
                                        decoration: BoxDecoration(
                                          color: isDark ? const Color(0xFF262626) : Colors.white,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: isDark ? Colors.white : AppColors.border, width: 3),
                                          boxShadow: const [
                                            BoxShadow(
                                              color: AppColors.shadow,
                                              offset: Offset(2, 2),
                                            )
                                          ],
                                        ),
                                        child: ClipOval(
                                          child: _isUploadingImage
                                              ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                                              : (photoUrl != null && photoUrl.isNotEmpty)
                                                  ? Image.network(
                                                      photoUrl,
                                                      fit: BoxFit.cover,
                                                      width: 72,
                                                      height: 72,
                                                      errorBuilder: (_, __, ___) => _buildInitialsFallback(name, textColor),
                                                    )
                                                  : _buildInitialsFallback(name, textColor),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary,
                                            shape: BoxShape.circle,
                                            border: Border.all(color: Colors.white, width: 2),
                                          ),
                                          child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 14),
                                // User Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              name,
                                              style: GoogleFonts.poppins(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w900,
                                                color: textColor,
                                                height: 1.2,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.edit_note_rounded, size: 22),
                                            color: AppColors.primary,
                                            tooltip: 'Edit Profile',
                                            onPressed: _showEditProfileDialog,
                                          ),
                                        ],
                                      ),
                                      if (username != null && username.isNotEmpty)
                                        Text(
                                          '@$username',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      Text(
                                        email,
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: secondaryTextColor,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Member since $memberSince',
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: textColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (bio != null && bio.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.black26 : Colors.white54,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  bio,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                    color: textColor,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── 2. Streaks Row ──
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: _brutalDecoration(context, const Color(0xFFFB923C), darkBgColor: const Color(0xFF5C2900)),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              child: Row(
                                children: [
                                  _iconBadge(context, Icons.local_fire_department_rounded, const Color(0xFFEA580C)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Study Streak',
                                          style: GoogleFonts.inter(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w800,
                                            color: textColor,
                                          ),
                                        ),
                                        Text(
                                          '${stats.totalStudySessions} Days',
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w900,
                                            color: textColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              decoration: _brutalDecoration(context, const Color(0xFFFF8EAF), darkBgColor: const Color(0xFF5C0020)),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              child: Row(
                                children: [
                                  _iconBadge(context, Icons.emoji_events_rounded, const Color(0xFFE11D48)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Gym Streak',
                                          style: GoogleFonts.inter(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w800,
                                            color: textColor,
                                          ),
                                        ),
                                        Text(
                                          '$gymStreak Days',
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w900,
                                            color: textColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ── 3. Stats Dashboard Section Title ──
                      Text(
                        'Personal Dashboard',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Responsive Stats Grid Layout
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final width = constraints.maxWidth;
                          int columns = 2;
                          double aspectRatio = 1.4;

                          if (width >= 600 && width < 900) {
                            columns = 3;
                            aspectRatio = 1.5;
                          } else if (width >= 900) {
                            columns = 4;
                            aspectRatio = 1.5;
                          }

                          return GridView.count(
                            crossAxisCount: columns,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: aspectRatio,
                            children: [
                              _StatItemCard(
                                title: 'Total Study Hours',
                                value: '${stats.totalStudyHours.toStringAsFixed(1)} h',
                                lightColor: const Color(0xFFC7D2FE),
                                darkColor: const Color(0xFF1E293B),
                                icon: Icons.hourglass_empty_rounded,
                                iconColor: const Color(0xFF5B5FEF),
                              ),
                              _StatItemCard(
                                title: 'Total Sessions',
                                value: '${stats.totalStudySessions}',
                                lightColor: const Color(0xFF93C5FD),
                                darkColor: const Color(0xFF1E3A8A),
                                icon: Icons.timer_rounded,
                                iconColor: Colors.blue.shade700,
                              ),
                              _StatItemCard(
                                title: 'Subjects Created',
                                value: '${stats.subjectsCreated}',
                                lightColor: const Color(0xFF86EFAC),
                                darkColor: const Color(0xFF14532D),
                                icon: Icons.subject_rounded,
                                iconColor: const Color(0xFF15803D),
                              ),
                              _StatItemCard(
                                title: 'Revision Progress',
                                value: '${stats.revisionProgress.toStringAsFixed(0)}%',
                                lightColor: const Color(0xFFFFE599),
                                darkColor: const Color(0xFF78350F),
                                icon: Icons.published_with_changes_rounded,
                                iconColor: const Color(0xFFD97706),
                              ),
                              _StatItemCard(
                                title: 'Completed Chapters',
                                value: '${stats.completedChapters}',
                                lightColor: const Color(0xFFA5F3FC),
                                darkColor: const Color(0xFF164E63),
                                icon: Icons.checklist_rounded,
                                iconColor: Colors.cyan.shade800,
                              ),
                              _StatItemCard(
                                title: 'Pending Chapters',
                                value: '${stats.pendingChapters}',
                                lightColor: const Color(0xFFFCA5A5),
                                darkColor: const Color(0xFF7F1D1D),
                                icon: Icons.pending_actions_rounded,
                                iconColor: Colors.red.shade700,
                              ),
                              _StatItemCard(
                                title: 'Gym Attendance',
                                value: '${stats.gymAttendancePercentage.toStringAsFixed(0)}%',
                                lightColor: const Color(0xFFFFC0CB),
                                darkColor: const Color(0xFF831843),
                                icon: Icons.fitness_center_rounded,
                                iconColor: const Color(0xFFE11D48),
                              ),
                              _StatItemCard(
                                title: 'This Month Study',
                                value: '${stats.currentMonthStudyHours.toStringAsFixed(1)} h',
                                lightColor: const Color(0xFFE9D5FF),
                                darkColor: const Color(0xFF581C87),
                                icon: Icons.calendar_month_rounded,
                                iconColor: Colors.purple.shade700,
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StatItemCard extends StatelessWidget {
  const _StatItemCard({
    required this.title,
    required this.value,
    required this.lightColor,
    required this.darkColor,
    required this.icon,
    required this.iconColor,
  });

  final String title;
  final String value;
  final Color lightColor;
  final Color darkColor;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.text;

    return Container(
      decoration: _brutalDecoration(context, lightColor, darkBgColor: darkColor),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _iconBadge(context, icon, iconColor),
            ],
          ),
          const Spacer(),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Shimmer loader layout for Profile Stats
class _ProfileShimmerLoading extends StatelessWidget {
  const _ProfileShimmerLoading();

  @override
  Widget build(BuildContext context) {
    final baseColor = Colors.grey.shade300;
    final highlightColor = Colors.grey.shade100;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 96,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(width: 150, height: 20, color: Colors.white),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: List.generate(
                8,
                (index) => Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
