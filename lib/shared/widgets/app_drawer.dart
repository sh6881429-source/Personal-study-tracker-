import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:prep_tracker/core/constants/app_colors.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentRoute = GoRouterState.of(context).uri.path;

    return Drawer(
      width: 310,
      backgroundColor: const Color(0xFFFAF6E8),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        side: BorderSide(color: AppColors.border, width: 3),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Drawer Header Banner
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD93D), // Accent Yellow
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border, width: 3),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.shadow,
                      offset: Offset(3.5, 3.5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PrepTracker',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'All-in-One Revision & Gym Tracker',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Drawer Items Scroll List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _DrawerItem(
                    icon: Icons.home_rounded,
                    label: 'Dashboard',
                    route: '/home',
                    active: currentRoute == '/home',
                    color: const Color(0xFFBAE6FD), // Sky Blue
                  ),
                  _DrawerItem(
                    icon: Icons.timer_rounded,
                    label: 'Study Focus Timer',
                    route: '/study',
                    active: currentRoute == '/study',
                    color: const Color(0xFFC7D2FE), // Indigo
                  ),
                  _DrawerItem(
                    icon: Icons.menu_book_rounded,
                    label: 'Syllabus Tracker',
                    route: '/syllabus',
                    active: currentRoute == '/syllabus',
                    color: const Color(0xFFFFD93D), // Yellow
                  ),
                  _DrawerItem(
                    icon: Icons.bookmark_rounded,
                    label: 'Sticky Notes (Bookmarks)',
                    route: '/bookmark',
                    active: currentRoute == '/bookmark',
                    color: const Color(0xFFFF8EAF), // Pink / Rose
                  ),
                  _DrawerItem(
                    icon: Icons.picture_as_pdf_rounded,
                    label: 'PDF Library',
                    route: '/pdf',
                    active: currentRoute == '/pdf',
                    color: const Color(0xFFFED7AA), // Orange
                  ),
                  const Divider(color: AppColors.border, thickness: 2.5, height: 24),
                  _DrawerItem(
                    icon: Icons.fitness_center_rounded,
                    label: 'Gym Tracker',
                    route: '/gym',
                    active: currentRoute == '/gym',
                    color: const Color(0xFFFFE4E6), // Gym Light Pink
                  ),
                  _DrawerItem(
                    icon: Icons.bar_chart_rounded,
                    label: 'Analytics Dashboard',
                    route: '/analytics',
                    active: currentRoute == '/analytics',
                    color: const Color(0xFFE5E7EB),
                  ),
                  _DrawerItem(
                    icon: Icons.person_rounded,
                    label: 'Streaks & Profile',
                    route: '/profile',
                    active: currentRoute == '/profile',
                    color: const Color(0xFFE5E7EB),
                  ),
                  _DrawerItem(
                    icon: Icons.settings_rounded,
                    label: 'Settings',
                    route: '/settings',
                    active: currentRoute == '/settings',
                    color: const Color(0xFFE5E7EB),
                  ),
                  _DrawerItem(
                    icon: Icons.smart_toy_rounded,
                    label: 'Ask Yash Bot (AI)',
                    route: '/ask-yash',
                    active: currentRoute == '/ask-yash',
                    color: const Color(0xFFE5E7EB),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.active,
    required this.color,
    this.tag,
  });

  final IconData icon;
  final String label;
  final String route;
  final bool active;
  final Color color;
  final String? tag;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: active ? color : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 2.5),
        boxShadow: active
            ? const [
                BoxShadow(
                  color: AppColors.shadow,
                  offset: Offset(2.5, 2.5),
                )
              ]
            : const [
                BoxShadow(
                  color: AppColors.shadow,
                  offset: Offset(1.5, 1.5),
                )
              ],
      ),
      child: ListTile(
        visualDensity: VisualDensity.compact,
        leading: Icon(icon, color: AppColors.text, size: 20),
        title: Text(
          label,
          style: GoogleFonts.poppins(
            fontWeight: active ? FontWeight.w900 : FontWeight.w800,
            fontSize: 13,
            color: AppColors.text,
          ),
        ),
        trailing: tag != null
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: tag == 'Built' ? const Color(0xFF34D399) : const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border, width: 1.5),
                ),
                child: Text(
                  tag!,
                  style: GoogleFonts.poppins(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    color: AppColors.text,
                  ),
                ),
              )
            : const Icon(Icons.chevron_right_rounded, size: 18),
        onTap: () {
          Navigator.pop(context);
          context.go(route);
        },
      ),
    );
  }
}
