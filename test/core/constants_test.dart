import 'package:flutter_test/flutter_test.dart';
import 'package:worklog/core/constants.dart';

void main() {
  group('AppConstants Tests', () {
    test('should have a defined googleClientId', () {
      expect(AppConstants.googleClientId, isNotEmpty);
      expect(AppConstants.googleClientId, contains('apps.googleusercontent.com'));
    });
  });
}
