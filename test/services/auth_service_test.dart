import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:worklog/services/auth_service.dart';

class MockSupabaseClient implements SupabaseClient {
  @override
  final GoTrueClient auth;

  MockSupabaseClient({required this.auth});

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockGoTrueClient implements GoTrueClient {
  final Future<AuthResponse> Function(String email, String password) onSignUp;

  MockGoTrueClient({required this.onSignUp});

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #signUp) {
      final email = invocation.namedArguments[#email] as String;
      final password = invocation.namedArguments[#password] as String;
      return onSignUp(email, password);
    }
    return super.noSuchMethod(invocation);
  }
}

void main() {
  group('AuthService Tests', () {
    test('signUp should rethrow error when Supabase client throws an exception', () async {
      // Arrange
      final mockAuth = MockGoTrueClient(
        onSignUp: (email, password) async {
          throw const AuthException('Sign up failed');
        },
      );
      final mockClient = MockSupabaseClient(auth: mockAuth);
      final authService = AuthService(client: mockClient);

      // Act & Assert
      expect(
        () => authService.signUp('test@example.com', 'password123'),
        throwsA(isA<AuthException>().having((e) => e.message, 'message', 'Sign up failed')),
      );
    });

    test('signUp should complete successfully when client succeeds', () async {
      // Arrange
      final mockAuth = MockGoTrueClient(
        onSignUp: (email, password) async {
          return AuthResponse(
            session: null,
            user: null,
          );
        },
      );
      final mockClient = MockSupabaseClient(auth: mockAuth);
      final authService = AuthService(client: mockClient);

      // Act & Assert
      expect(
        authService.signUp('test@example.com', 'password123'),
        completes,
      );
    });
  });
}
