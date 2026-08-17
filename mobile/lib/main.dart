import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config.dart';
import 'core/crash_reporting.dart';
import 'providers/app_providers.dart';
import 'providers/ride_providers.dart';

/// Time the lockup stays on screen after Flutter's first frame.
const _minSplash = Duration(milliseconds: 3000);

/// Dart HttpClient has no Happy Eyeballs: a broken IPv6 SYN hangs until the
/// Future timeout, so Vercel never falls back to IPv4 (A54 WiFi is dual-stack).
class _ApiHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..connectionTimeout = const Duration(seconds: 8);
  }
}

Future<void> main() async {
  await runWithCrashReporting(() async {
    WidgetsFlutterBinding.ensureInitialized();
    HttpOverrides.global = _ApiHttpOverrides();
    runApp(const ProviderScope(child: _Bootstrap()));
  });
}

class _Bootstrap extends ConsumerStatefulWidget {
  const _Bootstrap();

  @override
  ConsumerState<_Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends ConsumerState<_Bootstrap> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    unawaited(_open());
  }

  Future<void> _open() async {
    final started = DateTime.now();
    unawaited(_initSupabase());
    await _bootLocal();
    unawaited(_startSync());
    final left = _minSplash - DateTime.now().difference(started);
    if (left > Duration.zero) await Future<void>.delayed(left);
    if (mounted) setState(() => _ready = true);
  }

  Future<void> _bootLocal() async {
    try {
      await ref.read(userProfileStoreProvider).load().timeout(
            const Duration(seconds: 3),
          );
      final store = ref.read(userProfileStoreProvider);
      ref.read(onboardingDoneProvider.notifier).state = store.onboardingDone;
    } catch (e) {
      debugPrint('Bootstrap: $e');
      ref.read(onboardingDoneProvider.notifier).state = false;
    }
  }

  Future<void> _initSupabase() async {
    if (!AppConfig.isSupabaseConfigured) return;
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

  Future<void> _startSync() async {
    try {
      await ref.read(syncEngineProvider).start();
    } catch (e) {
      debugPrint('Bootstrap sync: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FlowLineApp(ready: _ready);
  }
}
