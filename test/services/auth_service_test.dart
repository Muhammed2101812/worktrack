import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:worklog/services/auth_service.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockGoTrueClient extends Mock implements GoTrueClient {}
class MockAuthResponse extends Mock implements AuthResponse {}

void main() {
  group('AuthService Tests', () {
    late MockSupabaseClient mockSupabaseClient;
    late MockGoTrueClient mockGoTrueClient;
    late AuthService authService;

    setUp(() {
      mockSupabaseClient = MockSupabaseClient();
      mockGoTrueClient = MockGoTrueClient();
      authService = AuthService(client: mockSupabaseClient);

      // Default stub for auth getter
      when(() => mockSupabaseClient.auth).thenReturn(mockGoTrueClient);
    });

    test('should have AuthService class', () {
      expect(() => AuthService(client: mockSupabaseClient), returnsNormally);
    });

    group('signIn', () {
      const email = 'test@example.com';
      const password = 'password123';

      test('should call signInWithPassword and succeed on happy path', () async {
        final mockAuthResponse = MockAuthResponse();

        when(() => mockGoTrueClient.signInWithPassword(
              email: email,
              password: password,
            )).thenAnswer((_) async => mockAuthResponse);

        await expectLater(
          authService.signIn(email, password),
          completes,
        );

        verify(() => mockGoTrueClient.signInWithPassword(
              email: email,
              password: password,
            )).called(1);
      });

      test('should rethrow exceptions caught during signInWithPassword', () async {
        final expectedException = AuthException('Invalid login credentials');

        when(() => mockGoTrueClient.signInWithPassword(
              email: email,
              password: password,
            )).thenThrow(expectedException);

        await expectLater(
          authService.signIn(email, password),
          throwsA(isA<AuthException>().having(
            (e) => e.message,
            'message',
            'Invalid login credentials',
          )),
        );

        verify(() => mockGoTrueClient.signInWithPassword(
              email: email,
              password: password,
            )).called(1);
      });
    });

    group('signUp', () {
      const email = 'test@example.com';
      const password = 'password123';

      test('should call signUp and succeed on happy path', () async {
        final mockAuthResponse = MockAuthResponse();

        when(() => mockGoTrueClient.signUp(
              email: email,
              password: password,
            )).thenAnswer((_) async => mockAuthResponse);

        await expectLater(
          authService.signUp(email, password),
          completes,
        );

        verify(() => mockGoTrueClient.signUp(
              email: email,
              password: password,
            )).called(1);
      });

      test('should rethrow exceptions caught during signUp', () async {
        final expectedException = AuthException('Sign up failed');

        when(() => mockGoTrueClient.signUp(
              email: email,
              password: password,
            )).thenThrow(expectedException);

        await expectLater(
          authService.signUp(email, password),
          throwsA(isA<AuthException>().having(
            (e) => e.message,
            'message',
            'Sign up failed',
          )),
        );

        verify(() => mockGoTrueClient.signUp(
              email: email,
              password: password,
            )).called(1);
      });
    });
  });
}
