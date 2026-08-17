import 'package:flutter/widgets.dart';

/// Chrome languages shipped as ARB. Unknown UI languages fall back to `de`
/// while keeping the country so Hof-Titel can still split CH-FR / CH-IT
/// from the device language.
class AppLocaleBinding {
  AppLocaleBinding._();

  static const chromeLanguages = {'de', 'en', 'fr', 'it', 'nl'};

  /// Resolved UI language: `de`, `en`, `fr`, `it`, or `nl`.
  static String chromeLanguageCode = 'de';

  static String? chromeCountryCode;

  /// First platform locale — not the chrome fallback.
  static String deviceLanguageCode = 'de';

  static String? deviceCountryCode;

  static Locale resolve(Locale? locale, Iterable<Locale> supported) {
    if (locale != null) {
      for (final candidate in supported) {
        if (candidate.languageCode == locale.languageCode) {
          return Locale(candidate.languageCode, locale.countryCode);
        }
      }
    }
    return Locale('de', locale?.countryCode);
  }

  static void sync(BuildContext context) {
    final ui = Localizations.localeOf(context);
    final lang = ui.languageCode.toLowerCase();
    chromeLanguageCode =
        chromeLanguages.contains(lang) ? lang : 'de';
    chromeCountryCode = ui.countryCode;
    final device = View.of(context).platformDispatcher.locale;
    deviceLanguageCode = device.languageCode;
    deviceCountryCode = device.countryCode;
  }

  static String hofLanguageCode() => deviceLanguageCode;

  static String? hofCountryCode() => chromeCountryCode ?? deviceCountryCode;

  static bool get isEnglish => chromeLanguageCode == 'en';

  static String ttsLanguageTag() {
    final c = chromeCountryCode?.toUpperCase();
    switch (chromeLanguageCode) {
      case 'en':
        if (c == 'GB' || c == 'UK') return 'en-GB';
        return 'en-US';
      case 'fr':
        if (c == 'CH') return 'fr-CH';
        if (c == 'CA') return 'fr-CA';
        return 'fr-FR';
      case 'it':
        if (c == 'CH') return 'it-CH';
        return 'it-IT';
      case 'nl':
        if (c == 'BE') return 'nl-BE';
        return 'nl-NL';
      default:
        if (c == 'AT') return 'de-AT';
        if (c == 'CH') return 'de-CH';
        return 'de-DE';
    }
  }
}
