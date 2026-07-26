import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prep_tracker/core/config/app_config.dart';
import 'package:prep_tracker/core/theme/app_theme.dart';
import 'package:prep_tracker/core/theme/theme_provider.dart';
import 'package:prep_tracker/core/router/app_router.dart';

/// ── App Entry Point Widget ──
/// Integrates State Management (Riverpod), Routing (GoRouter), and Custom Neo Brutalism Theming.
class PrepTrackerApp extends ConsumerWidget {
  const PrepTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      themeMode: themeMode,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
    );
  }
}
