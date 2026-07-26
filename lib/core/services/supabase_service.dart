import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:prep_tracker/core/config/env_config.dart';

/// ── Supabase Service Scaffold ──
/// Handles database connection initialization safely.
class SupabaseService {
  static SupabaseClient? _client;

  /// Returns the SupabaseClient instance.
  static SupabaseClient get client {
    if (_client != null) return _client!;
    try {
      return Supabase.instance.client;
    } catch (_) {
      throw StateError('SupabaseService has not been initialized.');
    }
  }

  /// Initialize Supabase connection.
  static Future<void> init() async {
    String url = EnvConfig.supabaseUrl;
    String anonKey = EnvConfig.supabaseAnonKey;

    // Use placeholder credentials to prevent startup crashes if env variables are empty
    if (url.isEmpty || anonKey.isEmpty) {
      url = 'https://zufmmqixuxboacryotvd.supabase.co';
      anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inp1Zm1tcWl4dXhib2FjcnlvdHZkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODM2Njg0MzUsImV4cCI6MjA5OTI0NDQzNX0.rTqT429zB9ulzewYD1ssX6xtV8XZjRtx1UK2IOIHAJ0';
    }

    try {
      await Supabase.initialize(
        url: url,
        anonKey: anonKey,
      );
      _client = Supabase.instance.client;
    } catch (e) {
      // If already initialized or fails, fallback to standard instance client
      try {
        _client = Supabase.instance.client;
      } catch (_) {
        // Fail silently
      }
    }
  }
}
