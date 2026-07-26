import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prep_tracker/features/auth/presentation/providers/auth_provider.dart';
import 'package:prep_tracker/shared/widgets/splash_screen_placeholder.dart';

/// ── Authentication Splash Screen ──
/// Initial launch view that triggers session restore checks.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  void _checkAuth() {
    // Post-frame callback to trigger the checkSession asynchronously after initial build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).checkSession();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show splash visual elements while running checkSession. GoRouter redirects
    // will take over routing as soon as state.isInitializing changes to false.
    return const SplashScreenPlaceholder();
  }
}
