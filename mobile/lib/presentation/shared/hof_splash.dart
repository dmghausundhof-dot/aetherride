import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Full brand splash artwork — never cropped, always entirely on screen.
class HofSplash extends StatelessWidget {
  const HofSplash({super.key});

  static const _bg = Color(0xFFFAFAFA);

  @override
  Widget build(BuildContext context) {
    return const AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.light,
        statusBarIconBrightness: Brightness.dark,
        systemStatusBarContrastEnforced: false,
        systemNavigationBarColor: _bg,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: ColoredBox(
        color: _bg,
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: SizedBox.expand(
              child: Image(
                image: AssetImage('assets/brand/splash.png'),
                fit: BoxFit.contain,
                alignment: Alignment.center,
                filterQuality: FilterQuality.high,
                gaplessPlayback: true,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
