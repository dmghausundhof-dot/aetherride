import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/theme/app_theme.dart';
import 'l10n/app_localizations.dart';
import 'presentation/shell/app_shell.dart';

class AetherRideApp extends StatelessWidget {
  const AetherRideApp({super.key});

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
        // Gerätesprache; DE ist Primär/Fallback (siehe localeResolutionCallback).
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        localeResolutionCallback: (locale, supported) {
          if (locale != null) {
            for (final candidate in supported) {
              if (candidate.languageCode == locale.languageCode) {
                // Land bleibt am Locale (Titel folgt Land, Chrome der Sprache).
                return Locale(candidate.languageCode, locale.countryCode);
              }
            }
          }
          return Locale('de', locale?.countryCode);
        },
        home: const AppShell(),
      ),
    );
  }
}
