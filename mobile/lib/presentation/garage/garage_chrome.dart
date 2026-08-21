import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/garage/bike_photo_fill.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_ext.dart';
import 'rad_glyph.dart';

/// Sichtbarer Grok-Text — gleiche Karte wie Specs und Belege.
class GrokReadCard extends StatelessWidget {
  const GrokReadCard({
    super.key,
    required this.summary,
    this.parts = const [],
    this.compact = false,
  });

  final String summary;
  final List<OemPartSuggestion> parts;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (summary.trim().isEmpty && parts.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      key: const Key('grok-read-card'),
      padding: const EdgeInsets.all(AppSpacing.s),
      decoration: garageCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).oemGrokRead,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (summary.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              summary.trim(),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (!compact && parts.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final p in parts)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  '${AppLocalizations.of(context).componentSlotLabel(p.slot)} · ${p.title}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.muted,
                  ),
                ),
              ),
          ],
          const SizedBox(height: 4),
          Text(
            AppLocalizations.of(context).oemGrokVerify,
            style: const TextStyle(
              fontSize: 11.5,
              color: AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

/// Gemeinsame Section-Titel — Box, Tabs, Specs, Sheets.
class GarageSectionTitle extends StatelessWidget {
  const GarageSectionTitle({
    super.key,
    required this.label,
    this.mark,
  });

  final String label;
  final String? mark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (mark != null) ...[
          RadGlyph(mark!, size: 16),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
          ),
        ),
      ],
    );
  }
}

/// Griff aller Garage-Sheets — eine Kante, keine ad-hoc 36×4-Balken.
class GarageSheetHandle extends StatelessWidget {
  const GarageSheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 36,
        height: 4,
        margin: const EdgeInsets.only(top: 10, bottom: AppSpacing.s),
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
      ),
    );
  }
}

/// Titel + optionaler Hinweis — Sheets und Karten dieselbe Typo.
class GarageSheetTitle extends StatelessWidget {
  const GarageSheetTitle({
    super.key,
    required this.title,
    this.hint,
    this.hintKey,
    this.trailing,
  });

  final String title;
  final String? hint;
  final Key? hintKey;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
        if (hint != null && hint!.trim().isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            hint!,
            key: hintKey,
            style: const TextStyle(fontSize: 12.5, color: AppColors.muted),
          ),
        ],
      ],
    );
  }
}

/// Zahlen- und Status-Chips — Werte-Leiste, Compat, Bereit, Beleg-Arten.
class GarageFactChip extends StatelessWidget {
  const GarageFactChip({
    super.key,
    required this.label,
    this.leading,
    this.color,
    this.selected = false,
  });

  final String label;
  final Widget? leading;
  final Color? color;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final ink = color ?? (selected ? AppColors.chrome : AppColors.chipIdleText);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: (color ?? AppColors.chrome).withValues(alpha: selected ? 0.22 : 0.12),
        borderRadius: BorderRadius.circular(AppRadius.chip),
        border: Border.all(
          color: (color ?? AppColors.chrome).withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: ink,
            ),
          ),
        ],
      ),
    );
  }
}

/// Ghost-Slot — gleiche Einladungssprache wie [GarageInviteCard].
class GarageGhostRow extends StatelessWidget {
  const GarageGhostRow({
    super.key,
    required this.title,
    this.hint,
    this.onTap,
    this.icon = Icons.add,
  });

  final String title;
  final String? hint;
  final VoidCallback? onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Material(
        color: AppColors.chrome.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.chip),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.chip),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.m,
                vertical: AppSpacing.s,
              ),
              child: Row(
                children: [
                  Icon(icon, size: 18, color: AppColors.chrome),
                  const SizedBox(width: AppSpacing.s),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        if (hint != null)
                          Text(
                            hint!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.muted,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Leerer Zustand in derselben Sprache wie Ghost-Slots.
class GarageInviteCard extends StatelessWidget {
  const GarageInviteCard({
    super.key,
    required this.title,
    required this.hint,
    this.onTap,
    this.icon = Icons.add_circle_outline,
  });

  final String title;
  final String hint;
  final VoidCallback? onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.chrome.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.m,
            vertical: AppSpacing.m,
          ),
          child: Row(
            children: [
              Icon(icon, size: 22, color: AppColors.chrome),
              const SizedBox(width: AppSpacing.s),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      hint,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

BoxDecoration garageCardDecoration({bool active = false}) {
  return BoxDecoration(
    color: AppColors.surfaceDark,
    borderRadius: BorderRadius.circular(AppRadius.card),
    border: Border.all(
      color: active ? AppColors.chrome : AppColors.border,
      width: active ? 1.5 : 1,
    ),
  );
}

/// Kamera / Galerie — dieselbe Sheet-Sprache für Foto und Beleg.
Future<ImageSource?> showGarageImageSourceSheet({
  required BuildContext context,
  String? hint,
  bool allowSkip = false,
}) {
  return showModalBottomSheet<ImageSource>(
    context: context,
    builder: (ctx) {
      final d = AppLocalizations.of(ctx);
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const GarageSheetHandle(),
            if (hint != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  0,
                  AppSpacing.xl,
                  AppSpacing.s,
                ),
                child: Text(
                  hint,
                  style: const TextStyle(fontSize: 13, color: AppColors.muted),
                ),
              ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(d.postRidePhotoCamera),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_outlined),
              title: Text(d.garageGallery),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            if (allowSkip)
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: Text(d.garageReceiptTypeOnly),
                onTap: () => Navigator.pop(ctx),
              ),
          ],
        ),
      );
    },
  );
}
