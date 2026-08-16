import '../bike.dart';

/// psi pro bar — UI rechnet um; Speicher bleibt `tire_*.pressure_psi`.
const psiPerBar = 14.503773773;

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

String pressureUnitLabel(BikeCategory category) =>
    pressureUsesBar(category) ? 'bar' : 'psi';

double barToPsi(double bar) => (bar * psiPerBar * 10).round() / 10;

double psiToBar(double psi) => (psi / psiPerBar * 10).round() / 10;

/// Getipptes Feld → gespeicherte psi.
double enteredPressureToPsi(double entered, BikeCategory category) =>
    pressureUsesBar(category) ? barToPsi(entered) : entered;
