import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../l10n/app_locale.dart';

/// Zentrale Übersetzung technischer Exceptions in kurze Nutzer-Meldungen —
/// nie einen rohen `Exception`/`TimeoutException`-String direkt in
/// `_status`/`_error`-Felder durchreichen.
///
/// Sprache folgt [AppLocaleBinding.chromeLanguageCode].
String friendlyErrorMessage(Object error, {String? context}) {
  final lang = AppLocaleBinding.chromeLanguageCode;
  final ctx = _localizeContext(context, lang);
  final prefix = ctx == null ? '' : '$ctx — ';
  final msg = error.toString();

  if (error is TimeoutException) {
    return '$prefix${_copy(lang, de: 'Zeitüberschreitung — Verbindung prüfen und erneut versuchen.', en: 'Timed out — check the connection and try again.', fr: 'Délai dépassé — vérifie la connexion et réessaie.', it: 'Tempo scaduto — controlla la connessione e riprova.', nl: 'Time-out — check de verbinding en probeer opnieuw.')}';
  }
  if (error is SocketException ||
      msg.contains('SocketException') ||
      msg.contains('Failed host lookup') ||
      msg.contains('Connection refused') ||
      msg.contains('Network is unreachable')) {
    return '$prefix${_copy(lang, de: 'Keine Verbindung — Internet prüfen.', en: 'No connection — check the internet.', fr: 'Pas de connexion — vérifie Internet.', it: 'Nessuna connessione — controlla Internet.', nl: 'Geen verbinding — check internet.')}';
  }
  if (msg.contains('429') || msg.toLowerCase().contains('too many requests')) {
    return '$prefix${_copy(lang, de: 'Zu viele Anfragen — kurz warten und erneut versuchen.', en: 'Too many requests — wait a moment and try again.', fr: 'Trop de requêtes — attends un moment et réessaie.', it: 'Troppe richieste — aspetta un attimo e riprova.', nl: 'Te veel verzoeken — even wachten en opnieuw proberen.')}';
  }
  final serverError = RegExp(r'\b5\d{2}\b').hasMatch(msg);
  if (serverError) {
    return '$prefix${_copy(lang, de: 'Dienst vorübergehend nicht erreichbar — später erneut versuchen.', en: 'Service temporarily unavailable — try again later.', fr: 'Service temporairement indisponible — réessaie plus tard.', it: 'Servizio temporaneamente non disponibile — riprova più tardi.', nl: 'Dienst tijdelijk niet bereikbaar — later opnieuw proberen.')}';
  }
  if (msg.contains('404')) {
    return '$prefix${_copy(lang, de: 'Nichts gefunden.', en: 'Nothing found.', fr: 'Rien trouvé.', it: 'Niente trovato.', nl: 'Niets gevonden.')}';
  }
  if (error is FormatException || msg.contains('FormatException')) {
    return '$prefix${_copy(lang, de: 'Antwort konnte nicht gelesen werden.', en: 'Could not read the response.', fr: 'Impossible de lire la réponse.', it: 'Impossibile leggere la risposta.', nl: 'Antwoord kon niet worden gelezen.')}';
  }

  final generic = '$prefix${_copy(lang, de: 'Etwas ist schiefgelaufen — erneut versuchen.', en: 'Something went wrong — try again.', fr: 'Quelque chose a cloché — réessaie.', it: 'Qualcosa è andato storto — riprova.', nl: 'Er ging iets mis — probeer opnieuw.')}';
  return kDebugMode ? '$generic ($msg)' : generic;
}

String _copy(
  String lang, {
  required String de,
  required String en,
  required String fr,
  required String it,
  required String nl,
}) {
  switch (lang) {
    case 'en':
      return en;
    case 'fr':
      return fr;
    case 'it':
      return it;
    case 'nl':
      return nl;
    default:
      return de;
  }
}

String? _localizeContext(String? context, String lang) {
  if (context == null || context.isEmpty) return null;
  if (lang == 'de') return context;
  return switch (context) {
    'Route berechnen' => switch (lang) {
        'fr' => 'Calculer l’itinéraire',
        'it' => 'Calcola itinerario',
        'nl' => 'Route berekenen',
        _ => 'Calculate route',
      },
    'Quick-Route' => switch (lang) {
        'fr' => 'Itinéraire rapide',
        'it' => 'Percorso rapido',
        'nl' => 'Snelle route',
        _ => 'Quick route',
      },
    'Routing' => 'Routing',
    'Trail-Ansicht' => switch (lang) {
        'fr' => 'Vue sentier',
        'it' => 'Vista sentiero',
        'nl' => 'Trailweergave',
        _ => 'Trail view',
      },
    _ => context,
  };
}
