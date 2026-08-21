import '../bike.dart';
import '../setup.dart';

/// psi pro bar — UI rechnet um; Speicher bleibt `tire_*.pressure_psi`.
const psiPerBar = 14.503773773;

enum PressureUnitPref { auto, bar, psi }

PressureUnitPref pressureUnitPrefFrom(String? raw) {
  return switch ((raw ?? '').trim().toLowerCase()) {
    'bar' => PressureUnitPref.bar,
    'psi' => PressureUnitPref.psi,
    _ => PressureUnitPref.auto,
  };
}

/// MTB/E-MTB/DH: psi. Alltag, Gravel, Rennrad, Trekking: bar.
bool pressureUsesBar(BikeCategory category) => switch (category) {
      BikeCategory.mtbTrail ||
      BikeCategory.mtbAm ||
      BikeCategory.mtbEnduro ||
      BikeCategory.dh ||
      BikeCategory.emtb =>
        false,
      _ => true,
    };

bool resolvePressureUsesBar(
  BikeCategory category, [
  PressureUnitPref pref = PressureUnitPref.auto,
]) {
  return switch (pref) {
    PressureUnitPref.bar => true,
    PressureUnitPref.psi => false,
    PressureUnitPref.auto => pressureUsesBar(category),
  };
}

String pressureUnitLabel(
  BikeCategory category, [
  PressureUnitPref pref = PressureUnitPref.auto,
]) =>
    resolvePressureUsesBar(category, pref) ? 'bar' : 'psi';

double barToPsi(double bar) => (bar * psiPerBar * 10).round() / 10;

double psiToBar(double psi) => (psi / psiPerBar * 10).round() / 10;

/// Getipptes Feld → gespeicherte psi.
double enteredPressureToPsi(
  double entered,
  BikeCategory category, [
  PressureUnitPref pref = PressureUnitPref.auto,
]) =>
    resolvePressureUsesBar(category, pref) ? barToPsi(entered) : entered;

({double? front, double? rear}) loggedTirePsi(Iterable<BikeSetup> setups) {
  double? front;
  double? rear;
  for (final s in setups) {
    front ??= s.valueFor('tire_front.pressure_psi');
    rear ??= s.valueFor('tire_rear.pressure_psi');
    if (front != null && rear != null) break;
  }
  return (front: front, rear: rear);
}

String formatPressureValue(
  double psi, {
  required bool usesBar,
}) {
  return usesBar ? psiToBar(psi).toStringAsFixed(1) : psi.round().toString();
}

/// z. B. `1.8 / 2.0 bar` oder `26 psi`.
String? formatLoggedTirePressure(
  Iterable<BikeSetup> setups, {
  required bool usesBar,
}) {
  final pair = loggedTirePsi(setups);
  if (pair.front == null && pair.rear == null) return null;
  final unit = usesBar ? 'bar' : 'psi';
  if (pair.front != null && pair.rear != null) {
    return '${formatPressureValue(pair.front!, usesBar: usesBar)} / ${formatPressureValue(pair.rear!, usesBar: usesBar)} $unit';
  }
  final one = pair.front ?? pair.rear!;
  return '${formatPressureValue(one, usesBar: usesBar)} $unit';
}
