import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Official FlowLine boot (vector GIF, portrait lockup, never cropped).
class HofSplash extends StatelessWidget {
  const HofSplash({super.key});

  static const Color bg = Color(0xFFFAFAFA);
  static const Duration motion = Duration(milliseconds: 3000);

  @override
  Widget build(BuildContext context) {
    return const AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.light,
        statusBarIconBrightness: Brightness.dark,
        systemStatusBarContrastEnforced: false,
        systemNavigationBarColor: bg,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: ColoredBox(
        color: bg,
        child: SizedBox.expand(
          child: Image(
            image: AssetImage('assets/brand/boot.gif'),
            fit: BoxFit.contain,
            alignment: Alignment.center,
            filterQuality: FilterQuality.high,
            gaplessPlayback: true,
          ),
        ),
      ),
    );
  }
}
