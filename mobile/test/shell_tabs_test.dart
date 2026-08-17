import 'package:aetherride_mobile/presentation/shell/shell_tabs.dart';
import 'package:aetherride_mobile/providers/ride_providers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Nav hat vier Ziele: Start, Karte, Touren, Rad', () {
    expect(ShellTabs.navCount, 4);
    expect(ShellTabs.stackFromNav(0), ShellTabs.hof);
    expect(ShellTabs.stackFromNav(1), ShellTabs.karte);
    expect(ShellTabs.stackFromNav(2), ShellTabs.platz);
    expect(ShellTabs.stackFromNav(3), ShellTabs.werkstatt);
    expect(ShellTabs.stackFromNav(4), ShellTabs.hof);
  });

  test('Fahren ist kein Reiter — HUD liegt auf der Karte', () {
    expect(ShellTabs.navIndex(ShellTabs.ride), 1);
    expect(ShellTabs.navIndex(ShellTabs.karte), 1);
    expect(ShellTabs.navIndex(ShellTabs.platz), 2);
    expect(ShellTabs.navIndex(ShellTabs.werkstatt), 3);
  });

  test('Rausfahren ist ein Discover-Launch', () {
    expect(DiscoverLaunchMode.values, contains(DiscoverLaunchMode.rideOut));
    expect(DiscoverLaunchMode.values, contains(DiscoverLaunchMode.mine));
  });

  test('Karte-Tab öffnet ohne Choice-Sheet', () {
    expect(
      ShellTabs.shouldOfferRideOutOnKarteNav(
        fromStack: ShellTabs.hof,
        toStack: ShellTabs.karte,
      ),
      isFalse,
    );
    expect(
      ShellTabs.shouldOfferRideOutOnKarteNav(
        fromStack: ShellTabs.werkstatt,
        toStack: ShellTabs.karte,
      ),
      isFalse,
    );
    expect(
      ShellTabs.shouldOfferRideOutOnKarteNav(
        fromStack: ShellTabs.platz,
        toStack: ShellTabs.karte,
      ),
      isFalse,
    );
  });

  test('Karte-Wahl nicht bei HUD, erneutem Tab oder fremdem Intent', () {
    expect(
      ShellTabs.shouldOfferRideOutOnKarteNav(
        fromStack: ShellTabs.karte,
        toStack: ShellTabs.karte,
      ),
      isFalse,
    );
    expect(
      ShellTabs.shouldOfferRideOutOnKarteNav(
        fromStack: ShellTabs.ride,
        toStack: ShellTabs.karte,
      ),
      isFalse,
    );
    expect(
      ShellTabs.shouldOfferRideOutOnKarteNav(
        fromStack: ShellTabs.hof,
        toStack: ShellTabs.werkstatt,
      ),
      isFalse,
    );
    expect(
      ShellTabs.shouldOfferRideOutOnKarteNav(
        fromStack: ShellTabs.hof,
        toStack: ShellTabs.karte,
        hasLaunchIntent: true,
      ),
      isFalse,
    );
    expect(
      ShellTabs.shouldOfferRideOutOnKarteNav(
        fromStack: ShellTabs.hof,
        toStack: ShellTabs.karte,
        hasPendingDiscoverTarget: true,
      ),
      isFalse,
    );
  });
}
