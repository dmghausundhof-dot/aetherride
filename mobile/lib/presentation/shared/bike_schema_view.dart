import 'package:flutter/material.dart';

import '../garage/rad_stand_frame.dart';
import '../../domain/bike.dart';

/// Disziplin-Schema auf dem Stand (dieselben SVGs wie die Web-Box).
class BikeSchemaView extends StatelessWidget {
  const BikeSchemaView({
    super.key,
    required this.bike,
    this.height = 120,
    this.framed = true,
  });

  final Bike bike;
  final double height;
  final bool framed;

  @override
  Widget build(BuildContext context) {
    final mark = RadSilhouette(bike: bike);
    if (!framed) return SizedBox(height: height, child: mark);
    return RadStandFrame(
      height: height,
      child: mark,
    );
  }
}
