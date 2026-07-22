import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:worklog/providers/auth_provider.dart';
import 'package:worklog/services/auth_service.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockGoTrueClient extends Mock implements GoTrueClient {}
class MockUser extends Mock implements User {}
class MockSession extends Mock implements Session {}
class MockAuthService extends Mock implements AuthService {}

void main() {
  group('friendlyAuthError Tests', () {
    test('translates invalid login credentials', () {
      expect(friendlyAuthError('invalid login credentials'), 'E-posta veya şifre hatalı.');
    });

    test('translates email not confirmed', () {
      expect(friendlyAuthError('email not confirmed'), 'E-posta adresiniz henüz doğrulanmamış. Lütfen gelen kutunuzu kontrol edin.');
    });

    test('translates user already registered', () {
      expect(friendlyAuthError('user already registered'), 'Bu e-posta adresi zaten kayıtlı.');
    });

    test('translates password should be at least', () {
      expect(friendlyAuthError('password should be at least'), 'Şifre en az 6 karakter olmalıdır.');
    });

    test('translates unable to validate email address', () {
      expect(friendlyAuthError('unable to validate email address'), 'Geçersiz e-posta adresi.');
    });

    test('translates rate limit / too many attempts', () {
      expect(friendlyAuthError('rate limit exceeded'), 'Çok fazla deneme yapıldı. Lütfen biraz bekleyin.');
      expect(friendlyAuthError('too many requests'), 'Çok fazla deneme yapıldı. Lütfen biraz bekleyin.');
    });

    test('translates network or socket errors', () {
      expect(friendlyAuthError('networkrequestfailed'), 'Bağlantı hatası. İnternet bağlantınızı kontrol edin.');
      expect(friendlyAuthError('socket exception'), 'Bağlantı hatası. İnternet bağlantınızı kontrol edin.');
      expect(friendlyAuthError('network error occurred'), 'Bağlantı hatası. İnternet bağlantınızı kontrol edin.');
    });

    test('falls back gracefully on unknown errors', () {
      expect(friendlyAuthError('something went wrong'), 'İşlem başarısız: something went wrong');
      expect(friendlyAuthError('Exception: Some technical error'), 'İşlem başarısız: Some technical error');
    });
  });

  group('AuthProvider Tests', () {
    late MockSupabaseClient mockClient;
    late MockGoTrueClient mockAuth;
    late MockAuthService mockAuthService;
    late MockUser mockUser;
    late MockSession mockSession;
    late StreamController<AuthState> authStateController;

    setUp(() {
      mockClient = MockSupabaseClient();
      mockAuth = MockGoTrueClient();
      mockAuthService = MockAuthService();
      mockUser = MockUser();
      mockSession = MockSession();
      authStateController = StreamController<AuthState>.broadcast();

      when(() => mockClient.auth).thenReturn(mockAuth);
      when(() => mockAuth.currentUser).thenReturn(null);
      when(() => mockAuth.onAuthStateChange).thenAnswer((_) => authStateController.stream);
      when(() => mockSession.user).thenReturn(mockUser);
      when(() => mockUser.id).thenReturn('user_123');
    });

    tearDown(() {
      authStateController.close();
    });

    ProviderContainer createContainer() {
      final container = ProviderContainer(
        overrides: [
          supabaseClientProvider.overrideWithValue(mockClient),
          authServiceProvider.overrideWithValue(mockAuthService),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('currentUserProvider returns null when no user is signed in', () {
      final container = createContainer();
      final user = container.read(currentUserProvider);
      expect(user, isNull);
    });

    test('currentUserProvider returns user when user is signed in', () {
      when(() => mockAuth.currentUser).thenReturn(mockUser);
      final container = createContainer();
      final user = container.read(currentUserProvider);
      expect(user, equals(mockUser));
    });

    test('AuthNotifier initial state is currentUser', () {
      final container = createContainer();
      expect(container.read(authNotifierProvider), isNull);

      when(() => mockAuth.currentUser).thenReturn(mockUser);
      final containerWithUser = createContainer();
      expect(containerWithUser.read(authNotifierProvider), equals(mockUser));
    });

    test('AuthNotifier updates state when onAuthStateChange stream fires', () async {
      final container = createContainer();
      container.listen<User?>(authNotifierProvider, (_, __) {});

      expect(container.read(authNotifierProvider), isNull);

      // Emit signed in state
      authStateController.add(AuthState(AuthChangeEvent.signedIn, mockSession));
      await Future.delayed(Duration.zero);

      expect(container.read(authNotifierProvider), equals(mockUser));

      // Emit signed out state (session is null)
      authStateController.add(const AuthState(AuthChangeEvent.signedOut, null));
      await Future.delayed(Duration.zero);

      expect(container.read(authNotifierProvider), isNull);
    });

    test('signIn calls AuthService.signIn and updates notifier state', () async {
      final container = createContainer();
      container.listen<User?>(authNotifierProvider, (_, __) {});

      const email = 'test@example.com';
      const password = 'password123';

      when(() => mockAuthService.signIn(email, password)).thenAnswer((_) async {});
      when(() => mockAuth.currentUser).thenReturn(mockUser);

      await container.read(authNotifierProvider.notifier).signIn(email, password);

      verify(() => mockAuthService.signIn(email, password)).called(1);
      expect(container.read(authNotifierProvider), equals(mockUser));
    });

    test('signUp calls AuthService.signUp and updates notifier state', () async {
      final container = createContainer();
      container.listen<User?>(authNotifierProvider, (_, __) {});

      const email = 'test@example.com';
      const password = 'password123';

      when(() => mockAuthService.signUp(email, password)).thenAnswer((_) async {});
      when(() => mockAuth.currentUser).thenReturn(mockUser);

      await container.read(authNotifierProvider.notifier).signUp(email, password);

      verify(() => mockAuthService.signUp(email, password)).called(1);
      expect(container.read(authNotifierProvider), equals(mockUser));
    });

    test('signInWithGoogle calls AuthService.signInWithGoogle and updates notifier state', () async {
      final container = createContainer();
      container.listen<User?>(authNotifierProvider, (_, __) {});

      when(() => mockAuthService.signInWithGoogle()).thenAnswer((_) async {});
      when(() => mockAuth.currentUser).thenReturn(mockUser);

      await container.read(authNotifierProvider.notifier).signInWithGoogle();

      verify(() => mockAuthService.signInWithGoogle()).called(1);
      expect(container.read(authNotifierProvider), equals(mockUser));
    });

    test('signOut calls AuthService.signOut and sets state to null', () async {
      // Set initial state to logged-in user
      when(() => mockAuth.currentUser).thenReturn(mockUser);
      final container = createContainer();
      container.listen<User?>(authNotifierProvider, (_, __) {});

      expect(container.read(authNotifierProvider), equals(mockUser));

      when(() => mockAuthService.signOut()).thenAnswer((_) async {});
      when(() => mockAuth.currentUser).thenReturn(null);

      await container.read(authNotifierProvider.notifier).signOut();

      verify(() => mockAuthService.signOut()).called(1);
      expect(container.read(authNotifierProvider), isNull);
    });
  });
}
