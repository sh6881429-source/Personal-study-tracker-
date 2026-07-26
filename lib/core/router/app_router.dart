import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prep_tracker/shared/widgets/app_bottom_nav.dart';

// Import Auth screens & providers
import 'package:prep_tracker/features/auth/presentation/screens/splash_screen.dart';
import 'package:prep_tracker/features/auth/presentation/screens/login_screen.dart';
import 'package:prep_tracker/features/auth/presentation/providers/auth_provider.dart';

// Import Feature screens
import 'package:prep_tracker/features/home/presentation/screens/home_screen.dart';
import 'package:prep_tracker/features/study/presentation/screens/study_screen.dart';
import 'package:prep_tracker/features/study/presentation/screens/goal_config_screen.dart';
import 'package:prep_tracker/features/study/presentation/screens/study_history_screen.dart';
import 'package:prep_tracker/features/study/presentation/screens/study_reports_screen.dart';
import 'package:prep_tracker/features/syllabus/presentation/screens/syllabus_screen.dart';
import 'package:prep_tracker/features/gym/presentation/screens/gym_screen.dart';
import 'package:prep_tracker/features/profile/presentation/screens/profile_screen.dart';
import 'package:prep_tracker/features/bookmark/presentation/screens/bookmark_screen.dart';
import 'package:prep_tracker/features/pdf/presentation/screens/pdf_screen.dart';
import 'package:prep_tracker/features/analytics/presentation/screens/analytics_screen.dart';
import 'package:prep_tracker/features/settings/presentation/screens/settings_screen.dart';
import 'package:prep_tracker/features/ask_yash_bot/presentation/screens/ask_yash_bot_screen.dart';
import 'package:prep_tracker/features/reminders/presentation/screens/reminders_screen.dart';

/// Global navigator key for full-screen dialogs and overlays.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

/// Shell navigator key for navigation tabs.
final GlobalKey<NavigatorState> shellNavigatorKey = GlobalKey<NavigatorState>();

/// ── GoRouter Stream Listenable Bridge ──
/// Converts a Dart Stream (like Riverpod notifier stream) into a Listenable for GoRouter.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen(
          (dynamic _) => notifyListeners(),
        );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

/// ── App Router Configuration ──
/// Handles route mappings, splash routing, and authenticating Route Guards.
final routerProvider = Provider<GoRouter>((ref) {
  final authStream = ref.watch(authProvider.notifier).stream;

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: GoRouterRefreshStream(authStream),
    routes: [
      // ── Public Launch Routes ──
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),

      // ── Shell Route for bottom navigation (Protected) ──
      ShellRoute(
        navigatorKey: shellNavigatorKey,
        builder: (context, state, child) {
          return AppBottomNav(child: child);
        },
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/study',
            builder: (context, state) => const StudyScreen(),
          ),
          GoRoute(
            path: '/syllabus',
            builder: (context, state) => const SyllabusScreen(),
          ),
          GoRoute(
            path: '/gym',
            builder: (context, state) => const GymScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),

      // ── Full-screen protected routes ──
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/bookmark',
        builder: (context, state) => const BookmarkScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/pdf',
        builder: (context, state) => const PdfScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/analytics',
        builder: (context, state) {
          final tabParam = state.uri.queryParameters['tab'];
          int initialTab = 0;
          if (tabParam == 'consistency' || tabParam == '1') {
            initialTab = 1;
          } else if (tabParam == 'achievements' || tabParam == '4') {
            initialTab = 4;
          } else if (tabParam == 'study' || tabParam == '2') {
            initialTab = 2;
          } else if (tabParam == 'gym' || tabParam == '3') {
            initialTab = 3;
          }
          return AnalyticsScreen(initialTabIndex: initialTab);
        },
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/ask-yash',
        builder: (context, state) => const AskYashBotScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/reminders',
        builder: (context, state) => const RemindersScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/study/goals',
        builder: (context, state) => const GoalConfigScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/study/history',
        builder: (context, state) => const StudyHistoryScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/study/reports',
        builder: (context, state) => const StudyReportsScreen(),
      ),
    ],
    // ── Auth Route Guard Redirect ──
    redirect: (context, state) {
      final authState = ref.read(authProvider);

      // 1. If still checking persisted sessions on splash, do not redirect
      if (authState.isInitializing) {
        return null;
      }

      final isOnSplash = state.uri.path == '/splash';
      final isOnLogin = state.uri.path == '/login';

      // 2. User is authenticated
      if (authState.isAuthenticated) {
        if (isOnSplash || isOnLogin) {
          return '/home';
        }
        return null;
      }

      // 3. User is unauthenticated
      if (!isOnLogin && !isOnSplash) {
        return '/login';
      }

      // If user is unauthenticated and session restore completed, redirect from splash to login
      if (isOnSplash) {
        return '/login';
      }

      return null;
    },
  );
});
