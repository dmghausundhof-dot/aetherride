import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// Zentrale Übersetzung technischer Exceptions in kurze, deutsche
/// Nutzer-Meldungen — nie einen rohen `Exception`/`TimeoutException`-String
/// direkt in `_status`/`_error`-Felder durchreichen.
///
/// Ort bewusst zentral (nicht pro Screen dupliziert): jede neue Fehlerquelle
/// (Routing, Geocoding, Wetter, Sync, …) bekommt hier eine Zeile statt in
/// jedem `catch (e)` erneut Text zu basteln.
String friendlyErrorMessage(Object error, {String? context}) {
  final prefix = context == null ? '' : '$context — ';
  final msg = error.toString();

  if (error is TimeoutException) {
    return '${prefix}Zeitüberschreitung — Verbindung prüfen und erneut versuchen.';
  }
  if (error is SocketException ||
      msg.contains('SocketException') ||
      msg.contains('Failed host lookup') ||
      msg.contains('Connection refused') ||
      msg.contains('Network is unreachable')) {
    return '${prefix}Keine Verbindung — Internet prüfen.';
  }
  if (msg.contains('429') || msg.toLowerCase().contains('too many requests')) {
    return '${prefix}Zu viele Anfragen — kurz warten und erneut versuchen.';
  }
  final serverError = RegExp(r'\b5\d{2}\b').hasMatch(msg);
  if (serverError) {
    return '${prefix}Dienst vorübergehend nicht erreichbar — später erneut versuchen.';
  }
  if (msg.contains('404')) {
    return '${prefix}Nichts gefunden.';
  }
  if (error is FormatException || msg.contains('FormatException')) {
    return '${prefix}Antwort konnte nicht gelesen werden.';
  }

  // Fallback: nie den rohen Typnamen/Stacktrace-Fetzen zeigen — im Debug-Build
  // zur Fehlersuche trotzdem anhängen.
  final generic = '${prefix}Etwas ist schiefgelaufen — erneut versuchen.';
  return kDebugMode ? '$generic ($msg)' : generic;
}
