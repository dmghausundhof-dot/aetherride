import 'package:flutter_test/flutter_test.dart';

import 'package:aetherride_mobile/domain/home/onboarding_gate.dart';

void main() {
  test('unknown or done never opens the overlay', () {
    expect(
      OnboardingGate.shouldShow(
        flaggedDone: null,
        hasBike: false,
        hasRide: false,
      ),
      isFalse,
    );
    expect(
      OnboardingGate.shouldShow(
        flaggedDone: true,
        hasBike: false,
        hasRide: false,
      ),
      isFalse,
    );
  });

  test('pending only if the yard is empty', () {
    expect(
      OnboardingGate.shouldShow(
        flaggedDone: false,
        hasBike: false,
        hasRide: false,
      ),
      isTrue,
    );
    expect(
      OnboardingGate.shouldShow(
        flaggedDone: false,
        hasBike: true,
        hasRide: false,
      ),
      isFalse,
    );
    expect(
      OnboardingGate.shouldShow(
        flaggedDone: false,
        hasBike: false,
        hasRide: true,
      ),
      isFalse,
    );
  });
}
