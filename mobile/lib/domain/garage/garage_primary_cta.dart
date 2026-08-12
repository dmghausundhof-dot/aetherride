/// Einsteiger-Default: genau eine Primäraktion in der Garage.
///
/// Priorität: Wartung → Teile erfassen → Aktiv setzen → Setup.
enum GaragePrimaryAction {
  viewMaintenance,
  addPart,
  setActive,
  openSetup,
}

GaragePrimaryAction resolveGaragePrimaryAction({
  required bool isActive,
  required int dueCount,
  required int partsCount,
}) {
  if (dueCount > 0) return GaragePrimaryAction.viewMaintenance;
  if (partsCount == 0) return GaragePrimaryAction.addPart;
  if (!isActive) return GaragePrimaryAction.setActive;
  return GaragePrimaryAction.openSetup;
}
