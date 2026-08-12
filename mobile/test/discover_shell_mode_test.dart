import 'package:flutter_test/flutter_test.dart';

import 'package:aetherride_mobile/presentation/discover/discover_shell_mode.dart';

void main() {
  group('DiscoverShellModeLogic', () {
    test('explore uses browse sheet and tour catalog', () {
      const m = DiscoverShellMode.explore;
      expect(DiscoverShellModeLogic.usesBrowseSheet(m), isTrue);
      expect(DiscoverShellModeLogic.usesFixedNavPanel(m), isFalse);
      expect(DiscoverShellModeLogic.showsTourCatalog(m), isTrue);
      expect(DiscoverShellModeLogic.showsMineList(m), isFalse);
      expect(DiscoverShellModeLogic.showsNavigateForm(m), isFalse);
    });

    test('navigate is fixed A→B panel, not catalog', () {
      const m = DiscoverShellMode.navigate;
      expect(DiscoverShellModeLogic.usesBrowseSheet(m), isFalse);
      expect(DiscoverShellModeLogic.usesFixedNavPanel(m), isTrue);
      expect(DiscoverShellModeLogic.showsTourCatalog(m), isFalse);
      expect(DiscoverShellModeLogic.showsMineList(m), isFalse);
      expect(DiscoverShellModeLogic.showsNavigateForm(m), isTrue);
    });

    test('mine uses browse sheet for own tracks only', () {
      const m = DiscoverShellMode.mine;
      expect(DiscoverShellModeLogic.usesBrowseSheet(m), isTrue);
      expect(DiscoverShellModeLogic.usesFixedNavPanel(m), isFalse);
      expect(DiscoverShellModeLogic.showsTourCatalog(m), isFalse);
      expect(DiscoverShellModeLogic.showsMineList(m), isTrue);
      expect(DiscoverShellModeLogic.showsNavigateForm(m), isFalse);
    });
  });
}
