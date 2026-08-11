import 'dart:io';

/// Lightweight online check for mid-ride reroute honesty (N-02b).
/// No fake replan when offline — map/TBT can still work from cache.
Future<bool> rideHasNetwork({
  Duration timeout = const Duration(seconds: 2),
}) async {
  try {
    final result = await InternetAddress.lookup('dns.google').timeout(timeout);
    return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
  } on SocketException {
    return false;
  } on Exception {
    return false;
  }
}
