import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:prep_tracker/core/constants/app_colors.dart';
import 'package:prep_tracker/core/constants/app_constants.dart';
import 'package:prep_tracker/core/constants/app_spacing.dart';
import 'package:prep_tracker/features/ask_yash_bot/presentation/widgets/floating_yash_bot_launcher.dart';
import 'package:prep_tracker/features/ask_yash_bot/presentation/widgets/floating_chat_overlay.dart';

/// ── Bottom Navigation Shell ──
/// Matches the reference bottom navigation bar design 99% visually.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key, required this.child});

  final Widget child;

  static const _tabs = <_NavTab>[
    _NavTab(label: 'Home', icon: Icons.home_outlined, path: '/home'),
    _NavTab(label: 'Study', icon: Icons.menu_book_rounded, path: '/study'),
    _NavTab(label: 'Gym', icon: Icons.fitness_center_rounded, path: '/gym'),
    _NavTab(label: 'Progress', icon: Icons.insert_chart_outlined, path: '/syllabus'),
    _NavTab(label: 'Profile', icon: Icons.person_outline_rounded, path: '/profile'),
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    for (int i = 0; i < _tabs.length; i++) {
      if (location.startsWith(_tabs[i].path)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final activeIndex = _currentIndex(context);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF6E8), // Warm beige background
      body: Stack(
        children: [
          child,
          const FloatingYashBotLauncher(),
          const FloatingChatOverlay(),
        ],
      ),
      bottomNavigationBar: Container(
        height: 64,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(
              color: AppColors.border,
              width: 3.0,
            ),
          ),
        ),
        child: Row(
          children: List.generate(_tabs.length, (index) {
            final tab = _tabs[index];
            final isActive = index == activeIndex;

            return Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFFFFD93D) : Colors.white,
                  border: index < _tabs.length - 1
                      ? const Border(
                          right: BorderSide(
                            color: AppColors.border,
                            width: 1.5,
                          ),
                        )
                      : null,
                ),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (!isActive) context.go(tab.path);
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        tab.icon,
                        size: 22,
                        color: AppColors.text,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tab.label,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: AppColors.text,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _NavTab {
  const _NavTab({
    required this.label,
    required this.icon,
    required this.path,
  });

  final String label;
  final IconData icon;
  final String path;
}
