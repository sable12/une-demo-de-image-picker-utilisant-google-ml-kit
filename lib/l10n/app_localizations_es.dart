// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Escáner VIN';

  @override
  String get scanVinTitle => 'Escanear VIN';

  @override
  String get language => 'Idioma';

  @override
  String get english => 'Inglés';

  @override
  String get french => 'Francés';

  @override
  String get spanish => 'Español';

  @override
  String get takeVinPhoto => 'Fotografía la placa VIN';

  @override
  String get camera => 'Cámara';

  @override
  String get gallery => 'Galería';

  @override
  String get readingVin => 'Leyendo VIN...';

  @override
  String get errorPrefix => 'Error';

  @override
  String get vinCopied => 'VIN copiado';

  @override
  String get copy => 'Copiar';

  @override
  String get vinDetected => 'VIN DETECTADO';

  @override
  String get noValidVinDetected => 'No se detectó un VIN válido (se esperan 17 caracteres). Intenta de nuevo con un encuadre más nítido, o corrígelo manualmente abajo.';

  @override
  String get manualVinHint => 'Introducir VIN manualmente (17 caracteres)';

  @override
  String get ocrRawTextDebug => 'Texto OCR sin procesar (debug):';
}
