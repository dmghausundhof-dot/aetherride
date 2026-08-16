/// Top-level Discover map-shell modes — Komoot-like IA for one map + sheet.
///
/// - [explore]: catalog loops, trails, duration lens, filters
/// - [navigate]: classic A→B bike navigation (start / destination / vias)
/// - [mine]: UGC / saved / recorded / imported tracks („Meine Strecken“)
enum DiscoverShellMode {
  explore,
  navigate,
  mine,
}

/// Pure helpers for shell-mode UX (unit-tested; no Flutter widget deps).
abstract final class DiscoverShellModeLogic {
  /// Sheet uses the draggable Discover snaps (Peek/Half/Full).
  static bool usesBrowseSheet(DiscoverShellMode mode) =>
      mode == DiscoverShellMode.explore || mode == DiscoverShellMode.mine;

  /// Fixed-height plan-style panel (keyboard-friendly address fields).
  static bool usesFixedNavPanel(DiscoverShellMode mode) =>
      mode == DiscoverShellMode.navigate;

  /// Catalog tour list + primary filter chips live here.
  static bool showsTourCatalog(DiscoverShellMode mode) =>
      mode == DiscoverShellMode.explore;

  /// Saved/UGC list is the primary content (not buried under tours).
  static bool showsMineList(DiscoverShellMode mode) =>
      mode == DiscoverShellMode.mine;

  /// Start/destination fields + route compute.
  static bool showsNavigateForm(DiscoverShellMode mode) =>
      mode == DiscoverShellMode.navigate;

  /// Compass (time + heading) lives in Navigieren, not the tour catalog.
  static bool showsCompassAction(DiscoverShellMode mode) =>
      mode == DiscoverShellMode.navigate;

  /// Old N/O/SW heading cards must not sit among catalog/seed tours.
  static bool get showsHeadingCardsInTourCatalog => false;
}
