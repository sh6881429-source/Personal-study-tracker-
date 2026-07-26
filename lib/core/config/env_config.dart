import 'package:flutter_dotenv/flutter_dotenv.dart';

/// ── Environment Configuration ──
/// Loads environment variables from the `.env` file at root.
abstract final class EnvConfig {
  static Future<void> init() async {
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {
      // Fallback if env file doesn't exist or failed to load
    }
  }

  static String get supabaseUrl => dotenv.get('SUPABASE_URL', fallback: '');
  static String get supabaseAnonKey => dotenv.get('SUPABASE_ANON_KEY', fallback: '');
  static String get geminiApiKey => dotenv.get('GEMINI_API_KEY', fallback: '');
}
