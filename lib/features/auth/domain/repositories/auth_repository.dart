import 'package:supabase_flutter/supabase_flutter.dart';

/// ── Authentication Repository Interface ──
/// Defines Google OAuth flow and auth state operations.
abstract interface class AuthRepository {
  /// Stream of Supabase Auth state changes (user sign-in, sign-out, etc.).
  Stream<AuthState> get authStateChanges;

  /// Retrieves the currently authenticated Supabase User, if any.
  User? get currentUser;

  /// Retrieves the current active session.
  Session? get currentSession;

  /// Signs in the user using Google OAuth.
  /// Uses native Google Sign In where available, falling back to OAuth redirection on Web.
  Future<User?> signInWithGoogle();

  /// Signs out the current user from both Google and Supabase.
  Future<void> signOut();

  /// Checks if there is a valid persisted session and attempts to restore it.
  Future<User?> restoreSession();
}
