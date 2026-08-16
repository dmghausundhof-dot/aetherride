import 'package:aetherride_mobile/presentation/ride/widgets/ride_network.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('apiOriginNeedsLoopbackProbe', () {
    test('probes debug loopback and emulator hosts', () {
      expect(
        apiOriginNeedsLoopbackProbe('http://127.0.0.1:3001'),
        isTrue,
      );
      expect(apiOriginNeedsLoopbackProbe('http://localhost:3001'), isTrue);
      expect(apiOriginNeedsLoopbackProbe('http://10.0.2.2:3001'), isTrue);
    });

    test('skips production HTTPS', () {
      expect(
        apiOriginNeedsLoopbackProbe('https://aetherride.vercel.app'),
        isFalse,
      );
    });
  });

  group('apiOriginPort', () {
    test('reads explicit port and falls back', () {
      expect(apiOriginPort('http://127.0.0.1:3001'), 3001);
      expect(apiOriginPort('http://localhost'), 80);
    });
  });
}
