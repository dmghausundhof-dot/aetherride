import '../setup.dart';

/// Kompakte Setup-Anzeige (Port SetupFingerprint.tsx).
class SetupFingerprint {
  const SetupFingerprint({
    required this.lines,
    this.conditionLabel,
  });

  final List<String> lines;
  final String? conditionLabel;

  static SetupFingerprint fromSetup(BikeSetup? setup) {
    if (setup == null) {
      return const SetupFingerprint(lines: ['Kein Setup']);
    }
    String? sag;
    String? fork;
    String? tire;
    for (final v in setup.values) {
      final k = v.adjusterKey.toLowerCase();
      if (k.contains('sag') && sag == null) {
        sag = 'SAG ${v.valueNum.toStringAsFixed(0)}%';
      }
      if (k.contains('fork') &&
          (k.contains('air') || k.contains('pressure') || k.contains('psi')) &&
          fork == null) {
        fork = 'Gabel ${v.valueNum.toStringAsFixed(0)} psi';
      }
      if (fork == null && k.contains('fork') && k.contains('rebound')) {
        fork = 'Gabel Rebound ${v.valueNum.toStringAsFixed(0)}';
      }
      if (k.contains('tire') &&
          k.contains('front') &&
          (k.contains('pressure') || k.contains('psi')) &&
          tire == null) {
        // Values are stored as psi (tire_*.pressure_psi). Labelling the raw
        // number as "bar" produced absurd readings (e.g. 22 bar ≈ 319 psi).
        tire = 'Reifen ${v.valueNum.toStringAsFixed(0)} psi';
      }
    }
    final lines = <String>[
      if (sag != null) sag,
      if (fork != null) fork,
      if (tire != null) tire,
      if (sag == null && fork == null) setup.label,
    ];
    return SetupFingerprint(
      lines: lines.isEmpty ? [setup.label] : lines,
      conditionLabel: setup.conditions,
    );
  }
}
