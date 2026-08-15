import 'package:aetherride_mobile/presentation/shell/shell_tabs.dart';
import 'package:aetherride_mobile/providers/ride_providers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Nav hat vier Ziele: Hof, Karte, Werkstatt, Shop', () {
    expect(ShellTabs.stackFromNav(0), ShellTabs.hof);
    expect(ShellTabs.stackFromNav(1), ShellTabs.karte);
    expect(ShellTabs.stackFromNav(2), ShellTabs.werkstatt);
    expect(ShellTabs.stackFromNav(3), ShellTabs.shop);
  });

  test('Fahren ist kein Reiter — HUD liegt auf der Karte', () {
    expect(ShellTabs.navIndex(ShellTabs.ride), 1);
    expect(ShellTabs.navIndex(ShellTabs.karte), 1);
    expect(ShellTabs.navIndex(ShellTabs.shop), 3);
  });

  test('Rausfahren ist ein Discover-Launch', () {
    expect(DiscoverLaunchMode.values, contains(DiscoverLaunchMode.rideOut));
  });
}
