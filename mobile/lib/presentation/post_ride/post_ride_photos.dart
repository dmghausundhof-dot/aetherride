import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

/// Lokale Ride-Fotos + Share-Hook (kein Community-Upload-Backend).
class PostRidePhotosSection extends StatelessWidget {
  const PostRidePhotosSection({
    super.key,
    required this.photoPaths,
    required this.onChanged,
    this.maxPhotos = 8,
  });

  final List<String> photoPaths;
  final ValueChanged<List<String>> onChanged;
  final int maxPhotos;

  Future<void> _pick(BuildContext context, ImageSource source) async {
    final l10n = AppLocalizations.of(context);
    if (photoPaths.length >= maxPhotos) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.postRidePhotosMax(maxPhotos))),
      );
      return;
    }
    final picker = ImagePicker();
    final x = await picker.pickImage(
      source: source,
      maxWidth: 1920,
      imageQuality: 85,
    );
    if (x == null) return;
    final dir = await getApplicationSupportDirectory();
    final destDir = Directory(p.join(dir.path, 'ride_photos'));
    await destDir.create(recursive: true);
    final dest = File(p.join(destDir.path, '${const Uuid().v4()}.jpg'));
    await File(x.path).copy(dest.path);
    if (!context.mounted) return;
    onChanged([...photoPaths, dest.path]);
  }

  Future<void> _share(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final existing = [
      for (final path in photoPaths)
        if (File(path).existsSync()) XFile(path, mimeType: 'image/jpeg'),
    ];
    if (existing.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.postRidePhotosEmpty)),
      );
      return;
    }
    await SharePlus.instance.share(
      ShareParams(
        files: existing,
        text: l10n.postRidePhotosShareText,
      ),
    );
  }

  void _removeAt(int i) {
    final next = [...photoPaths]..removeAt(i);
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.postRidePhotosTitle,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.postRidePhotosHint,
          style: const TextStyle(fontSize: 12, color: AppColors.muted),
        ),
        const SizedBox(height: AppSpacing.s),
        if (photoPaths.isNotEmpty)
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: photoPaths.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.s),
              itemBuilder: (context, i) {
                final path = photoPaths[i];
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.chip),
                      child: Image.file(
                        File(path),
                        width: 96,
                        height: 96,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 96,
                          height: 96,
                          color: AppColors.surface,
                          child: const Icon(Icons.broken_image_outlined),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Material(
                        color: Colors.black54,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => _removeAt(i),
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(
                              Icons.close,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        if (photoPaths.isNotEmpty) const SizedBox(height: AppSpacing.s),
        Wrap(
          spacing: AppSpacing.s,
          runSpacing: AppSpacing.s,
          children: [
            OutlinedButton.icon(
              onPressed: () => _pick(context, ImageSource.camera),
              icon: const Icon(Icons.photo_camera_outlined),
              label: Text(l10n.postRidePhotoCamera),
            ),
            OutlinedButton.icon(
              onPressed: () => _pick(context, ImageSource.gallery),
              icon: const Icon(Icons.photo_library_outlined),
              label: Text(l10n.postRidePhotoGallery),
            ),
            if (photoPaths.isNotEmpty)
              OutlinedButton.icon(
                onPressed: () => _share(context),
                icon: const Icon(Icons.ios_share),
                label: Text(l10n.postRidePhotosShare),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.postRideCommunityStub,
          style: const TextStyle(fontSize: 11, color: AppColors.muted),
        ),
      ],
    );
  }
}
