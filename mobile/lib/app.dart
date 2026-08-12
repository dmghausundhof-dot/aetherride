import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/theme/app_theme.dart';
import 'l10n/app_localizations.dart';
import 'presentation/shell/app_shell.dart';

class AetherRideApp extends StatelessWidget {
  const AetherRideApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
              return candidate;
            }
          }
        }
        return const Locale('de');
      },
      home: const AppShell(),
    );
  }
}
