/// Aide à nettoyer et à valider de façon souple un VIN (Vehicle Identification
/// Number) extrait d'un texte OCR.
///
/// Un VIN comporte toujours 17 caractères alphanumériques et ne contient
/// jamais les lettres I, O ou Q (pour éviter la confusion avec 1 et 0).
class VinUtils {
  /// Motif strict : le jeton ENTIER (déjà nettoyé) doit contenir exactement
  /// 17 caractères VIN valides, ni plus ni moins.
  static final RegExp _vinExactPattern = RegExp(r'^[A-HJ-NPR-Z0-9]{17}$');

  /// Motif souple : toute séquence de 17 caractères VIN valides à l'intérieur
  /// d'une chaîne plus longue. Utilisé uniquement en secours (voir extractVin).
  static final RegExp _vinLoosePattern = RegExp(r'[A-HJ-NPR-Z0-9]{17}');

  static final RegExp _weightPattern = RegExp(r'\b\d{3,}\s*kg\b', caseSensitive: false);
  static final RegExp _vinLabelPattern = RegExp(r'\bvin\b', caseSensitive: false);
  static final RegExp _chassisPattern = RegExp(r'\b(chassis|frame)\b', caseSensitive: false);
  static final RegExp _brandPattern = RegExp(r'\b(renault)\b', caseSensitive: false);

  /// Tente de trouver un VIN plausible de 17 caractères dans le texte OCR brut.
  ///
  /// Stratégie :
  /// 1. Découper chaque ligne en jetons séparés par des espaces AVANT de
  ///    supprimer les espaces. Un VIN est généralement imprimé comme un jeton
  ///    isolé (par ex. "VIN WVWZZZ1JZXW000001" ou "VIN: WVWZZZ1JZXW000001"),
  ///    donc le contrôle jeton par jeton évite qu'un libellé comme "VIN" ou
  ///    "N°" soit collé au vrai code une fois la ponctuation et les espaces
  ///    supprimés — ce qui faisait auparavant capturer par la regex la mauvaise
  ///    fenêtre de 17 caractères (texte du libellé + VIN tronqué).
  /// 2. Si aucun jeton isolé de 17 caractères n'est trouvé (par ex. si l'OCR a
  ///    fusionné le libellé et le VIN sans espace), revenir à l'ancienne
  ///    recherche par sous-chaîne, ligne par ligne, en mode best-effort.
  static String? extractVin(String rawText) {
    final lines = rawText.split('\n');
    final candidates = <_VinCandidate>[];

    for (var lineIndex = 0; lineIndex < lines.length; lineIndex++) {
      final line = lines[lineIndex];
      final lineScore = _scoreLine(line, lineIndex, lines.length);

      // Étape 1 : correspondance exacte basée sur les jetons — la plus fiable.
      for (final rawToken in line.split(RegExp(r'\s+'))) {
        if (rawToken.isEmpty) continue;
        final cleaned = _normalize(rawToken);
        if (cleaned.length == 17 && _vinExactPattern.hasMatch(cleaned)) {
          candidates.add(_VinCandidate(cleaned, lineScore + 100));
        }
      }

      // Étape 2 : recherche de secours par sous-chaîne sur toute la ligne
      // (sans espaces), au cas où le VIN et le libellé seraient collés.
      final cleaned = _normalize(line);
      for (final match in _vinLoosePattern.allMatches(cleaned)) {
        final value = match.group(0);
        if (value != null) {
          candidates.add(_VinCandidate(value, lineScore + 70));
        }
      }
    }

    if (candidates.isEmpty) return null;

    candidates.sort((a, b) => b.score.compareTo(a.score));
    return candidates.first.value;
  }

    /// Met en majuscules, supprime les caractères non alphanumériques et
    /// corrige les deux confusions OCR les plus fréquentes sur les plaques VIN
    /// embossées. Comme un vrai VIN ne contient jamais légitimement "O" ou
    /// "I", toute occurrence peut être traitée sans risque comme une mauvaise
    /// lecture de "0" / "1" plutôt que comme une raison de rejeter la valeur.
  static String _normalize(String token) {
    return token
      .replaceAll('İ', '1') // I majuscule pointée turque — était supprimée silencieusement
      .replaceAll('ı', '1') // i minuscule turque sans point
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9]'), '')
        .replaceAll('O', '0')
        .replaceAll('I', '1');
  }

  static int _scoreLine(String line, int lineIndex, int totalLines) {
    var score = 0;
    final upper = line.toUpperCase();

    if (_vinLabelPattern.hasMatch(upper)) score += 40;
    if (_chassisPattern.hasMatch(upper)) score += 20;
    if (_brandPattern.hasMatch(upper)) score += 8;
    if (_weightPattern.hasMatch(upper)) score -= 60;

    // Sur beaucoup de plaques, le VIN se trouve dans la moitié supérieure de l'étiquette.
    if (lineIndex <= totalLines ~/ 2) {
      score += 5;
    }

    return score;
  }
}

class _VinCandidate {
  _VinCandidate(this.value, this.score);

  final String value;
  final int score;
}