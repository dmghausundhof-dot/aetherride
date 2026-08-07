import '../bike.dart';
import '../setup.dart';

/// F-SET-002 Setup-Vorlagen (Port src/lib/setup/templates.ts).
class SetupTemplate {
  const SetupTemplate({
    required this.id,
    required this.label,
    required this.conditions,
    required this.kind,
    required this.disclaimer,
    required this.sourceLabel,
    this.categories,
    required this.resolve,
  });

  final String id;
  final String label;
  final String conditions;
  final String kind; // oem_weight_table | editorial_preset
  final String disclaimer;
  final String sourceLabel;
  final List<BikeCategory>? categories;
  final Map<String, double> Function(double weightKg, BikeCategory category)
      resolve;

  bool matches(BikeCategory category) {
    final cats = categories;
    if (cats == null || cats.isEmpty) return true;
    return cats.contains(category);
  }

  List<SetupValue> toValues(double weightKg, BikeCategory category) {
    final map = resolve(weightKg, category);
    return [
      for (final e in map.entries)
        SetupValue(
          adjusterKey: e.key,
          valueNum: e.value,
          unit: e.key.contains('pressure') || e.key.contains('psi')
              ? 'psi'
              : e.key.contains('sag')
                  ? 'pct'
                  : 'clicks',
        ),
    ];
  }
}

double _fox36Psi(double weightKg) {
  final clamped = weightKg.clamp(54.0, 113.0);
  return (64 + ((clamped - 54) / (113 - 54)) * (120 - 64)).roundToDouble();
}

double _weightLbs(double weightKg) => (weightKg * 2.205).roundToDouble();

double _foxX2ShockPsi(double weightKg) =>
    _weightLbs(weightKg).clamp(0, 300).toDouble();

({int lsr, int hsr, int lsc, int hsc}) _foxX2Clicks(double psi) {
  const table = <List<int>>[
    [90, 17, 8, 17, 8],
    [120, 14, 7, 16, 7],
    [150, 11, 6, 14, 6],
    [180, 8, 5, 12, 5],
    [210, 7, 4, 9, 4],
    [240, 4, 3, 6, 3],
    [270, 2, 2, 3, 3],
    [300, 1, 1, 2, 2],
  ];
  var best = table.first;
  for (final row in table) {
    if ((row[0] - psi).abs() < (best[0] - psi).abs()) best = row;
  }
  return (lsr: best[1], hsr: best[2], lsc: best[3], hsc: best[4]);
}

double _rockShoxForkPsi(double weightKg, BikeCategory category) {
  final w = weightKg.clamp(55.0, 105.0);
  final base = 38 + ((w - 55) / 50) * 50;
  if (category == BikeCategory.mtbEnduro ||
      category == BikeCategory.dh ||
      category == BikeCategory.emtb) {
    return (base - 5).roundToDouble();
  }
  if (category == BikeCategory.mtbTrail) return (base + 2).roundToDouble();
  return base.roundToDouble();
}

