import 'package:flutter_test/flutter_test.dart';
import 'package:worklog/providers/auth_provider.dart';

void main() {
  group('friendlyAuthError Tests', () {
    test('translates invalid login credentials message', () {
      final error = 'Invalid login credentials';
      expect(friendlyAuthError(error), equals('E-posta veya şifre hatalı.'));
    });

    test('translates email not confirmed message', () {
      final error = 'Email not confirmed';
      expect(
        friendlyAuthError(error),
        equals('E-posta adresiniz henüz doğrulanmamış. Lütfen gelen kutunuzu kontrol edin.'),
      );
    });

    test('translates user already registered message', () {
      final error = 'User already registered';
      expect(friendlyAuthError(error), equals('Bu e-posta adresi zaten kayıtlı.'));
    });

    test('translates password length message', () {
      final error = 'Password should be at least 6 characters';
      expect(friendlyAuthError(error), equals('Şifre en az 6 karakter olmalıdır.'));
    });

    test('translates invalid email address message', () {
      final error = 'Unable to validate email address';
      expect(friendlyAuthError(error), equals('Geçersiz e-posta adresi.'));
    });

    test('translates rate limit / too many requests messages', () {
      expect(
        friendlyAuthError('rate limit exceeded'),
        equals('Çok fazla deneme yapıldı. Lütfen biraz bekleyin.'),
      );
      expect(
        friendlyAuthError('Too many requests'),
        equals('Çok fazla deneme yapıldı. Lütfen biraz bekleyin.'),
      );
    });

    test('translates network / connection failures', () {
      expect(
        friendlyAuthError('NetworkRequestFailed'),
        equals('Bağlantı hatası. İnternet bağlantınızı kontrol edin.'),
      );
      expect(
        friendlyAuthError('socket exception'),
        equals('Bağlantı hatası. İnternet bağlantınızı kontrol edin.'),
      );
      expect(
        friendlyAuthError('network error occurred'),
        equals('Bağlantı hatası. İnternet bağlantınızı kontrol edin.'),
      );
    });

    test('is case insensitive', () {
      final error = 'INVALID LOGIN CREDENTIALS';
      expect(friendlyAuthError(error), equals('E-posta veya şifre hatalı.'));
    });

    test('falls back to stripped exception message for unknown exceptions', () {
      final error = 'Exception: Unknown auth failure';
      expect(friendlyAuthError(error), equals('İşlem başarısız: Unknown auth failure'));
    });

    test('falls back to original string for custom error messages', () {
      final error = 'Something went totally wrong';
      expect(friendlyAuthError(error), equals('İşlem başarısız: Something went totally wrong'));
    });
  });
}
