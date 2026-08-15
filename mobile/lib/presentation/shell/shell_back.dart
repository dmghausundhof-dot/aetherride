import 'shell_tabs.dart';

/// What the Android system-back / predictive-back gesture should do
/// when [AppShell] is the current route (modals and pushed pages pop first).
enum ShellBackDecision {
  /// Hof at root — Android may finish the activity.
  systemPop,

  /// Non-Hof tab at its own root — switch to Der Hof.
  goHof,

  /// Overlay, inner map/HUD state, or onboarding consumed the back.
  inner,
}

abstract final class ShellBack {
  static ShellBackDecision resolve({
    required int tabIndex,
    required bool onboardingOpen,
    required bool tabHasInnerBack,
  }) {
    if (onboardingOpen) return ShellBackDecision.inner;
    if (tabHasInnerBack) return ShellBackDecision.inner;
    if (ShellTabs.stackIndex(tabIndex) != ShellTabs.hof) {
      return ShellBackDecision.goHof;
    }
    return ShellBackDecision.systemPop;
  }

  static bool allowSystemPop({
    required int tabIndex,
    required bool onboardingOpen,
    required bool tabHasInnerBack,
  }) =>
      resolve(
        tabIndex: tabIndex,
        onboardingOpen: onboardingOpen,
        tabHasInnerBack: tabHasInnerBack,
      ) ==
      ShellBackDecision.systemPop;
}
