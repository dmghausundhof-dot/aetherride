import 'dart:io';

import '../../../core/config.dart';

/// Debug APKs often talk to loopback via `adb reverse`. Wi-Fi DNS can
/// succeed while that hop is dead — those origins need a port probe.
bool apiOriginNeedsLoopbackProbe(String apiBaseUrl) {
  final host = Uri.tryParse(apiBaseUrl)?.host ?? '';
  return host == '127.0.0.1' || host == 'localhost' || host == '10.0.2.2';
}

int apiOriginPort(String apiBaseUrl, {int fallback = 80}) {
  final port = Uri.tryParse(apiBaseUrl)?.port ?? 0;
  return port == 0 ? fallback : port;
}

/// Lightweight online check for mid-ride reroute honesty (N-02b).
/// No fake replan when offline — map/TBT can still work from cache.
Future<bool> rideHasNetwork({
  Duration timeout = const Duration(seconds: 2),
}) async {
  try {
    final result = await InternetAddress.lookup('dns.google').timeout(timeout);
    if (result.isEmpty || result.first.rawAddress.isEmpty) return false;
  } on SocketException {
    return false;
  } on Exception {
    return false;
  }

  if (apiOriginNeedsLoopbackProbe(AppConfig.apiBaseUrl)) {
    final port = apiOriginPort(AppConfig.apiBaseUrl);
    try {
      final socket = await Socket.connect(
        Uri.parse(AppConfig.apiBaseUrl).host,
        port,
        timeout: timeout,
      );
      socket.destroy();
    } catch (_) {
      return false;
    }
  }
  return true;
}
