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
