import 'package:flutter/material.dart';

String decodeHtmlEntities(String s) {
  if (s.isEmpty) return s;
  var decoded = s
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&apos;', "'");

  // Decode decimal entities &#123;
  final decRegex = RegExp(r'&#(\d+);');
  decoded = decoded.replaceAllMapped(decRegex, (match) {
    final code = int.parse(match.group(1)!);
    return String.fromCharCode(code);
  });

  // Decode hex entities &#xABC;
  final hexRegex = RegExp(r'&#x([0-9a-fA-F]+);');
  decoded = decoded.replaceAllMapped(hexRegex, (match) {
    final code = int.parse(match.group(1)!, radix: 16);
    return String.fromCharCode(code);
  });

  return decoded;
}

/// Converts a display date ("dd.MM.yyyy") into a lexicographically sortable
/// string ("yyyy-MM-dd"). Returns null when the input does not match the
/// expected format, so callers can fall back to the raw value.
String? displayDateToSortable(String displayDate) {
  final parts = displayDate.split('.');
  if (parts.length != 3) return null;
  final day = parts[0].padLeft(2, '0');
  final month = parts[1].padLeft(2, '0');
  final year = parts[2];
  if (year.length != 4) return null;
  return '$year-$month-$day';
}

/// Lexicographic date comparator for the "dd.MM.yyyy" display format.
/// Falls back to a plain string compare when either side is not parseable,
/// so sorting never throws on malformed legacy data.
int compareDisplayDates(String a, String b) {
  final sa = displayDateToSortable(a);
  final sb = displayDateToSortable(b);
  if (sa != null && sb != null) return sa.compareTo(sb);
  return a.compareTo(b);
}

/// Parses a hex color string into a [Color]. Accepts `#RRGGBB`,
/// `#AARRGGBB`, `RRGGBB`, `AARRGGBB` (case-insensitive). Returns [fallback]
/// for null, empty, or malformed input so callers never throw.
///
/// Consolidates the 7 duplicated `_parseColor` implementations across screens.
Color parseHexColor(String? hex, [Color fallback = const Color(0xFF9CA3AF)]) {
  if (hex == null || hex.isEmpty) return fallback;
  var h = hex.trim();
  if (h.startsWith('#')) h = h.substring(1);
  // Normalize to AARRGGBB.
  if (h.length == 6) h = 'FF$h';
  if (h.length != 8) return fallback;
  final value = int.tryParse(h, radix: 16);
  if (value == null) return fallback;
  return Color(value);
}
