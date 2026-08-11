import '../bike.dart';

/// Dauer-Lens für Discover (D-60-01): ~60 Min Default, ehrliche Bänder.
class DurationPreset {
  const DurationPreset(this.minutes, this.label);
  /// 0 = „egal“ (kein Dauer-Filter).
  final int minutes;
  final String label;
}

class DurationLens {
  DurationLens._();

  /// Chip-Presets: ~45 · **~60** · ~90 · 2–3 h · egal
  static const presets = <DurationPreset>[
    DurationPreset(45, '~45'),
    DurationPreset(60, '~60'),
    DurationPreset(90, '~90'),
    DurationPreset(150, '2–3 h'),
    DurationPreset(0, 'egal'),
  ];

  /// Default-Minuten nach Sport. Touring-ähnlich (E-Trekking) → 2–3 h,
  /// sonst ~60. Unklar → 60.
  static int defaultMinutesForSport(BikeCategory? category) {
    if (category == BikeCategory.etrekking) return 150;
    return 60;
  }

  /// Filter-Band um das Zielbudget. Für „~60“: 45–75 Min (Spec).
  static bool inBand(int durationMin, int targetMinutes) {
    if (targetMinutes <= 0) return true;
    if (durationMin <= 0) return false;
    return switch (targetMinutes) {
      45 => durationMin >= 30 && durationMin <= 60,
      60 => durationMin >= 45 && durationMin <= 75,
      90 => durationMin >= 60 && durationMin <= 120,
      150 => durationMin >= 100 && durationMin <= 200,
      _ => (durationMin - targetMinutes).abs() <=
          (targetMinutes * 0.35).round().clamp(20, 60),
    };
  }

  /// Sortier-Score: kleiner = besserer Duration-Fit.
  static int fitDelta(int durationMin, int targetMinutes) {
    if (targetMinutes <= 0) return 0;
    return (durationMin - targetMinutes).abs();
  }

  static String chipLabel(int minutes) {
    for (final p in presets) {
      if (p.minutes == minutes) return p.label;
    }
    if (minutes <= 0) return 'egal';
    return '~$minutes';
  }
}
