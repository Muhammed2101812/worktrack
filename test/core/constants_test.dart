import 'package:flutter_test/flutter_test.dart';
import 'package:worklog/core/constants.dart';

void main() {
  group('AppConstants Security Tests', () {
    test('supabaseUrl should default to empty string to prevent hardcoded credentials', () {
      expect(AppConstants.supabaseUrl, isEmpty);
    });

    test('supabaseAnonKey should default to empty string to prevent hardcoded credentials', () {
      expect(AppConstants.supabaseAnonKey, isEmpty);
    });
  });
}
