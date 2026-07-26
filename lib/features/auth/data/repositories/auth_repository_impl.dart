import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:prep_tracker/core/services/supabase_service.dart';
import 'package:prep_tracker/features/auth/data/services/auth_service.dart';
import 'package:prep_tracker/features/auth/domain/repositories/auth_repository.dart';

/// Provider for AuthService.
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Provider for AuthRepository implementation.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final service = ref.watch(authServiceProvider);
  return AuthRepositoryImpl(service);
});

/// ── Authentication Repository Implementation ──
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._service);

  final AuthService _service;
  SupabaseClient get _supabase => SupabaseService.client;

  @override
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  @override
  User? get currentUser => _supabase.auth.currentUser;

  @override
  Session? get currentSession => _supabase.auth.currentSession;

  @override
  Future<User?> signInWithGoogle() async {
    final response = await _service.signInWithGoogle();
    return response.user;
  }

  @override
  Future<void> signOut() async {
    await _service.signOut();
  }

  @override
  Future<User?> restoreSession() async {
    try {
      final session = _supabase.auth.currentSession;
      if (session != null && !session.isExpired) {
        return _supabase.auth.currentUser;
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
