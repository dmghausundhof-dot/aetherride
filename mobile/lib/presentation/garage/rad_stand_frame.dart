import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/theme/app_theme.dart';
import '../../data/garage/bike_photo_sync.dart';
import '../../domain/bike.dart';
import '../../domain/garage/rad_mark.dart';
import '../../domain/garage/stand_photo.dart';
import 'rad_nav_mark.dart';

/// Cover alignment for a pan: y −1 top, +1 bottom.
Alignment standPhotoAlignment({
  double yBias = kStandPhotoYBias,
  double xBias = kStandPhotoXBias,
}) {
  return Alignment(2 * xBias - 1, 2 * yBias - 1);
}

/// Default cover alignment — lower third, sky cropped first.
final Alignment kStandPhotoAlignment = standPhotoAlignment();

/// Space above the stand rail so overlays do not sit on the header mark.
const double kStandRailClearance = 22;

/// Shared stand stage — ground, bike or photo, rail.
class RadStandFrame extends StatelessWidget {
  const RadStandFrame({
    super.key,
    required this.child,
    this.height = 140,
    this.useStandRatio = false,
    this.photo = false,
    this.compact = false,
    this.borderRadius,
  });

  final Widget child;
  final double height;
  /// 2:1 like the schema paper — stored stand JPEGs fill this without a second crop.
  final bool useStandRatio;
  final bool photo;
  final bool compact;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(AppRadius.card);
    final stage = ClipRRect(
      borderRadius: radius,
      child: Stack(
        fit: StackFit.expand,
        children: [
          SvgPicture.asset(
            radStandGroundAsset,
            fit: BoxFit.cover,
            excludeFromSemantics: true,
          ),
          if (!photo)
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 64,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x00E57532),
                      Color(0x29E57532),
                    ],
                  ),
                ),
              ),
            ),
          child,
          if (!compact && !photo)
            Positioned(
              left: 12,
              bottom: 4,
              child: SvgPicture.asset(
                radStandHeaderAsset,
                width: compact ? 64 : 96,
                height: 14,
                excludeFromSemantics: true,
              ),
            ),
        ],
      ),
    );
    if (useStandRatio) {
      return AspectRatio(aspectRatio: kStandPhotoRatio, child: stage);
    }
    return SizedBox(height: height, width: double.infinity, child: stage);
  }
}

class RadSilhouette extends StatelessWidget {
  const RadSilhouette({
    super.key,
    required this.bike,
    this.fit = BoxFit.contain,
  });

  final Bike bike;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: SvgPicture.asset(
        radSilhouetteAsset(bike),
        fit: fit,
        alignment: Alignment.center,
        excludeFromSemantics: true,
      ),
    );
  }
}

class RadEmptyStandMark extends StatelessWidget {
  const RadEmptyStandMark({super.key, this.height = 140});

  final double height;

  @override
  Widget build(BuildContext context) {
    return RadStandFrame(
      height: height,
      borderRadius: BorderRadius.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: SvgPicture.asset(
          radEmptyStandMarkAsset,
          fit: BoxFit.contain,
          excludeFromSemantics: true,
        ),
      ),
    );
  }
}

/// Shop-Leerbild — dieselbe Bühne, flache Marke statt gestricheltem Rad.
class RadShopStandFallback extends StatelessWidget {
  const RadShopStandFallback({super.key, this.markSize = 28});

  final double markSize;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bounded = constraints.hasBoundedHeight &&
            constraints.maxHeight.isFinite &&
            constraints.maxHeight > 0;
        return RadStandFrame(
          height: bounded ? constraints.maxHeight : 88,
          compact: !bounded || constraints.maxHeight < 100,
          borderRadius: BorderRadius.zero,
          child: Center(
            child: RadNavMark(
              color: const Color(0xFF818C7B),
              size: markSize,
            ),
          ),
        );
      },
    );
  }
}

class RadMiniStand extends StatelessWidget {
  const RadMiniStand({
    super.key,
    required this.bike,
    this.photo,
    this.width = 56,
    this.height = 36,
    this.selected = false,
  });

  final Bike bike;
  final String? photo;
  final double width;
  final double height;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final ref = photo;
    final hasPhoto = ref != null &&
        ref.isNotEmpty &&
        (isRemotePhotoRef(ref) || File(ref).existsSync());
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: selected ? AppColors.chrome : AppColors.border,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: RadStandFrame(
        height: height,
        photo: hasPhoto,
        compact: true,
        borderRadius: BorderRadius.zero,
        child: !hasPhoto
            ? RadSilhouette(bike: bike)
            : isRemotePhotoRef(ref)
                ? Image.network(
                    ref,
                    fit: BoxFit.cover,
                    alignment: kStandPhotoAlignment,
                    errorBuilder: (_, __, ___) => RadSilhouette(bike: bike),
                  )
                : Image.file(
                    File(ref),
                    fit: BoxFit.cover,
                    alignment: kStandPhotoAlignment,
                    errorBuilder: (_, __, ___) => RadSilhouette(bike: bike),
                  ),
      ),
    );
  }
}
