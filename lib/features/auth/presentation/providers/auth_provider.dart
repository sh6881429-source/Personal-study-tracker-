import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:prep_tracker/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:prep_tracker/features/auth/domain/repositories/auth_repository.dart';
import 'package:prep_tracker/features/profile/data/models/profile_model.dart';
import 'package:prep_tracker/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:prep_tracker/features/profile/domain/repositories/profile_repository.dart';
import 'package:prep_tracker/core/services/device_token_service.dart';

/// ── Application Authentication State Class ──
@immutable
class AppAuthState {
  const AppAuthState({
    this.supabaseUser,
    this.profile,
    this.isLoading = false,
    this.isInitializing = true,
    this.errorMessage,
  });

  final User? supabaseUser;
  final ProfileModel? profile;
  final bool isLoading;
  final bool isInitializing;
  final String? errorMessage;

  bool get isAuthenticated => supabaseUser != null;

  AppAuthState copyWith({
    User? supabaseUser,
    ProfileModel? profile,
    bool? isLoading,
    bool? isInitializing,
    String? errorMessage,
    bool clearError = false,
    bool clearUser = false,
  }) {
    return AppAuthState(
      supabaseUser: clearUser ? null : (supabaseUser ?? this.supabaseUser),
      profile: clearUser ? null : (profile ?? this.profile),
      isLoading: isLoading ?? this.isLoading,
      isInitializing: isInitializing ?? this.isInitializing,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// ── Authentication Notifier ──
/// StateNotifier that handles all login, logout, session restoration, and database profile sync.
class AuthNotifier extends StateNotifier<AppAuthState> {
  AuthNotifier(this._authRepository, this._profileRepository)
      : super(const AppAuthState()) {
    _init();
  }

  final AuthRepository _authRepository;
  final ProfileRepository _profileRepository;
  StreamSubscription<AuthState>? _authSubscription;


  void _init() {
    // Listen to real-time auth changes from Supabase (e.g. auto login, token refresh, external sign-out)
    _authSubscription = _authRepository.authStateChanges.listen((data) async {
      final user = data.session?.user;
      if (user != null) {
        await _handleUserSignIn(user);
      } else {
        _handleUserSignOut();
      }
    });
  }

  /// Perform session checks on app startup.
  Future<void> checkSession() async {
    state = state.copyWith(isInitializing: true);
    try {
      final user = await _authRepository.restoreSession();
      if (user != null) {
        state = state.copyWith(
          supabaseUser: user,
          isInitializing: false,
        );
        // Start profile sync asynchronously in the background
        _handleUserSignIn(user);
      } else {
        state = state.copyWith(isInitializing: false);
      }
    } catch (e) {
      state = state.copyWith(
        isInitializing: false,
        errorMessage: 'Failed to restore session: $e',
      );
    }
  }

  /// Perform Google sign-in.
  Future<void> loginWithGoogle() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _authRepository.signInWithGoogle();
      if (user != null) {
        await _handleUserSignIn(user);
      } else {
        // On Web, returning null indicates OAuth redirection is in progress
        state = state.copyWith(isLoading: true);
      }
    } catch (e) {
      // Don't set error message if user cancelled sign in or redirect is occurring
      final errorMsg = e.toString();
      if (errorMsg.contains('cancelled') ||
          errorMsg.contains('canceled') ||
          errorMsg.contains('Redirecting') ||
          errorMsg.contains('redirecting')) {
        state = state.copyWith(isLoading: false);
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Authentication error: $e',
        );
      }
    }
  }

  /// Perform sign-out.
  Future<void> logout() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _authRepository.signOut();
      _handleUserSignOut();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Sign out failed: $e',
      );
    }
  }

  /// Clears current error message from state.
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Refresh current profile from database.
  Future<void> refreshProfile() async {
    final user = state.supabaseUser;
    if (user != null) {
      try {
        final profile = await _profileRepository.getProfile(user.id);
        if (profile != null) {
          state = state.copyWith(profile: profile);
        }
      } catch (_) {}
    }
  }

  /// Updates local profile model directly in state.
  void updateLocalProfile(ProfileModel updatedProfile) {
    state = state.copyWith(profile: updatedProfile);
  }

  Future<void> _handleUserSignIn(User user) async {
    try {
      // Sync Google user profile details with profiles database table
      final userMetadata = user.userMetadata ?? {};
      final name = userMetadata['full_name'] as String? ?? user.email?.split('@').first ?? 'User';
      final email = user.email ?? '';
      final photoUrl = userMetadata['avatar_url'] as String?;

      final profile = await _profileRepository.syncProfile(
        userId: user.id,
        name: name,
        email: email,
        photoUrl: photoUrl,
      );

      state = state.copyWith(
        supabaseUser: user,
        profile: profile,
        isLoading: false,
        isInitializing: false,
      );

      // Register device token in Supabase user_device_tokens table (CorePush architecture)
      unawaited(DeviceTokenService.registerUserDeviceToken(user.id));
    } catch (e) {
      state = state.copyWith(
        supabaseUser: user,
        isLoading: false,
        isInitializing: false,
        errorMessage: 'Failed to synchronize profile data: $e',
      );
    }
  }

  void _handleUserSignOut() {
    state = state.copyWith(
      clearUser: true,
      isLoading: false,
      isInitializing: false,
    );
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

/// Provider for AuthNotifier.
final authProvider = StateNotifierProvider<AuthNotifier, AppAuthState>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  final profileRepo = ref.watch(profileRepositoryProvider);
  return AuthNotifier(authRepo, profileRepo);
});
