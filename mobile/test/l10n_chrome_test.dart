import 'dart:async';

import 'package:aetherride_mobile/core/errors/friendly_error.dart';
import 'package:aetherride_mobile/domain/home/greeting.dart';
import 'package:aetherride_mobile/l10n/app_locale.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() {
    AppLocaleBinding.chromeLanguageCode = 'de';
    AppLocaleBinding.chromeCountryCode = null;
    AppLocaleBinding.deviceLanguageCode = 'de';
    AppLocaleBinding.deviceCountryCode = null;
  });

  test('resolve matches de/en/fr/it and falls unknown languages to de', () {
    const supported = [
      Locale('de'),
      Locale('en'),
      Locale('fr'),
      Locale('it'),
    ];
    expect(
      AppLocaleBinding.resolve(const Locale('fr', 'CH'), supported),
      const Locale('fr', 'CH'),
    );
    expect(
      AppLocaleBinding.resolve(const Locale('it', 'IT'), supported),
      const Locale('it', 'IT'),
    );
    expect(
      AppLocaleBinding.resolve(const Locale('en', 'DE'), supported),
      const Locale('en', 'DE'),
    );
    expect(
      AppLocaleBinding.resolve(const Locale('nl', 'NL'), supported),
      const Locale('de', 'NL'),
    );
  });

  test('greeting follows languageCode', () {
    final morning = DateTime(2026, 8, 7, 9);
    expect(greetingLine(now: morning), 'Guten Morgen');
    expect(greetingLine(now: morning, languageCode: 'en'), 'Good morning');
    expect(
      greetingLine(displayName: 'Jonas', now: morning, languageCode: 'en'),
      'Good morning, Jonas',
    );
    expect(greetingLine(now: morning, languageCode: 'fr'), 'Bonjour');
    expect(greetingLine(now: morning, languageCode: 'it'), 'Buongiorno');
  });

  test('friendlyError follows chrome language', () {
    expect(
      friendlyErrorMessage(TimeoutException('x')),
      contains('Zeitüberschreitung'),
    );
    AppLocaleBinding.chromeLanguageCode = 'en';
    expect(
      friendlyErrorMessage(TimeoutException('x'), context: 'Route berechnen'),
      contains('Timed out'),
    );
    expect(
      friendlyErrorMessage(TimeoutException('x'), context: 'Route berechnen'),
      contains('Calculate route'),
    );
    AppLocaleBinding.chromeLanguageCode = 'fr';
    expect(
      friendlyErrorMessage(TimeoutException('x')),
      contains('Délai dépassé'),
    );
    AppLocaleBinding.chromeLanguageCode = 'it';
    expect(
      friendlyErrorMessage(TimeoutException('x')),
      contains('Tempo scaduto'),
    );
  });

  test('friendlyError hides localhost socket refuse from riders', () {
    const raw =
        'ClientException with SocketException: Connection refused '
        '(OS Error: Connection refused, errno = 111), address = 127.0.0.1, '
        'port = 34378, uri=http://127.0.0.1:3001/api/route';
    final msg = friendlyErrorMessage(raw);
    expect(msg, contains('Keine Verbindung'));
    expect(msg, isNot(contains('127.0.0.1')));
    expect(msg, isNot(contains('SocketException')));
    expect(msg, isNot(contains('/api/route')));
  });

  test('tts tag follows chrome + country', () {
    AppLocaleBinding.chromeLanguageCode = 'en';
    AppLocaleBinding.chromeCountryCode = 'GB';
    expect(AppLocaleBinding.ttsLanguageTag(), 'en-GB');
    AppLocaleBinding.chromeCountryCode = 'US';
    expect(AppLocaleBinding.ttsLanguageTag(), 'en-US');
    AppLocaleBinding.chromeLanguageCode = 'de';
    expect(AppLocaleBinding.ttsLanguageTag(), 'de-DE');
    AppLocaleBinding.chromeLanguageCode = 'fr';
    AppLocaleBinding.chromeCountryCode = 'CH';
    expect(AppLocaleBinding.ttsLanguageTag(), 'fr-CH');
    AppLocaleBinding.chromeLanguageCode = 'it';
    AppLocaleBinding.chromeCountryCode = 'IT';
    expect(AppLocaleBinding.ttsLanguageTag(), 'it-IT');
  });
}
