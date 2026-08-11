import 'package:aetherride_mobile/domain/routing/battery_preset.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RideBatteryPreset', () {
    test('default pocket has no keep-screen-on', () {
      const p = RideBatteryPreset.pocket;
      expect(p.keepScreenOn, isFalse);
      expect(p.wakeOnCue, isFalse);
      expect(p.costsBattery, isFalse);
      expect(p.titleDe, 'Pocket');
    });

    test('lenker keep-screen-on and costs battery', () {
      const p = RideBatteryPreset.lenker;
      expect(p.keepScreenOn, isTrue);
      expect(p.wakeOnCue, isFalse);
      expect(p.costsBattery, isTrue);
      expect(p.subtitleDe, contains('Display'));
    });

    test('ultra wake-on-cue and costs battery', () {
      const p = RideBatteryPreset.ultra;
      expect(p.keepScreenOn, isFalse);
      expect(p.wakeOnCue, isTrue);
      expect(p.costsBattery, isTrue);
    });

    test('fromId defaults to pocket', () {
      expect(RideBatteryPresetX.fromId(null), RideBatteryPreset.pocket);
      expect(RideBatteryPresetX.fromId('nope'), RideBatteryPreset.pocket);
      expect(RideBatteryPresetX.fromId('lenker'), RideBatteryPreset.lenker);
      expect(RideBatteryPresetX.fromId('ultra'), RideBatteryPreset.ultra);
    });
  });
}
