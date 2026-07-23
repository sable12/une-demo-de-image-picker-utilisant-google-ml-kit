// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Scanner VIN';

  @override
  String get scanVinTitle => 'Scanner VIN';

  @override
  String get language => 'Langue';

  @override
  String get english => 'Anglais';

  @override
  String get french => 'Français';

  @override
  String get spanish => 'Espagnol';

  @override
  String get takeVinPhoto => 'Photographiez la plaque VIN';

  @override
  String get camera => 'Caméra';

  @override
  String get gallery => 'Galerie';

  @override
  String get readingVin => 'Lecture du VIN...';

  @override
  String get errorPrefix => 'Erreur';

  @override
  String get vinCopied => 'VIN copié';

  @override
  String get copy => 'Copier';

  @override
  String get vinDetected => 'VIN DÉTECTÉ';

  @override
  String get noValidVinDetected => 'Aucun VIN valide détecté (17 caractères attendus). Réessayez avec un cadrage plus net, ou corrigez manuellement ci-dessous.';

  @override
  String get manualVinHint => 'Saisir le VIN manuellement (17 caractères)';

  @override
  String get ocrRawTextDebug => 'Texte brut lu par l\'OCR (debug) :';
}
