/**
 * Einsteiger-Default: eine Primäraktion in der Garage.
 * Priorität: Wartung → Teile → Aktiv setzen → Setup.
 */
export type GaragePrimaryAction =
  | "viewMaintenance"
  | "addPart"
  | "setActive"
  | "openSetup";

export function resolveGaragePrimaryAction(opts: {
  isActive: boolean;
  dueCount: number;
  partsCount: number;
}): GaragePrimaryAction {
  if (opts.dueCount > 0) return "viewMaintenance";
  if (opts.partsCount === 0) return "addPart";
  if (!opts.isActive) return "setActive";
  return "openSetup";
}

export function garagePrimaryActionLabelDe(a: GaragePrimaryAction): string {
  switch (a) {
    case "viewMaintenance":
      return "Wartung ansehen";
    case "addPart":
      return "Teil hinzufügen";
    case "setActive":
      return "Als aktiv setzen";
    case "openSetup":
      return "Zum Setup";
  }
}
