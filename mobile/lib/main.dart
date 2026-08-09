import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config.dart';
import 'providers/app_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // UI zuerst zeichnen — Supabase darf den Cold-Start nicht blockieren.
  runApp(const ProviderScope(child: _Bootstrap()));
}

class _Bootstrap extends ConsumerStatefulWidget {
  const _Bootstrap();

  @override
  ConsumerState<_Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends ConsumerState<_Bootstrap> {
  @override
  void initState() {
    super.initState();
    unawaited(_boot());
  }

  Future<void> _boot() async {
    if (AppConfig.isSupabaseConfigured) {
      try {
        await Supabase.initialize(
          url: AppConfig.supabaseUrl,
          publishableKey: AppConfig.supabaseAnonKey,
        ).timeout(const Duration(seconds: 10));
        if (mounted) ref.invalidate(authSessionProvider);
      } catch (e) {
        debugPrint('Supabase init: $e');
      }
    }
    try {
      await ref.read(userProfileStoreProvider).load();
      // Kein Auto-Demo-Bike — leere Garage bleibt leer (wie Web nach Freeride/Skip).
      await ref.read(syncEngineProvider).start();
    } catch (e) {
      debugPrint('Bootstrap: $e');
    }
  }

  @override
  Widget build(BuildContext context) => const AetherRideApp();
}
