/// Kompat-Engine — Spiegel src/lib/compatibility/engine.ts (ohne Katalog-Modelle).
/// Attribute kommen aus BikeComponent.attributes; fehlende Keys → INSUFFICIENT_DATA.

import '../component.dart';
import 'rules.dart';

dynamic _read(Map<String, dynamic> attrs, String key) {
  if (!attrs.containsKey(key)) return null;
  final v = attrs[key];
  if (v == null) return null;
  if (v == 'n/a') return 'n/a';
  return v;
}

bool _tireRimCompatible(num tireWidthMm, num rimInnerMm) {
  final min = rimInnerMm * 1.4;
  final max = rimInnerMm * 2.4;
  return tireWidthMm >= min && tireWidthMm <= max;
}

String _fill(
  String template,
  Map<String, dynamic> a,
  Map<String, dynamic> b,
) {
  return template
      .replaceAllMapped(
        RegExp(r'\{a\.(\w+)\}'),
        (m) => '${_read(a, m[1]!) ?? '?'}',
      )
      .replaceAllMapped(
        RegExp(r'\{b\.(\w+)\}'),
        (m) => '${_read(b, m[1]!) ?? '?'}',
      );
}

({bool pass, bool conditional}) _evaluatePredicate(
  CompatibilityRuleDef rule,
  Map<String, dynamic> mapA,
  Map<String, dynamic> mapB,
) {
  switch (rule.predicate) {
    case 'equals':
      final va = _read(mapA, rule.requiresA.first);
      final vb = _read(mapB, rule.requiresB.first);
      if (va == 'n/a' && vb == 'n/a') return (pass: true, conditional: false);
      if (va == 'n/a' || vb == 'n/a') return (pass: false, conditional: false);
      return (pass: '$va' == '$vb', conditional: false);
    case 'shock_fit':
      const pairs = [
        ('eye_to_eye_mm', 'shock_eye_to_eye_mm'),
        ('stroke_mm', 'shock_stroke_mm'),
        ('mount_type', 'shock_mount_type'),
      ];
      var pass = true;
      for (final (ka, kb) in pairs) {
        if ('${_read(mapA, ka)}' != '${_read(mapB, kb)}') pass = false;
      }
      return (pass: pass, conditional: false);
    case 'tire_rim_fit':
      final tire = num.tryParse('${_read(mapA, 'tire_width_mm')}') ?? 0;
      final rim = num.tryParse('${_read(mapB, 'internal_rim_width_mm')}') ?? 0;
      final pass = _tireRimCompatible(tire, rim);
      return (pass: pass, conditional: pass);
    case 'rotor_within_max':
      final valA =
          num.tryParse('${_read(mapA, rule.requiresA.first)}') ?? 0;
      final maxB =
          num.tryParse('${_read(mapB, rule.requiresB.first)}') ?? 0;
      return (pass: valA <= maxB, conditional: false);
    case 'seatpost_fit':
      final diaA =
          num.tryParse('${_read(mapA, 'seatpost_diameter_mm')}') ?? -1;
      final diaB =
          num.tryParse('${_read(mapB, 'seatpost_diameter_mm')}') ?? -2;
      final minIns =
          num.tryParse('${_read(mapA, 'min_insertion_mm')}') ?? 0;
      final maxIns =
          num.tryParse('${_read(mapB, 'max_seatpost_insertion_mm')}') ?? 0;
      return (pass: diaA == diaB && minIns <= maxIns, conditional: false);
    default:
      return (pass: false, conditional: false);
  }
}

BikeComponent? _installed(List<BikeComponent> comps, ComponentSlot slot) {
  for (final c in comps) {
    if (c.slot == slot && c.isInstalled) return c;
  }
  return null;
}

String? _workshopHint(CompatibilityRuleDef rule) {
  if (rule.severity == RuleSeverity.safetyCritical) {
    return 'Sicherheitsrelevante Montage: Fachwerkstatt. Drehmomente nur aus Herstellerdokumenten.';
  }
  return null;
}

