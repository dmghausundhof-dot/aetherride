import { getComponentModel } from "@/lib/catalog/components";
import { isSafetyCriticalSlot } from "@/lib/catalog/slots";
import {
  COMPATIBILITY_RULES,
  type CompatibilityRuleDef,
} from "@/lib/compatibility/rules";
import type {
  Bike,
  BikeComponent,
  CompatibilityResult,
  CompatibilityVerdict,
  ComponentModel,
  ComponentSlot,
  EvidenceItem,
  TypedAttribute,
} from "@/types/garage";

function attrMap(attrs: TypedAttribute[]): Map<string, TypedAttribute> {
  return new Map(attrs.map((a) => [a.key, a]));
}

function resolveAttrs(
  component: BikeComponent | undefined,
  model: ComponentModel | undefined
): Map<string, TypedAttribute> {
  const merged = new Map<string, TypedAttribute>();
  if (model) {
    for (const a of model.attributes) merged.set(a.key, a);
  }
  if (component) {
    for (const a of component.attributes) merged.set(a.key, a);
  }
  return merged;
}

function getInstalled(bike: Bike, slot: ComponentSlot): BikeComponent | undefined {
  return bike.components.find((c) => c.slot === slot && !c.removedAt);
}

function readValue(
  map: Map<string, TypedAttribute>,
  key: string
): string | number | undefined {
  const a = map.get(key);
  if (!a) return undefined;
  if (a.notApplicable || a.valueEnum === "n/a" || a.valueText === "n/a") {
    return "n/a";
  }
  if (a.valueEnum !== undefined) return a.valueEnum;
  if (a.valueNum !== undefined) return a.valueNum;
  if (a.valueText !== undefined) return a.valueText;
  return undefined;
}

function missingList(
  rule: CompatibilityRuleDef,
  mapA: Map<string, TypedAttribute>,
  mapB: Map<string, TypedAttribute>
): { key: string; howToObtain: string }[] {
  const missing: { key: string; howToObtain: string }[] = [];
  for (const key of rule.requiresA) {
    if (readValue(mapA, key) === undefined) {
      missing.push({
        key: `${rule.slotA}.${key}`,
        howToObtain: rule.howToObtain[key] ?? "Herstellerdatenblatt prüfen",
      });
    }
  }
  for (const key of rule.requiresB) {
    if (readValue(mapB, key) === undefined) {
      missing.push({
        key: `${rule.slotB}.${key}`,
        howToObtain: rule.howToObtain[key] ?? "Herstellerdatenblatt prüfen",
      });
    }
  }
  return missing;
}

/** Praxis-Tabelle: Reifenbreite sollte ca. 1,4–2,4 × innere Felgenmaulweite sein */
function tireRimCompatible(tireWidthMm: number, rimInnerMm: number): boolean {
  const min = rimInnerMm * 1.4;
  const max = rimInnerMm * 2.4;
  return tireWidthMm >= min && tireWidthMm <= max;
}

function fillTemplate(
  template: string,
  a: Map<string, TypedAttribute>,
  b: Map<string, TypedAttribute>
): string {
  return template
    .replace(/\{a\.(\w+)\}/g, (_, k) => String(readValue(a, k) ?? "?"))
    .replace(/\{b\.(\w+)\}/g, (_, k) => String(readValue(b, k) ?? "?"));
}

