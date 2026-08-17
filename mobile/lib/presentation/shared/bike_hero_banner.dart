import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/theme/app_theme.dart';
import '../../data/garage/bike_photo_sync.dart';
import '../../domain/bike.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_ext.dart';
import '../../providers/app_providers.dart';
import 'bike_schema_view.dart';

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
    this.showActiveBadge = true,
    this.showCaption = true,
    this.photoHeight = 140,
    this.lastRideLine,
  });

  final Bike bike;

  /// Optional — z. B. Navigation zur Garage, wenn das Banner auf Home sitzt.
  /// `null` auf der Garage-Detailseite selbst (dort schon am Ziel).
  final VoidCallback? onTap;

  /// Home-Bewohner: Foto bleibt, Kamera und AKTIV-Badge gehören in die Werkstatt.
  final bool showPhotoPicker;
  final bool showActiveBadge;
  final bool showCaption;
  final double photoHeight;
  final String? lastRideLine;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(userProfileStoreProvider);
    final photo = store.bikePhotos[bike.id];
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Container(
                    height: photoHeight,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.charcoal.withValues(alpha: 0.55),
                          AppColors.charcoal.withValues(alpha: 0.95),
                        ],
                      ),
                    ),
                    child: _heroPhoto(photo, photoHeight),
                  ),
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
                  if (showPhotoPicker)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Material(
                        color: Colors.black.withValues(alpha: 0.32),
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => _pickPhoto(context, ref),
                          child: const Padding(
                            padding: EdgeInsets.all(6),
                            child: Icon(
                              Icons.photo_camera_outlined,
                              size: 16,
                              color: Colors.white,
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
                    AppSpacing.m,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bike.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 2),
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
      return BikeSchemaView(bike: bike, height: height);
    }
    return isRemotePhotoRef(photo)
        ? Image.network(
            photo,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (_, __, ___) => const Center(
              child: Icon(Icons.pedal_bike, size: 56, color: Colors.white70),
            ),
          )
        : Image.file(
            File(photo),
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          );
  }

  Future<void> _pickPhoto(BuildContext context, WidgetRef ref) async {
    final store = ref.read(userProfileStoreProvider);
    final picker = ImagePicker();
    final x = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (x == null) return;
    final dir = await getApplicationSupportDirectory();
    final dest = File(p.join(dir.path, 'bike_photos', '${bike.id}.jpg'));
    await dest.parent.create(recursive: true);
    await File(x.path).copy(dest.path);
    await store.setBikePhoto(bike.id, dest.path);
    final url = await uploadBikePhotoToStorage(bikeId: bike.id, file: dest);
    if (url != null) {
      await store.setBikePhoto(bike.id, url);
    }
    // Kein ChangeNotifier auf userProfileStoreProvider — Rebuild über
    // Invalidate eines Providers erzwingen, den der Aufrufer watcht.
    ref.invalidate(currentSetupProvider(bike.id));
  }
}
