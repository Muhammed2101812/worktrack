import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worklog/core/utils.dart';

void main() {
  group('parseHexColor', () {
    test('parses #RRGGBB', () {
      expect(parseHexColor('#4A90D9'), const Color(0xFF4A90D9));
    });

    test('parses RRGGBB without #', () {
      expect(parseHexColor('4A90D9'), const Color(0xFF4A90D9));
    });

    test('parses #AARRGGBB', () {
      expect(parseHexColor('#FF4A90D9'), const Color(0xFF4A90D9));
    });

    test('parses lowercase hex', () {
      expect(parseHexColor('#4a90d9'), const Color(0xFF4A90D9));
    });

    test('returns fallback for empty string', () {
      expect(parseHexColor(''), const Color(0xFF9CA3AF));
    });

    test('returns fallback for null', () {
      expect(parseHexColor(null), const Color(0xFF9CA3AF));
    });

    test('returns fallback for malformed input', () {
      expect(parseHexColor('xyz'), const Color(0xFF9CA3AF));
    });

    test('accepts custom fallback', () {
      expect(parseHexColor(null, Colors.red), Colors.red);
    });
  });
}
