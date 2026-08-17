import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../domain/bike.dart';
import '../../domain/garage/bike_schema_anchors.dart';
import '../../domain/garage/bike_schema_mapper.dart';

/// Disziplin-Schema (dieselben SVGs wie die Werkstatt).
class BikeSchemaView extends StatelessWidget {
  const BikeSchemaView({
    super.key,
    required this.bike,
    this.height = 120,
  });

  final Bike bike;
  final double height;

  @override
  Widget build(BuildContext context) {
    final plan = planBikeSchema(
      category: bike.category,
      isEbike: bike.hasElectricAssist,
    );
    final asset =
        plan.assetKey == null ? null : schemaAssetPath[plan.assetKey!];
    if (asset == null) return const SizedBox.shrink();
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: ColoredBox(
        color: const Color(0xFF232622),
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: Transform.scale(
            scale: 1.48,
            child: SvgPicture.asset(
              asset,
              fit: BoxFit.contain,
              alignment: Alignment.center,
            ),
          ),
        ),
      ),
    );
  }
}