final List<SetupTemplate> setupTemplates = [
  SetupTemplate(
    id: 'tpl-fox-oem-base',
    label: 'Fox OEM Basis (Gewichtstabelle)',
    conditions: 'general',
    kind: 'oem_weight_table',
    disclaimer:
        'Ausgangspunkt laut Fox Starting-Points — keine persönliche Empfehlung.',
    sourceLabel: 'Fox Owner\'s Manual',
    categories: [
      BikeCategory.mtbTrail,
      BikeCategory.mtbAm,
      BikeCategory.mtbEnduro,
      BikeCategory.emtb,
      BikeCategory.dh,
    ],
    resolve: (w, cat) {
      final sagF = cat == BikeCategory.mtbEnduro ||
              cat == BikeCategory.dh ||
              cat == BikeCategory.emtb
          ? 23.0
          : 22.0;
      final sagR = cat == BikeCategory.mtbEnduro ||
              cat == BikeCategory.dh ||
              cat == BikeCategory.emtb
          ? 30.0
          : 28.0;
      final shockPsi = _foxX2ShockPsi(w);
      final clicks = _foxX2Clicks(shockPsi);
      return {
        'fork.air_pressure_psi': _fox36Psi(w),
        'fork.sag_pct': sagF,
        'fork.rebound': (18 - w / 10).round().clamp(4, 14).toDouble(),
        'fork.lsc': 6,
        'fork.hsc': 4,
        'rear_shock.air_pressure_psi': shockPsi,
        'rear_shock.sag_pct': sagR,
        'rear_shock.rebound': clicks.lsr.toDouble(),
        'rear_shock.hsr': clicks.hsr.toDouble(),
        'rear_shock.lsc': clicks.lsc.toDouble(),
        'rear_shock.hsc': clicks.hsc.toDouble(),
        'tire_front.pressure_psi': w > 85 ? 24 : 22,
        'tire_rear.pressure_psi': w > 85 ? 26 : 24,
      };
    },
  ),
  SetupTemplate(
    id: 'tpl-rockshox-sag-start',
    label: 'RockShox SAG-Start',
    conditions: 'general',
    kind: 'oem_weight_table',
    disclaimer: 'Näherung an TrailHead — dann auf 25–30 % SAG trimmen.',
    sourceLabel: 'RockShox FAQ · TrailHead',
    categories: [
      BikeCategory.mtbTrail,
      BikeCategory.mtbAm,
      BikeCategory.mtbEnduro,
      BikeCategory.emtb,
    ],
    resolve: (w, cat) => {
      'fork.air_pressure_psi': _rockShoxForkPsi(w, cat),
      'fork.sag_pct':
          cat == BikeCategory.mtbEnduro || cat == BikeCategory.emtb ? 22 : 18,
      'rear_shock.air_pressure_psi': _weightLbs(w),
      'rear_shock.sag_pct': 30,
      'fork.rebound': 8,
      'rear_shock.rebound': 9,
      'tire_front.pressure_psi': 22,
      'tire_rear.pressure_psi': 24,
    },
  ),
  SetupTemplate(
    id: 'tpl-editorial-wet-roots',
    label: 'Editorial: Nasse Roots',
    conditions: 'wet',
    kind: 'editorial_preset',
    disclaimer: 'Redaktions-Preset — Ausgangspunkt, kein Bracketing-Ersatz.',
    sourceLabel: 'AetherRide Editorial',
    categories: [
      BikeCategory.mtbAm,
      BikeCategory.mtbEnduro,
      BikeCategory.emtb,
    ],
    resolve: (w, _) => {
      'fork.air_pressure_psi': _fox36Psi(w) - 4,
      'fork.sag_pct': 28,
      'fork.rebound': 10,
      'fork.lsc': 4,
      'rear_shock.sag_pct': 32,
      'rear_shock.rebound': 12,
      'tire_front.pressure_psi': 20,
      'tire_rear.pressure_psi': 22,
    },
  ),
  SetupTemplate(
    id: 'tpl-editorial-bikepark',
    label: 'Editorial: Bikepark',
    conditions: 'bikepark',
    kind: 'editorial_preset',
    disclaimer: 'Ausgangspunkt für Park — mehr Support.',
    sourceLabel: 'AetherRide Editorial',
    categories: [
      BikeCategory.mtbEnduro,
      BikeCategory.dh,
      BikeCategory.emtb,
    ],
    resolve: (w, _) => {
      'fork.air_pressure_psi': _fox36Psi(w) + 6,
      'fork.sag_pct': 20,
      'fork.hsc': 6,
      'fork.lsc': 8,
      'rear_shock.sag_pct': 28,
      'rear_shock.lsc': 7,
      'tire_front.pressure_psi': 26,
      'tire_rear.pressure_psi': 28,
    },
  ),
];

List<SetupTemplate> templatesFor(BikeCategory category) =>
    setupTemplates.where((t) => t.matches(category)).toList();
