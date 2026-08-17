import 'package:flutter/material.dart';

/// Land-colored cover until MapLibre has a style. Empty GL views flash gray.
class MapLoadingScrim extends StatelessWidget {
  const MapLoadingScrim({super.key});

  static const Color land = Color(0xFFE8E4D4);

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: land,
      child: Align(
        alignment: Alignment(0, -0.35),
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2.2,
            color: Color(0xFF8A8578),
          ),
        ),
      ),
    );
  }
}
