import 'package:geolocator/geolocator.dart';

/// Cached GPS only — never [Geolocator.getCurrentPosition].
///
/// Fresh GNSS on first Discover/Hof paint can ANR: Android
/// `NmeaClient.stop` → `LocationManager.removeNmeaListener` on the UI thread.
Future<Position?> readCachedPosition({
  Duration maxAge = const Duration(minutes: 8),
}) async {
  try {
    final last = await Geolocator.getLastKnownPosition();
    if (last == null) return null;
    if (DateTime.now().difference(last.timestamp) > maxAge) return null;
    return last;
  } catch (_) {
    return null;
  }
}

/// User-started locate (FAB / Hof tap). Medium accuracy, short timeout.
///
/// Falls back to a slightly older cache if GNSS is slow.
Future<Position?> readFreshPosition({
  Duration timeLimit = const Duration(seconds: 8),
  Duration cacheFallbackAge = const Duration(minutes: 15),
}) async {
  try {
    return await Geolocator.getCurrentPosition(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: timeLimit,
      ),
    );
  } catch (_) {
    return readCachedPosition(maxAge: cacheFallbackAge);
  }
}
