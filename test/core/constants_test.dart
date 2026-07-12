import 'package:flutter_test/flutter_test.dart';
import 'package:worklog/core/constants.dart';

void main() {
  group('AppConstants Tests', () {
    test('should have a defined googleServerClientId', () {
      expect(AppConstants.googleServerClientId, isNotEmpty);
      expect(AppConstants.googleServerClientId, contains('apps.googleusercontent.com'));
    });
  });
}
