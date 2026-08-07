import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'presentation/shell/app_shell.dart';

class AetherRideApp extends StatelessWidget {
  const AetherRideApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AetherRide',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      home: const AppShell(),
    );
  }
}
