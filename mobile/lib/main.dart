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
  final Completer<void> _splashDone = Completer<void>();

  @override
  void initState() {
    super.initState();
    unawaited(_open());
  }

  void _onSplashFinished() {
    if (!_splashDone.isCompleted) _splashDone.complete();
  }

  Future<void> _open() async {
    unawaited(_initSupabase());
    await Future.wait<void>([
      _bootLocal(),
      _splashDone.future.timeout(
        const Duration(seconds: 12),
        onTimeout: () {},
      ),
    ]);
    unawaited(_startSync());
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
    return FlowLineApp(
      ready: _ready,
      onSplashFinished: _onSplashFinished,
    );
  }
}
