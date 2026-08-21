import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_theme.dart';
import '../../data/garage/bike_photo_sync.dart';
import '../../domain/bike.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_ext.dart';
import '../../providers/app_providers.dart';
import '../garage/bike_photo_fill_sheet.dart';
import '../garage/rad_stand_frame.dart';

/// Foto-Banner + Name/Kategorie/Aktiv-Badge für ein Bike — gemeinsames
/// visuelles Vokabular zwischen Home (Begrüßung/Fingerprint) und Garage
/// (Bike-Detail), statt zweier unterschiedlicher Darstellungen für dasselbe
/// Bike (UX-Review Punkt „Home und Garage sprechen nicht dieselbe Sprache").
class BikeHeroBanner extends ConsumerWidget {
  const BikeHeroBanner({
    super.key,
    required this.bike,
    this.onTap,
    this.showPhotoPicker = true,
    this.usePhotoFill = false,
    this.onPhotoFilled,
    this.showActiveBadge = true,
    this.showCaption = true,
    this.photoHeight = 140,
    this.lastRideLine,
    this.embedded = false,
  });

  final Bike bike;

  /// Optional — z. B. Navigation zur Garage, wenn das Banner auf Home sitzt.
  /// `null` auf der Garage-Detailseite selbst (dort schon am Ziel).
  final VoidCallback? onTap;

  /// Home-Bewohner: Foto bleibt, Kamera und AKTIV-Badge gehören ans Rad.
  final bool showPhotoPicker;

  /// Garage: Kamera startet Grok (Lücken + Prüfliste), nicht nur Galerie.
  final bool usePhotoFill;
  final VoidCallback? onPhotoFilled;
  final bool showActiveBadge;
  final bool showCaption;
  final double photoHeight;
  final String? lastRideLine;

  /// Parent already draws the stand card chrome (Die Box).
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(userProfileStoreProvider);
    final photo = store.bikePhotos[bike.id];
    final grokRead = store.bikeGrokReads[bike.id] ?? '';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Container(
          decoration: embedded
              ? null
              : BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: AppColors.border),
                ),
          clipBehavior: embedded ? Clip.none : Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  _heroPhoto(photo, photoHeight),
                  if (showActiveBadge && bike.isActive)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.s,
                          vertical: AppSpacing.xxs,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          AppLocalizations.of(context).garageActiveStamp,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ),
                  if (showCaption)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.m,
                          AppSpacing.l,
                          AppSpacing.m,
                          AppSpacing.s,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppColors.hofGround.withValues(alpha: 0),
                              AppColors.hofGround.withValues(alpha: 0.82),
                            ],
                          ),
                        ),
                        child: Text(
                          bike.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppColors.chipIdleText,
                              ),
                        ),
                      ),
                    ),
                  if (showPhotoPicker)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Material(
                        color: AppColors.hofGround.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          onTap: () => _pickPhoto(context, ref),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.s,
                              vertical: 6,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.photo_camera_outlined,
                                  size: 16,
                                  color: AppColors.chipIdleText,
                                ),
                                if (usePhotoFill) ...[
                                  const SizedBox(width: 4),
                                  Text(
                                    AppLocalizations.of(context).garagePhotoFill,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.chipIdleText,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (showPhotoPicker && isRemotePhotoRef(photo))
                    Positioned(
                      left: 8,
                      right: 8,
                      bottom: showCaption ? 44 : kStandRailClearance,
                      child: Material(
                        key: const Key('stand-photo-retake'),
                        color: AppColors.hofGround.withValues(alpha: 0.62),
                        borderRadius: BorderRadius.circular(AppRadius.chip),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(AppRadius.chip),
                          onTap: () => _pickPhoto(context, ref),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.s,
                              vertical: 8,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppLocalizations.of(context).garagePhotoRetake,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.chipIdleText,
                                  ),
                                ),
                                Text(
                                  AppLocalizations.of(context)
                                      .garagePhotoRetakeHint,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    height: 1.25,
                                    color: AppColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              if (showCaption)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.m,
                    AppSpacing.s,
                    AppSpacing.m,
                    AppSpacing.s,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        [
                          AppLocalizations.of(context).bikeCategoryLabel(bike),
                          if (bike.brand != null) bike.brand!,
                          if (bike.model != null) bike.model!,
                          if (bike.year != null) '${bike.year}',
                        ].join(' · '),
                        style: const TextStyle(
                            color: AppColors.muted, fontSize: 12.5),
                      ),
                      if (lastRideLine != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          lastRideLine!,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              if (grokRead.isNotEmpty)
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.m,
                    showCaption ? 0 : AppSpacing.s,
                    AppSpacing.m,
                    AppSpacing.m,
                  ),
                  child: GrokReadCard(summary: grokRead, compact: true),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _heroPhoto(String? photo, double height) {
    final hasPhoto = photo != null &&
        (isRemotePhotoRef(photo) || File(photo).existsSync());
    if (!hasPhoto) {
      return RadStandFrame(
        height: height,
        borderRadius: BorderRadius.zero,
        child: RadSilhouette(bike: bike),
      );
    }
    return RadStandFrame(
      height: height,
      photo: true,
      borderRadius: BorderRadius.zero,
      child: isRemotePhotoRef(photo)
          ? Image.network(
              photo,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              alignment: kStandPhotoAlignment,
              errorBuilder: (_, __, ___) => RadSilhouette(bike: bike),
            )
          : Image.file(
              File(photo),
              key: ValueKey(
                '${photo}-${_localPhotoStamp(photo)}',
              ),
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              alignment: kStandPhotoAlignment,
              errorBuilder: (_, __, ___) => RadSilhouette(bike: bike),
              gaplessPlayback: false,
            ),
    );
  }

  Future<void> _pickPhoto(BuildContext context, WidgetRef ref) async {
    if (usePhotoFill) {
      await showBikePhotoFillSheet(
        context: context,
        ref: ref,
        bike: bike,
      );
      onPhotoFilled?.call();
      return;
    }
    final picker = ImagePicker();
    final x = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (x == null) return;
    await persistPickedBikePhoto(
      ref: ref,
      bikeId: bike.id,
      source: File(x.path),
    );
    // Kein ChangeNotifier auf userProfileStoreProvider — Rebuild über
    // Invalidate eines Providers erzwingen, den der Aufrufer watcht.
    ref.invalidate(currentSetupProvider(bike.id));
  }
}

int _localPhotoStamp(String path) {
  try {
    return File(path).lastModifiedSync().millisecondsSinceEpoch;
  } catch (_) {
    return 0;
  }
}