function evaluatePredicate(
  rule: CompatibilityRuleDef,
  mapA: Map<string, TypedAttribute>,
  mapB: Map<string, TypedAttribute>
): { pass: boolean; conditional?: boolean; evidence: EvidenceItem[] } {
  const evidence: EvidenceItem[] = [];

  if (rule.predicate === "equals") {
    const keyA = rule.requiresA[0];
    const keyB = rule.requiresB[0];
    const va = readValue(mapA, keyA);
    const vb = readValue(mapB, keyB);
    const attrA = mapA.get(keyA);
    const attrB = mapB.get(keyB);
    evidence.push({
      ruleCode: rule.code,
      attributeKey: keyA,
      valueA: va,
      valueB: vb,
      sourceA: attrA?.source,
      sourceB: attrB?.source,
      verifiedAtA: attrA?.verifiedAt,
      verifiedAtB: attrB?.verifiedAt,
    });
    // n/a auf Rahmen bei Motor = kein E-Bike → Motor-Slot sollte nicht belegt sein;
    // wenn Motor fehlt, wird Regel übersprungen. Wenn beide n/a: pass.
    if (va === "n/a" && vb === "n/a") return { pass: true, evidence };
    if (va === "n/a" || vb === "n/a") return { pass: false, evidence };
    return { pass: String(va) === String(vb), evidence };
  }

  if (rule.predicate === "shock_fit") {
    const pairs: [string, string][] = [
      ["eye_to_eye_mm", "shock_eye_to_eye_mm"],
      ["stroke_mm", "shock_stroke_mm"],
      ["mount_type", "shock_mount_type"],
    ];
    let pass = true;
    for (const [ka, kb] of pairs) {
      const va = readValue(mapA, ka);
      const vb = readValue(mapB, kb);
      evidence.push({
        ruleCode: rule.code,
        attributeKey: ka,
        valueA: va,
        valueB: vb,
        sourceA: mapA.get(ka)?.source,
        sourceB: mapB.get(kb)?.source,
      });
      if (String(va) !== String(vb)) pass = false;
    }
    return { pass, evidence };
  }

  if (rule.predicate === "tire_rim_fit") {
    const tire = Number(readValue(mapA, "tire_width_mm"));
    const rim = Number(readValue(mapB, "internal_rim_width_mm"));
    evidence.push({
      ruleCode: rule.code,
      attributeKey: "tire_width_mm",
      valueA: tire,
      valueB: rim,
      note: "Fallback-Tabelle 1,4–2,4× Maulweite (ohne OEM-Freigabe → CONDITIONAL bei Pass)",
      sourceA: mapA.get("tire_width_mm")?.source,
      sourceB: mapB.get("internal_rim_width_mm")?.source,
    });
    const pass = tireRimCompatible(tire, rim);
    return { pass, conditional: pass, evidence };
  }

  if (rule.predicate === "rotor_within_max") {
    // reuse: tire width vs max clearance OR rotor vs max
    const valA = Number(
      readValue(mapA, rule.requiresA[0]) ?? readValue(mapA, "rotor_diameter_mm")
    );
    const maxB = Number(readValue(mapB, rule.requiresB[0]));
    evidence.push({
      ruleCode: rule.code,
      attributeKey: rule.requiresA[0],
      valueA: valA,
      valueB: maxB,
      sourceA: mapA.get(rule.requiresA[0])?.source,
      sourceB: mapB.get(rule.requiresB[0])?.source,
    });
    return { pass: valA <= maxB, evidence };
  }

  if (rule.predicate === "seatpost_fit") {
    const diaA = Number(readValue(mapA, "seatpost_diameter_mm"));
    const diaB = Number(readValue(mapB, "seatpost_diameter_mm"));
    const minIns = Number(readValue(mapA, "min_insertion_mm") ?? 0);
    const maxIns = Number(readValue(mapB, "max_seatpost_insertion_mm") ?? 0);
    evidence.push({
      ruleCode: rule.code,
      attributeKey: "seatpost_diameter_mm",
      valueA: diaA,
      valueB: diaB,
    });
    evidence.push({
      ruleCode: rule.code,
      attributeKey: "min_insertion_mm",
      valueA: minIns,
      valueB: maxIns,
      note: "min. Einstecktiefe ≤ max. Rahmen-Einstecktiefe",
    });
    return { pass: diaA === diaB && minIns <= maxIns, evidence };
  }

  return { pass: false, evidence };
}

function workshopHint(slots: ComponentSlot[]): string | undefined {
  if (slots.some(isSafetyCriticalSlot)) {
    return "Sicherheitsrelevante Montage: von einer Fachwerkstatt ausführen lassen. Drehmomente ausschließlich aus Herstellerdokumenten – nie schätzen.";
  }
  return undefined;
}

