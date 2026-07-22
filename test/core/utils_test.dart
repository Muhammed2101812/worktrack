import 'package:flutter_test/flutter_test.dart';
import 'package:worklog/core/utils.dart';

void main() {
  group('Utils - displayDateToSortable Tests', () {
    test('should convert valid dd.MM.yyyy date to yyyy-MM-dd format', () {
      expect(displayDateToSortable('15.03.2026'), '2026-03-15');
      expect(displayDateToSortable('31.12.2025'), '2025-12-31');
    });

    test('should pad single digit days and months with leading zeros', () {
      expect(displayDateToSortable('1.2.2026'), '2026-02-01');
      expect(displayDateToSortable('09.05.2024'), '2024-05-09');
    });

    test('should return null if there are not exactly 3 parts separated by dots', () {
      expect(displayDateToSortable('15.03'), isNull);
      expect(displayDateToSortable('2026'), isNull);
      expect(displayDateToSortable(''), isNull);
      expect(displayDateToSortable('15/03/2026'), isNull);
    });

    test('should return null if the year part length is not 4', () {
      expect(displayDateToSortable('15.03.26'), isNull);
      expect(displayDateToSortable('15.03.20261'), isNull);
    });
  });

  group('Utils - compareDisplayDates Tests', () {
    test('should return 0 when both dates are equal', () {
      expect(compareDisplayDates('15.03.2026', '15.03.2026'), 0);
    });

    test('should correctly compare chronologically valid display dates', () {
      // First is earlier -> negative value
      expect(compareDisplayDates('15.03.2026', '16.03.2026'), lessThan(0));
      expect(compareDisplayDates('15.03.2026', '15.04.2026'), lessThan(0));
      expect(compareDisplayDates('15.03.2026', '15.03.2027'), lessThan(0));

      // First is later -> positive value
      expect(compareDisplayDates('16.03.2026', '15.03.2026'), greaterThan(0));
      expect(compareDisplayDates('15.04.2026', '15.03.2026'), greaterThan(0));
      expect(compareDisplayDates('15.03.2027', '15.03.2026'), greaterThan(0));
    });

    test('should fall back to raw string compare when first date is malformed', () {
      // 'abc' is not parseable. '15.03.2026' is parseable but comparing 'abc' to '15.03.2026'
      // falls back to 'abc'.compareTo('15.03.2026')
      expect(compareDisplayDates('abc', '15.03.2026'), 'abc'.compareTo('15.03.2026'));
    });

    test('should fall back to raw string compare when second date is malformed', () {
      // '15.03.2026' is parseable, 'def' is not parseable.
      // falls back to '15.03.2026'.compareTo('def')
      expect(compareDisplayDates('15.03.2026', 'def'), '15.03.2026'.compareTo('def'));
    });

    test('should fall back to raw string compare when both dates are malformed', () {
      expect(compareDisplayDates('abc', 'def'), 'abc'.compareTo('def'));
    });
  });

  group('Utils - decodeHtmlEntities Tests', () {
    test('should decode basic HTML entities', () {
      expect(decodeHtmlEntities('&amp;'), '&');
      expect(decodeHtmlEntities('&lt;'), '<');
      expect(decodeHtmlEntities('&gt;'), '>');
      expect(decodeHtmlEntities('&quot;'), '"');
      expect(decodeHtmlEntities('&#39;'), "'");
      expect(decodeHtmlEntities('&apos;'), "'");
    });

    test('should decode decimal unicode entities', () {
      expect(decodeHtmlEntities('&#38;'), '&');
      expect(decodeHtmlEntities('&#60;'), '<');
      expect(decodeHtmlEntities('&#62;'), '>');
      expect(decodeHtmlEntities('&#123;'), '{');
      expect(decodeHtmlEntities('&#125;'), '}');
    });

    test('should decode hex unicode entities', () {
      expect(decodeHtmlEntities('&#x26;'), '&');
      expect(decodeHtmlEntities('&#x3C;'), '<');
      expect(decodeHtmlEntities('&#x3E;'), '>');
      expect(decodeHtmlEntities('&#x7B;'), '{');
      expect(decodeHtmlEntities('&#x7D;'), '}');
    });

    test('should return empty string if input is empty', () {
      expect(decodeHtmlEntities(''), '');
    });

    test('should leave non-entity text intact', () {
      expect(decodeHtmlEntities('Hello World!'), 'Hello World!');
      expect(decodeHtmlEntities('No & entities here.'), 'No & entities here.');
    });

    test('should handle mixed content correctly', () {
      expect(
        decodeHtmlEntities('Hello &amp; welcome to &quot;Flutter&quot;! Use &#123;code&#125; and &#x26; have fun.'),
        'Hello & welcome to "Flutter"! Use {code} and & have fun.',
      );
    });
  });
}
