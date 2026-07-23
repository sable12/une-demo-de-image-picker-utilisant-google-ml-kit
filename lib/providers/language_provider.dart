import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

final appLanguageProvider = NotifierProvider<AppLanguageNotifier, Locale>(
  AppLanguageNotifier.new,
);

class AppLanguageNotifier extends Notifier<Locale> {
  @override
  Locale build() => const Locale('fr');

  void setLocale(Locale locale) {
    state = locale;
  }

  void setLocaleByCode(String code) {
    switch (code) {
      case 'en':
      case 'es':
      case 'fr':
        state = Locale(code);
        return;
      default:
        state = const Locale('fr');
    }
  }
}
