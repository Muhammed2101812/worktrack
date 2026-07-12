import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';

final authServiceProvider = Provider((ref) => AuthService());

final currentUserProvider = Provider<User?>((ref) {
  return Supabase.instance.client.auth.currentUser;
});

/// Translates a Supabase auth exception message into a user-friendly Turkish
/// string. Falls back to a generic message when the message is unknown.
String friendlyAuthError(Object e) {
  final msg = e.toString().toLowerCase();
  if (msg.contains('invalid login credentials')) {
    return 'E-posta veya şifre hatalı.';
  }
  if (msg.contains('email not confirmed')) {
    return 'E-posta adresiniz henüz doğrulanmamış. Lütfen gelen kutunuzu kontrol edin.';
  }
  if (msg.contains('user already registered')) {
    return 'Bu e-posta adresi zaten kayıtlı.';
  }
  if (msg.contains('password should be at least')) {
    return 'Şifre en az 6 karakter olmalıdır.';
  }
  if (msg.contains('unable to validate email address')) {
    return 'Geçersiz e-posta adresi.';
  }
  if (msg.contains('rate limit') || msg.contains('too many')) {
    return 'Çok fazla deneme yapıldı. Lütfen biraz bekleyin.';
  }
  if (msg.contains('networkrequestfailed') || msg.contains('socket') || msg.contains('network')) {
    return 'Bağlantı hatası. İnternet bağlantınızı kontrol edin.';
  }
  // Fallback: strip the exception prefix for a cleaner message.
  return 'İşlem başarısız: ${e.toString().replaceFirst('Exception: ', '')}';
}

class AuthNotifier extends Notifier<User?> {
  StreamSubscription<AuthState>? _sub;

  @override
  User? build() {
    // Keep state in sync with external auth changes (OAuth redirect,
    // token refresh, sign-out from another device, email confirmation, etc.).
    try {
      _sub = Supabase.instance.client.auth.onAuthStateChange.listen((state) {
        final user = state.session?.user;
        if (this.state?.id != user?.id) {
          this.state = user;
        }
      });
      ref.onDispose(() => _sub?.cancel());
    } catch (e) {
      debugPrint('AuthNotifier: onAuthStateChange unavailable ($e)');
    }
    return Supabase.instance.client.auth.currentUser;
  }

  Future<void> signIn(String email, String password) async {
    await ref.read(authServiceProvider).signIn(email, password);
    state = Supabase.instance.client.auth.currentUser;
  }

  Future<void> signUp(String email, String password) async {
    await ref.read(authServiceProvider).signUp(email, password);
    state = Supabase.instance.client.auth.currentUser;
  }

  Future<void> signInWithGoogle() async {
    await ref.read(authServiceProvider).signInWithGoogle();
    state = Supabase.instance.client.auth.currentUser;
  }

  Future<void> signOut() async {
    await ref.read(authServiceProvider).signOut();
    state = null;
  }
}

final authNotifierProvider = NotifierProvider<AuthNotifier, User?>(AuthNotifier.new);
