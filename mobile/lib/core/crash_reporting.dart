import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'config.dart';

/// Crash reporting. `SENTRY_DSN` empty → local hooks only, no events.
Future<void> runWithCrashReporting(Future<void> Function() appRunner) async {
  final dsn = AppConfig.sentryDsn.trim();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exceptionAsString()}');
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Uncaught: $error\n$stack');
    return true;
  };

  if (dsn.isEmpty) {
    await appRunner();
    return;
  }

  await SentryFlutter.init(
    (options) {
      options.dsn = dsn;
      options.environment = kReleaseMode ? 'release' : 'debug';
      options.sendDefaultPii = false;
      options.enableUserInteractionTracing = false;
      options.captureFailedRequests = false;
    },
    appRunner: appRunner,
  );
}
