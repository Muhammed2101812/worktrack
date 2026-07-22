import 'package:path/path.dart' as p;

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

/// Validates a file path to prevent directory traversal attacks.
///
/// Ensures the path:
/// 1. Is not empty or null.
/// 2. Does not contain directory traversal sequences like '..' or '.'.
/// 3. Ends with the expected case-insensitive extension.
bool isSafePath(String? path, String expectedExtension) {
  if (path == null || path.trim().isEmpty) return false;

  // Detect any explicit directory traversal indicators (e.g. ".." or relative components)
  if (path.contains('..') || path.contains('/./') || path.contains('\\.\\')) {
    return false;
  }

  // Normalize path and verify it is free of relative segments
  final normalized = p.normalize(path);
  final segments = p.split(normalized);

  if (segments.contains('..') || segments.contains('.')) {
    return false;
  }

  // Verify normalized path does not have traversal sequences
  if (normalized.contains('..') || normalized.contains('/./') || normalized.contains('\\.\\')) {
    return false;
  }

  // Ensure path ends with the expected extension (case-insensitive)
  if (!normalized.toLowerCase().endsWith('.${expectedExtension.toLowerCase()}')) {
    return false;
  }

  return true;
}
