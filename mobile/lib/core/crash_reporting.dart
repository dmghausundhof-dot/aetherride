import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'config.dart';

/// Crash-Reporting-Scaffold.
/// Sentry wird erst eingebunden, wenn `SENTRY_DSN` gesetzt ist *und* das
/// Plugin build-kompatibel ist. Aktuell: lokale Error-Hooks (kein Extra-Plugin).
Future<void> runWithCrashReporting(Future<void> Function() appRunner) async {
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exceptionAsString()}');
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Uncaught: $error\n$stack');
    return true;
  };
  if (AppConfig.isCrashReportingConfigured) {
    debugPrint(
      'SENTRY_DSN gesetzt — Plugin-Build aktuell deaktiviert; '
      'Fehler werden lokal geloggt.',
    );
  }
  await appRunner();
}