CompatibilityResult? evaluateRule(
  List<BikeComponent> components,
  CompatibilityRuleDef rule,
) {
  final compA = _installed(components, rule.slotA);
  final compB = _installed(components, rule.slotB);
  if (compA == null || compB == null) return null;

  // Freitext ohne Attribute → INSUFFICIENT_DATA (Spec: nicht raten)
  if (compA.attributes.isEmpty && compA.catalogModelId == null ||
      compB.attributes.isEmpty && compB.catalogModelId == null) {
    // still allow if attributes present on both
  }

  final mapA = Map<String, dynamic>.from(compA.attributes);
  final mapB = Map<String, dynamic>.from(compB.attributes);

  final missing = <({String key, String howToObtain})>[];
  for (final key in rule.requiresA) {
    if (_read(mapA, key) == null) {
      missing.add((
        key: '${rule.slotA.apiId}.$key',
        howToObtain: rule.howToObtain[key] ?? 'Herstellerdatenblatt prüfen',
      ));
    }
  }
  for (final key in rule.requiresB) {
    if (_read(mapB, key) == null) {
      missing.add((
        key: '${rule.slotB.apiId}.$key',
        howToObtain: rule.howToObtain[key] ?? 'Herstellerdatenblatt prüfen',
      ));
    }
  }
  if (missing.isNotEmpty) {
    return CompatibilityResult(
      verdict: CompatVerdict.insufficientData,
      ruleCode: rule.code,
      title: rule.title,
      severity: rule.severity,
      explainDe:
          'Fehlende Attribute — kein COMPATIBLE ohne vollständige Faktenlage.',
      missingAttributes: missing,
      safetyWorkshopHint: _workshopHint(rule),
      sourceUrl: rule.sourceUrl,
    );
  }

  final eval = _evaluatePredicate(rule, mapA, mapB);
  if (eval.pass) {
    return CompatibilityResult(
      verdict: eval.conditional
          ? CompatVerdict.conditional
          : rule.onPass,
      ruleCode: rule.code,
      title: rule.title,
      severity: rule.severity,
      explainDe: eval.conditional
          ? (rule.conditionText ?? 'Bedingt kompatibel')
          : 'Regel erfüllt.',
      conditionText: rule.conditionText,
      safetyWorkshopHint: _workshopHint(rule),
      sourceUrl: rule.sourceUrl,
    );
  }
  return CompatibilityResult(
    verdict: rule.onFail,
    ruleCode: rule.code,
    title: rule.title,
    severity: rule.severity,
    explainDe: _fill(rule.explainFailDe, mapA, mapB),
    conditionText: rule.conditionText,
    safetyWorkshopHint: _workshopHint(rule),
    sourceUrl: rule.sourceUrl,
  );
}

List<CompatibilityResult> checkBikeCompatibility(
  List<BikeComponent> components,
) {
  final out = <CompatibilityResult>[];
  for (final rule in compatibilityRules) {
    final r = evaluateRule(components, rule);
    if (r != null) out.add(r);
  }
  return out;
}

/// Kandidat (z. B. Shop-Produkt) gegen installierte Teile prüfen.
/// Ersetzt den Slot des Kandidaten und wertet nur betroffene Regeln aus.
List<CompatibilityResult> checkCandidateOnBike(
  List<BikeComponent> installed,
  BikeComponent candidate,
) {
  final comps = <BikeComponent>[
    for (final c in installed)
      if (c.slot != candidate.slot) c,
    candidate,
  ];
  final out = <CompatibilityResult>[];
  for (final rule in compatibilityRules) {
    if (rule.slotA != candidate.slot && rule.slotB != candidate.slot) {
      continue;
    }
    final r = evaluateRule(comps, rule);
    if (r != null) out.add(r);
  }
  return out;
}

CompatVerdict aggregateVerdict(List<CompatibilityResult> results) {
  if (results.isEmpty) return CompatVerdict.insufficientData;
  var worst = CompatVerdict.compatible;
  for (final r in results) {
    worst = _worse(worst, r.verdict);
  }
  return worst;
}

CompatVerdict _worse(CompatVerdict a, CompatVerdict b) {
  int rank(CompatVerdict v) => switch (v) {
        CompatVerdict.incompatible => 3,
        CompatVerdict.insufficientData => 2,
        CompatVerdict.conditional => 1,
        CompatVerdict.compatible => 0,
      };
  return rank(b) > rank(a) ? b : a;
}

String verdictLabel(CompatVerdict v) => switch (v) {
      CompatVerdict.compatible => 'Kompatibel',
      CompatVerdict.conditional => 'Bedingt',
      CompatVerdict.incompatible => 'Inkompatibel',
      CompatVerdict.insufficientData => 'Daten fehlen',
    };
