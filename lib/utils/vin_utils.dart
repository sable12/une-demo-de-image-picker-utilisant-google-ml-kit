/// Helpers to clean up and loosely validate a VIN (Vehicle Identification
/// Number) extracted from OCR output.
///
/// A VIN is always 17 characters, alphanumeric, and never contains the
/// letters I, O, or Q (to avoid confusion with 1 and 0).
class VinUtils {
  /// Strict pattern: the WHOLE (already cleaned) token must be exactly
  /// 17 valid VIN characters, nothing more, nothing less.
  static final RegExp _vinExactPattern = RegExp(r'^[A-HJ-NPR-Z0-9]{17}$');

  /// Loose pattern: any 17-char run of valid VIN characters inside a
  /// longer string. Only used as a fallback (see extractVin below).
  static final RegExp _vinLoosePattern = RegExp(r'[A-HJ-NPR-Z0-9]{17}');

  /// Tries to find a valid-looking 17-character VIN inside raw OCR text.
  ///
  /// Strategy:
  /// 1. Split each line into whitespace-separated tokens BEFORE removing
  ///    spaces. A VIN is normally printed as its own isolated token
  ///    (e.g. "VIN WVWZZZ1JZXW000001" or "VIN: WVWZZZ1JZXW000001"), so
  ///    checking token-by-token prevents a label like "VIN" or "N°" from
  ///    getting glued onto the real code once punctuation/spaces are
  ///    stripped — which previously caused the regex to grab the wrong
  ///    17-character window (label chars + truncated VIN).
  /// 2. If no isolated 17-character token is found (e.g. OCR merged the
  ///    label and the VIN with no space at all), fall back to the old
  ///    substring search, line by line, as a best-effort.
  static String? extractVin(String rawText) {
    // Pass 1: token-based, exact match — most reliable.
    for (final line in rawText.split('\n')) {
      for (final rawToken in line.split(RegExp(r'\s+'))) {
        if (rawToken.isEmpty) continue;
        final cleaned = _normalize(rawToken);
        if (cleaned.length == 17 && _vinExactPattern.hasMatch(cleaned)) {
          return cleaned;
        }
      }
    }

    // Pass 2: fallback substring search on the whole (whitespace-stripped)
    // line, in case the VIN and a label ended up with no separating space.
    for (final line in rawText.split('\n')) {
      final cleaned = _normalize(line);
      final match = _vinLoosePattern.firstMatch(cleaned);
      if (match != null) {
        return match.group(0);
      }
    }

    return null;
  }

  /// Uppercases, strips non-alphanumeric characters, and corrects the two
  /// OCR confusions seen most often on embossed VIN plates. Since a real
  /// VIN never legitimately contains "O" or "I", any occurrence is safe
  /// to treat as a misread "0" / "1" rather than a reason to reject the
  /// match.
  static String _normalize(String token) {
    return token
        .replaceAll('İ', '1') // Turkish dotted capital I — was being silently dropped
        .replaceAll('ı', '1') // Turkish dotless lowercase i
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9]'), '')
        .replaceAll('O', '0')
        .replaceAll('I', '1');
  }
}