import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../core/constants.dart';

class AuthService {
  final SupabaseClient _client;

  AuthService({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  Future<void> signIn(String email, String password) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signUp(String email, String password) async {
    await _client.auth.signUp(email: email, password: password);
  }

  Future<void> signInWithGoogle() async {
    if (kIsWeb) {
      await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: Uri.base.toString(),
      );
      return;
    }

    final googleSignIn = GoogleSignIn(
      serverClientId: AppConstants.googleServerClientId,
      scopes: ['email'],
    );
    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) return;

    final googleAuth = await googleUser.authentication;
    final accessToken = googleAuth.accessToken;
    final idToken = googleAuth.idToken;

    if (idToken == null) {
      throw Exception('No ID Token found.');
    }

    await _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );
  }

  Future<void> signOut() async => await _client.auth.signOut();

  /// Sends a password-reset email to [email]. Supabase will email a link the
  /// user can follow to set a new password.
  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  User? getCurrentUser() => _client.auth.currentUser;
}
