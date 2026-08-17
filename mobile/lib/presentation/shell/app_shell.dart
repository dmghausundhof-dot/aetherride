import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/community/ride_group_store.dart';
import '../../data/community/tour_community_store.dart';
import '../../data/deep_links.dart';
import '../../core/config.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/app_providers.dart';
import '../../providers/ride_providers.dart';
import '../discover/discover_screen.dart';
import '../garage/garage_screen.dart';
import '../home/home_screen.dart';
import '../library/mappe_screen.dart';
import '../onboarding/onboarding_flow.dart';
import '../ride/ride_screen.dart';
import '../shop/shop_screen.dart';
import 'hof_threshold_nav.dart';
import 'shell_back.dart';
import 'shell_tabs.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  /// Tabs erst beim ersten Besuch bauen — verhindert Discover/MapLibre/GPS
  /// beim Cold-Start (ANR durch GeolocatorLocationService).
  final Set<int> _visited = {0};
  DeepLinkHandler? _deepLinks;
  final _discoverKey = GlobalKey<DiscoverScreenState>();
  final _rideKey = GlobalKey<RideScreenState>();
  final _onboardingKey = GlobalKey<OnboardingFlowState>();

  @override
  void initState() {
    super.initState();
    TourCommunityStore.revision.addListener(_onPlatzBadge);
    RideGroupStore.revision.addListener(_onPlatzBadge);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _deepLinks = DeepLinkHandler(ref);
      _deepLinks!.start();
    });
  }

  void _onPlatzBadge() {
    if (!mounted) return;
    ref.invalidate(platzInboxBadgeProvider);
  }

  @override
  void dispose() {
    TourCommunityStore.revision.removeListener(_onPlatzBadge);
    RideGroupStore.revision.removeListener(_onPlatzBadge);
    _deepLinks?.dispose();
    super.dispose();
  }

  Widget _tabBody(int i, Set<int> mountedTabs) {
    if (!mountedTabs.contains(i)) return const SizedBox.shrink();
    switch (i) {
      case ShellTabs.hof:
        return const HomeScreen();
      case ShellTabs.werkstatt:
        return const GarageScreen();
      case ShellTabs.ride:
        return RideScreen(key: _rideKey);
      case ShellTabs.karte:
        return DiscoverScreen(key: _discoverKey);
      case ShellTabs.platz:
        return const MappeScreen();
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final index = ShellTabs.stackIndex(ref.watch(shellTabIndexProvider));
    final onboardingDone = ref.watch(onboardingDoneProvider);
    final riding = ref.watch(isRidingProvider);
    final mountedTabs = {..._visited, index};
    if (!_visited.contains(index)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_visited.add(index)) setState(() {});
      });
    }

    ref.listen<bool>(shopOpenRouteProvider, (prev, next) {
      if (next != true) return;
      if (!AppConfig.shopEnabled) {
        ref.read(shopOpenRouteProvider.notifier).state = false;
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (ref.read(shopOpenRouteProvider) != true) return;
        ref.read(shopOpenRouteProvider.notifier).state = false;
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const ShopScreen()),
        );
      });
    });

    final hideNav = riding || index == ShellTabs.ride;
    final onboardingOpen = onboardingDone == false;
    final dueCount = ref.watch(fleetDueCountProvider).valueOrNull ?? 0;
    final platzInbox = ref.watch(platzInboxBadgeProvider).valueOrNull ?? 0;
    final tabHasInnerBack = switch (index) {
      ShellTabs.karte => _discoverKey.currentState?.hasInnerBack ?? false,
      ShellTabs.ride => true,
      _ => false,
    };
    final allowSystemPop = ShellBack.allowSystemPop(
      tabIndex: index,
      onboardingOpen: onboardingOpen,
      tabHasInnerBack: tabHasInnerBack,
    );

    return PopScope(
      canPop: allowSystemPop,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _onSystemBack(
          index: index,
          onboardingOpen: onboardingOpen,
        );
      },
      child: Scaffold(
        body: Stack(
          children: [
            IndexedStack(
              index: index,
              children: List.generate(5, (i) => _tabBody(i, mountedTabs)),
            ),
            if (onboardingOpen) OnboardingFlow(key: _onboardingKey),
          ],
        ),
        bottomNavigationBar: hideNav
            ? null
            : HofThresholdNav(
                key: const Key('hof-threshold-nav'),
                selectedIndex: ShellTabs.navIndex(index),
                onDestinationSelected: (nav) {
                  final stack = ShellTabs.stackFromNav(nav);
                  setState(() => _visited.add(stack));
                  ref.read(shellTabIndexProvider.notifier).state = stack;
                },
                destinations: [
                  HofThresholdDestination(
                    icon: Icons.home_outlined,
                    selectedIcon: Icons.home,
                    label: l10n.navHome,
                  ),
                  HofThresholdDestination(
                    icon: Icons.map_outlined,
                    selectedIcon: Icons.map,
                    label: l10n.navKarte,
                  ),
                  HofThresholdDestination(
                    icon: Icons.menu_book_outlined,
                    selectedIcon: Icons.menu_book,
                    label: l10n.navPlatz,
                    showBadge: platzInbox > 0,
                  ),
                  HofThresholdDestination(
                    icon: Icons.pedal_bike_outlined,
                    selectedIcon: Icons.pedal_bike,
                    label: l10n.navWorkshop,
                    showBadge: dueCount > 0,
                  ),
                ],
              ),
      ),
    );
  }

  void _onSystemBack({
    required int index,
    required bool onboardingOpen,
  }) {
    final decision = ShellBack.resolve(
      tabIndex: index,
      onboardingOpen: onboardingOpen,
      tabHasInnerBack: switch (index) {
        ShellTabs.karte => _discoverKey.currentState?.hasInnerBack ?? false,
        ShellTabs.ride => true,
        _ => false,
      },
    );
    switch (decision) {
      case ShellBackDecision.systemPop:
        return;
      case ShellBackDecision.inner:
        if (onboardingOpen) {
          _onboardingKey.currentState?.handleSystemBack();
          return;
        }
        if (index == ShellTabs.ride) {
          if (_rideKey.currentState?.handleSystemBack() != true) {
            ref.read(shellTabIndexProvider.notifier).state = ShellTabs.karte;
          }
          return;
        }
        if (index == ShellTabs.karte) {
          if (_discoverKey.currentState?.handleSystemBack() != true) {
            setState(() => _visited.add(ShellTabs.hof));
            ref.read(shellTabIndexProvider.notifier).state = ShellTabs.hof;
          }
        }
        return;
      case ShellBackDecision.goHof:
        setState(() => _visited.add(ShellTabs.hof));
        ref.read(shellTabIndexProvider.notifier).state = ShellTabs.hof;
    }
  }
}
