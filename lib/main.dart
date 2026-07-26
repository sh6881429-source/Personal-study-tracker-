import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prep_tracker/app.dart';
import 'package:prep_tracker/core/config/env_config.dart';
import 'package:prep_tracker/core/services/storage_service.dart';
import 'package:prep_tracker/core/services/supabase_service.dart';

void main() async {
  // Ensure Flutter engine bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize configuration & local/cloud services asynchronously with error handling
  try {
    await EnvConfig.init();
  } catch (e) {
    debugPrint('EnvConfig initialization failed: $e');
  }

  try {
    await StorageService.init();
  } catch (e) {
    debugPrint('StorageService initialization failed: $e');
  }

  try {
    await SupabaseService.init();
  } catch (e) {
    debugPrint('SupabaseService initialization failed: $e');
  }

  // Run the application wrapped in Riverpod ProviderScope
  runApp(
    const ProviderScope(
      child: PrepTrackerApp(),
    ),
  );
}
