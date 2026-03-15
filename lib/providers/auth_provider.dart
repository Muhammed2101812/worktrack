import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';

final authServiceProvider = Provider((ref) => AuthService());

final currentUserProvider = Provider<User?>((ref) {
  return Supabase.instance.client.auth.currentUser;
});

class AuthNotifier extends Notifier<User?> {
  @override
  User? build() => Supabase.instance.client.auth.currentUser;

  Future<void> signIn(String email, String password) async {
    await ref.read(authServiceProvider).signIn(email, password);
    state = Supabase.instance.client.auth.currentUser;
  }

  Future<void> signUp(String email, String password) async {
    await ref.read(authServiceProvider).signUp(email, password);
    state = Supabase.instance.client.auth.currentUser;
  }

  Future<void> signOut() async {
    await ref.read(authServiceProvider).signOut();
    state = null;
  }
}

final authNotifierProvider = NotifierProvider<AuthNotifier, User?>(AuthNotifier.new);