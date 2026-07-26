import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:prep_tracker/core/services/supabase_service.dart';

/// ── Authentication Low-Level Service ──
/// Directly interfaces with google_sign_in package and Supabase Auth client.
class AuthService {
  SupabaseClient get _supabase => SupabaseService.client;

  /// Returns the GoogleSignIn configuration based on the target platform.
  GoogleSignIn _getGoogleSignIn() {
    return GoogleSignIn(
      scopes: [
        'email',
        'profile',
      ],
    );
  }

  /// Performs Google OAuth.
  /// On mobile, uses native GoogleSignIn and resolves through `signInWithIdToken`.
  /// On web, triggers redirect-based OAuth login without throwing dummy redirect exceptions.
  Future<AuthResponse> signInWithGoogle() async {
    if (kIsWeb) {
      // Web: Use redirect OAuth via Supabase
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kDebugMode
            ? 'http://localhost:5000'
            : 'https://preptracker.pages.dev', // Cloudflare Pages URL
      );
      // Return empty response as OAuth redirect takes over page navigation
      return AuthResponse();
    } else {
      // Mobile (Android / iOS): Use native SDK
      final googleSignIn = _getGoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        throw Exception('Sign in cancelled by user');
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        throw Exception('No ID token found from Google Authentication.');
      }

      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: googleAuth.accessToken,
      );

      return response;
    }
  }

  /// Signs out current authenticated user session.
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}
