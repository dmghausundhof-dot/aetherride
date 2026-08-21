import '../garage/pressure_unit.dart';
import '../setup.dart';

/// Kompakte Setup-Anzeige (Port SetupFingerprint.tsx).
class SetupFingerprint {
  const SetupFingerprint({
    required this.lines,
    this.conditionLabel,
  });

  final List<String> lines;
  final String? conditionLabel;

  static SetupFingerprint fromSetup(
    BikeSetup? setup, {
    bool usesBar = true,
  }) {
    if (setup == null) {
      return const SetupFingerprint(lines: ['Kein Setup']);
    }
    String? sag;
    String? fork;
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
    }
    final tire = formatLoggedTirePressure([setup], usesBar: usesBar);
    final lines = <String>[
      if (tire != null) 'Reifen $tire',
      if (sag != null) sag,
      if (fork != null) fork,
      if (sag == null && fork == null && tire == null) setup.label,
    ];
    return SetupFingerprint(
      lines: lines.isEmpty ? [setup.label] : lines,
      conditionLabel: setup.conditions,
    );
  }
}
