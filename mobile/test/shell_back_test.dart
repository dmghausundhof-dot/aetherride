import 'package:aetherride_mobile/presentation/shell/shell_back.dart';
import 'package:aetherride_mobile/presentation/shell/shell_tabs.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ShellBack', () {
    test('Hof at root may system-pop', () {
      expect(
        ShellBack.resolve(
          tabIndex: ShellTabs.hof,
          onboardingOpen: false,
          tabHasInnerBack: false,
        ),
        ShellBackDecision.systemPop,
      );
      expect(
        ShellBack.allowSystemPop(
          tabIndex: ShellTabs.hof,
          onboardingOpen: false,
          tabHasInnerBack: false,
        ),
        isTrue,
      );
    });

    test('Karte / Werkstatt / Shop at root go to Hof, never exit', () {
      for (final tab in [
        ShellTabs.karte,
        ShellTabs.werkstatt,
        ShellTabs.shop,
        ShellTabs.ride,
      ]) {
        expect(
          ShellBack.resolve(
            tabIndex: tab,
            onboardingOpen: false,
            tabHasInnerBack: false,
          ),
          ShellBackDecision.goHof,
          reason: 'tab $tab',
        );
        expect(
          ShellBack.allowSystemPop(
            tabIndex: tab,
            onboardingOpen: false,
            tabHasInnerBack: false,
          ),
          isFalse,
        );
      }
    });

    test('inner overlay / HUD consumes back before Hof', () {
      expect(
        ShellBack.resolve(
          tabIndex: ShellTabs.karte,
          onboardingOpen: false,
          tabHasInnerBack: true,
        ),
        ShellBackDecision.inner,
      );
      expect(
        ShellBack.resolve(
          tabIndex: ShellTabs.hof,
          onboardingOpen: false,
          tabHasInnerBack: true,
        ),
        ShellBackDecision.inner,
      );
    });

    test('onboarding consumes back even on Hof', () {
      expect(
        ShellBack.resolve(
          tabIndex: ShellTabs.hof,
          onboardingOpen: true,
          tabHasInnerBack: false,
        ),
        ShellBackDecision.inner,
      );
      expect(
        ShellBack.allowSystemPop(
          tabIndex: ShellTabs.hof,
          onboardingOpen: true,
          tabHasInnerBack: false,
        ),
        isFalse,
      );
    });
  });
}
