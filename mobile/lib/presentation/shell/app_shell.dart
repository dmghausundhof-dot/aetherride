import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/app_providers.dart';
import '../../providers/ride_providers.dart';
import '../discover/discover_screen.dart';
import '../garage/garage_screen.dart';
import '../home/home_screen.dart';
import '../onboarding/onboarding_flow.dart';
import '../ride/ride_screen.dart';
import '../shop/shop_screen.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  /// Tabs erst beim ersten Besuch bauen — verhindert Discover/MapLibre/GPS
  /// beim Cold-Start (ANR durch GeolocatorLocationService).
  final Set<int> _visited = {0};

  Widget _tabBody(int i, Set<int> mountedTabs) {
    if (!mountedTabs.contains(i)) return const SizedBox.shrink();
    switch (i) {
      case 0:
        return const HomeScreen();
      case 1:
        return const GarageScreen();
      case 2:
        return const RideScreen();
      case 3:
        return const DiscoverScreen();
      case 4:
        return const ShopScreen();
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final index = ref.watch(shellTabIndexProvider);
    final onboardingDone = ref.watch(onboardingDoneProvider);
    // Aktiven Tab sofort einblenden — sonst ein Frame lang leerer Slot
    // (Nav schon gewechselt → wirkt wie „Reiter springen“).
    final mountedTabs = {..._visited, index};
    if (!_visited.contains(index)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_visited.add(index)) setState(() {});
      });
    }

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: index,
            children: List.generate(5, (i) => _tabBody(i, mountedTabs)),
          ),
          if (onboardingDone == false) const OnboardingFlow(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index.clamp(0, 4),
        onDestinationSelected: (i) {
          setState(() => _visited.add(i));
          ref.read(shellTabIndexProvider.notifier).state = i;
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.garage_outlined),
            selectedIcon: Icon(Icons.garage),
            label: 'Garage',
          ),
          NavigationDestination(
            icon: Icon(Icons.pedal_bike_outlined),
            selectedIcon: Icon(Icons.pedal_bike, color: AppColors.accent),
            label: 'Ride',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Discover',
          ),
          NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront),
            label: 'Shop',
          ),
        ],
      ),
    );
  }
}
