import 'package:flutter_test/flutter_test.dart';
import 'package:worklog/core/utils.dart';

void main() {
  group('decodeHtmlEntities Tests', () {
    test('should return empty string when input is empty', () {
      expect(decodeHtmlEntities(''), '');
    });

    test('should return unchanged string when there are no HTML entities', () {
      expect(decodeHtmlEntities('Hello World 123!'), 'Hello World 123!');
    });

    test('should decode named HTML entities correctly', () {
      expect(decodeHtmlEntities('&amp;'), '&');
      expect(decodeHtmlEntities('&lt;'), '<');
      expect(decodeHtmlEntities('&gt;'), '>');
      expect(decodeHtmlEntities('&quot;'), '"');
      expect(decodeHtmlEntities('&#39;'), "'");
      expect(decodeHtmlEntities('&apos;'), "'");
    });

    test('should decode decimal entities correctly', () {
      expect(decodeHtmlEntities('&#38;'), '&');
      expect(decodeHtmlEntities('&#123;'), '{');
      expect(decodeHtmlEntities('&#125;'), '}');
    });

    test('should decode hex entities correctly (case-insensitive)', () {
      expect(decodeHtmlEntities('&#x26;'), '&');
      expect(decodeHtmlEntities('&#x7B;'), '{'); // Uppercase B
      expect(decodeHtmlEntities('&#x7b;'), '{'); // Lowercase b
      expect(decodeHtmlEntities('&#x7D;'), '}');
    });

    test('should decode a mixture of text and entities correctly', () {
      const input = 'A &amp; B &lt; C &gt; D &quot;E&#39;F&apos;G &#123; &#x7B;';
      const expected = 'A & B < C > D "E\'F\'G { {';
      expect(decodeHtmlEntities(input), expected);
    });

    test('should not decode invalid decimal or hex patterns', () {
      expect(decodeHtmlEntities('&#abc;'), '&#abc;');
      expect(decodeHtmlEntities('&#xghi;'), '&#xghi;');
      expect(decodeHtmlEntities('&#;'), '&#;');
      expect(decodeHtmlEntities('&#x;'), '&#x;');
    });
  });

  group('displayDateToSortable Tests', () {
    test('should convert a valid display date correctly', () {
      expect(displayDateToSortable('15.08.2023'), '2023-08-15');
    });

    test('should pad single-digit day and month correctly', () {
      expect(displayDateToSortable('1.2.2023'), '2023-02-01');
    });

    test('should return null if the format does not split into exactly three parts', () {
      expect(displayDateToSortable('15.08'), null);
      expect(displayDateToSortable('15.08.2023.01'), null);
      expect(displayDateToSortable(''), null);
    });

    test('should return null if the year is not exactly 4 characters', () {
      expect(displayDateToSortable('15.08.23'), null);
      expect(displayDateToSortable('15.08.20235'), null);
    });
  });

  group('compareDisplayDates Tests', () {
    test('should return 0 for identical dates', () {
      expect(compareDisplayDates('15.08.2023', '15.08.2023'), 0);
    });

    test('should correctly order different days within the same month', () {
      expect(compareDisplayDates('15.08.2023', '16.08.2023'), isNegative);
      expect(compareDisplayDates('16.08.2023', '15.08.2023'), isPositive);
    });

    test('should correctly order different months within the same year', () {
      expect(compareDisplayDates('01.02.2023', '15.01.2023'), isPositive);
      expect(compareDisplayDates('15.01.2023', '01.02.2023'), isNegative);
    });

    test('should correctly order different years', () {
      expect(compareDisplayDates('15.08.2023', '15.08.2024'), isNegative);
      expect(compareDisplayDates('15.08.2024', '15.08.2023'), isPositive);
    });

    test('should fall back to plain lexicographical string comparison if first date is invalid', () {
      // "invalid" vs "15.08.2023" (sortable "2023-08-15")
      // Since first is invalid, fallback to plain string compare: "invalid".compareTo("15.08.2023")
      // 'i' comes after '1', so should be positive
      expect(compareDisplayDates('invalid', '15.08.2023'), isPositive);
    });

    test('should fall back to plain lexicographical string comparison if second date is invalid', () {
      // "15.08.2023" vs "invalid"
      // "15.08.2023".compareTo("invalid")
      // '1' comes before 'i', so should be negative
      expect(compareDisplayDates('15.08.2023', 'invalid'), isNegative);
    });

    test('should fall back to plain lexicographical string comparison if both dates are invalid', () {
      expect(compareDisplayDates('abc', 'def'), isNegative);
      expect(compareDisplayDates('def', 'abc'), isPositive);
      expect(compareDisplayDates('abc', 'abc'), 0);
    });
  });
}
