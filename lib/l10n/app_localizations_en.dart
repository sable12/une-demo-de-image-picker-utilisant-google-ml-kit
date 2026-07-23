// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'VIN Scanner';

  @override
  String get scanVinTitle => 'Scan VIN';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get french => 'French';

  @override
  String get spanish => 'Spanish';

  @override
  String get takeVinPhoto => 'Take a photo of the VIN plate';

  @override
  String get camera => 'Camera';

  @override
  String get gallery => 'Gallery';

  @override
  String get readingVin => 'Reading VIN...';

  @override
  String get errorPrefix => 'Error';

  @override
  String get vinCopied => 'VIN copied';

  @override
  String get copy => 'Copy';

  @override
  String get vinDetected => 'VIN DETECTED';

  @override
  String get noValidVinDetected => 'No valid VIN detected (17 characters expected). Try again with a sharper framing, or correct it manually below.';

  @override
  String get manualVinHint => 'Enter VIN manually (17 characters)';

  @override
  String get ocrRawTextDebug => 'Raw OCR text (debug):';
}
