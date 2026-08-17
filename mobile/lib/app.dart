import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/theme/app_theme.dart';
import 'l10n/app_locale.dart';
import 'l10n/app_localizations.dart';
import 'presentation/shared/hof_splash.dart';
import 'presentation/shell/app_shell.dart';

class FlowLineApp extends StatelessWidget {
  const FlowLineApp({
    super.key,
    this.ready = true,
    this.onSplashFinished,
  });

  final bool ready;
  final VoidCallback? onSplashFinished;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.light,
        systemStatusBarContrastEnforced: false,
        systemNavigationBarColor: AppColors.hofGround,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: MaterialApp(
        onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.dark,
        // Chrome: de/en/fr/it. Land bleibt am Locale. Gerätesprache → Hof-Titel
        // (AppLocaleBinding), nicht der UI-Fallback.
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        localeResolutionCallback: AppLocaleBinding.resolve,
        builder: (context, child) {
          AppLocaleBinding.sync(context);
          return child ?? const SizedBox.shrink();
        },
        home: AnimatedSwitcher(
          duration: const Duration(milliseconds: 380),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: ready
              ? const AppShell(key: ValueKey('app'))
              : HofSplash(
                  key: const ValueKey('splash'),
                  onFinished: onSplashFinished,
                ),
        ),
      ),
    );
  }
}