export function evaluateRule(
  bike: Bike,
  rule: CompatibilityRuleDef,
  candidate?: { slot: ComponentSlot; modelId: string }
): CompatibilityResult | null {
  const compA =
    candidate && candidate.slot === rule.slotA
      ? undefined
      : getInstalled(bike, rule.slotA);
  const compB =
    candidate && candidate.slot === rule.slotB
      ? undefined
      : getInstalled(bike, rule.slotB);

  const modelA =
    candidate && candidate.slot === rule.slotA
      ? getComponentModel(candidate.modelId)
      : compA?.componentModelId
        ? getComponentModel(compA.componentModelId)
        : undefined;
  const modelB =
    candidate && candidate.slot === rule.slotB
      ? getComponentModel(candidate.modelId)
      : compB?.componentModelId
        ? getComponentModel(compB.componentModelId)
        : undefined;

  // Slot A oder B nicht vorhanden und kein Kandidat → Regel nicht anwenden
  const hasA =
    !!modelA ||
    !!compA?.componentModelId ||
    (compA && (compA.attributes.length > 0 || compA.freeText));
  const hasB =
    !!modelB ||
    !!compB?.componentModelId ||
    (compB && (compB.attributes.length > 0 || compB.freeText));

  if (!hasA || !hasB) return null;

  // Free-Text ohne Katalog → INSUFFICIENT_DATA (sperrt Kompat laut Spec)
  if (
    (compA && !compA.componentModelId && !candidate) ||
    (compB && !compB.componentModelId && !(candidate && candidate.slot === rule.slotB))
  ) {
    if (
      (compA && !compA.componentModelId && rule.slotA === compA.slot) ||
      (compB && !compB.componentModelId && rule.slotB === compB.slot)
    ) {
      return {
        verdict: "INSUFFICIENT_DATA",
        ruleCode: rule.code,
        title: rule.title,
        severity: rule.severity,
        explainDe:
          "Freitext-Komponente ohne Katalogbezug – Kompatibilitätsprüfung und Setup-Automatik gesperrt (F-GAR-002).",
        missingAttributes: [
          {
            key: "component_model_id",
            howToObtain: "Katalogmodell wählen statt Freitext",
          },
        ],
        evidence: [],
        safetyWorkshopHint: workshopHint([rule.slotA, rule.slotB]),
        torqueSpecs: [...(modelA?.torqueSpecs ?? []), ...(modelB?.torqueSpecs ?? [])],
        sourceUrl: rule.sourceUrl,
      };
    }
  }

  const mapA = resolveAttrs(
    candidate?.slot === rule.slotA ? undefined : compA,
    modelA
  );
  const mapB = resolveAttrs(
    candidate?.slot === rule.slotB ? undefined : compB,
    modelB
  );

  const missing = missingList(rule, mapA, mapB);
  if (missing.length > 0) {
    return {
      verdict: "INSUFFICIENT_DATA",
      ruleCode: rule.code,
      title: rule.title,
      severity: rule.severity,
      explainDe: `Fehlende Attribute – Engine rät nicht (F-GAR-003.1): ${missing
        .map((m) => m.key)
        .join(", ")}`,
      missingAttributes: missing,
      evidence: [],
      safetyWorkshopHint: workshopHint([rule.slotA, rule.slotB]),
      torqueSpecs: [...(modelA?.torqueSpecs ?? []), ...(modelB?.torqueSpecs ?? [])],
      sourceUrl: rule.sourceUrl,
    };
  }

  const { pass, conditional, evidence } = evaluatePredicate(rule, mapA, mapB);
  let verdict: CompatibilityVerdict;
  if (pass) {
    verdict =
      conditional || rule.onPass === "CONDITIONAL" ? "CONDITIONAL" : "COMPATIBLE";
  } else {
    verdict = rule.onFail;
  }

  return {
    verdict,
    ruleCode: rule.code,
    title: rule.title,
    severity: rule.severity,
    conditionText: verdict === "CONDITIONAL" ? rule.conditionText : undefined,
    explainDe: pass
      ? `${rule.title}: Prüfung bestanden.`
      : fillTemplate(rule.explainFailDe, mapA, mapB),
    missingAttributes: [],
    evidence,
    safetyWorkshopHint: workshopHint([rule.slotA, rule.slotB]),
    torqueSpecs: [...(modelA?.torqueSpecs ?? []), ...(modelB?.torqueSpecs ?? [])],
    sourceUrl: rule.sourceUrl,
  };
}

/** Aggregiertes Bike-Urteil: schlechtestes Einzelergebnis gewinnt */
export function aggregateVerdict(
  results: CompatibilityResult[]
): CompatibilityVerdict {
  if (results.some((r) => r.verdict === "INCOMPATIBLE")) return "INCOMPATIBLE";
  if (results.some((r) => r.verdict === "INSUFFICIENT_DATA"))
    return "INSUFFICIENT_DATA";
  if (results.some((r) => r.verdict === "CONDITIONAL")) return "CONDITIONAL";
  if (results.length === 0) return "INSUFFICIENT_DATA";
  return "COMPATIBLE";
}

export function checkBikeCompatibility(bike: Bike): CompatibilityResult[] {
  const results: CompatibilityResult[] = [];
  for (const rule of COMPATIBILITY_RULES) {
    const r = evaluateRule(bike, rule);
    if (r) results.push(r);
  }
  return results;
}

export function checkCandidateOnBike(
  bike: Bike,
  slot: ComponentSlot,
  modelId: string
): CompatibilityResult[] {
  const results: CompatibilityResult[] = [];
  for (const rule of COMPATIBILITY_RULES) {
    if (rule.slotA !== slot && rule.slotB !== slot) continue;
    const r = evaluateRule(bike, rule, { slot, modelId });
    if (r) results.push(r);
  }
  return results;
}

export function verdictLabel(v: CompatibilityVerdict): string {
  switch (v) {
    case "COMPATIBLE":
      return "Kompatibel";
    case "CONDITIONAL":
      return "Bedingt";
    case "INCOMPATIBLE":
      return "Inkompatibel";
    case "INSUFFICIENT_DATA":
      return "Daten fehlen";
  }
}

export function verdictColorClass(v: CompatibilityVerdict): string {
  switch (v) {
    case "COMPATIBLE":
      return "bg-success/20 text-success border-success/40";
    case "CONDITIONAL":
      return "bg-warning/20 text-warning border-warning/40";
    case "INCOMPATIBLE":
      return "bg-error/20 text-error border-error/40";
    case "INSUFFICIENT_DATA":
      return "bg-muted text-text-secondary border-border";
  }
}

export { attrMap };
