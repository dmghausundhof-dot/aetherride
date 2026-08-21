import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/hud_media.dart';
import '../../../l10n/l10n_ext.dart';
import '../../shared/chrome_glyph.dart';

/// Compact now-playing transport for the Ride HUD.
///
/// Not a Clean-Mode nav stat — same class as Pause: a control, shown only
/// when something is playing (or as a one-shot enable prompt in Pro).
class RideMediaChip extends StatelessWidget {
  const RideMediaChip({
    super.key,
    required this.kind,
    required this.nowPlaying,
    required this.compact,
    required this.onPlayPause,
    required this.onSkipNext,
    required this.onSkipPrevious,
    required this.onEnable,
    required this.onDismissPrompt,
    this.onOpenPlayer,
  });

  final HudMediaChipKind kind;
  final HudNowPlaying nowPlaying;
  final bool compact;
  final VoidCallback onPlayPause;
  final VoidCallback onSkipNext;
  final VoidCallback onSkipPrevious;
  final VoidCallback onEnable;
  final VoidCallback onDismissPrompt;
  final VoidCallback? onOpenPlayer;

  static const playPauseKey = Key('hud-media-play-pause');
  static const skipNextKey = Key('hud-media-skip-next');
  static const skipPrevKey = Key('hud-media-skip-prev');
  static const enableKey = Key('hud-media-enable');
  static const dismissKey = Key('hud-media-dismiss');

  @override
  Widget build(BuildContext context) {
    return switch (kind) {
      HudMediaChipKind.hidden => const SizedBox.shrink(),
      HudMediaChipKind.enablePrompt => _prompt(context),
      HudMediaChipKind.controls => _controls(context),
    };
  }

  Widget _shell(
    BuildContext context, {
    required Widget child,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Theme.of(context).cardColor.withValues(alpha: 0.94),
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s,
            vertical: AppSpacing.xs,
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _prompt(BuildContext context) {
    final l10n = context.l10nOrNull;
    return KeyedSubtree(
      key: enableKey,
      child: _shell(
        context,
        onTap: onEnable,
        child: Row(
          children: [
            const ChromeGlyph('play', size: 22),
            const SizedBox(width: AppSpacing.s),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n?.rideMusicHud ?? 'Musik im HUD',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    l10n?.rideMusicHudHint ?? 'Titel von Spotify & Co. anzeigen',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.meta(context),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 22, color: AppColors.meta(context)),
            IconButton(
              key: dismissKey,
              tooltip: l10n?.rideDismissHint ?? 'Hinweis schließen',
              onPressed: onDismissPrompt,
              icon: const Icon(Icons.close, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _controls(BuildContext context) {
    final l10n = context.l10nOrNull;
    final playing = nowPlaying.playing;
    final canPrev = !nowPlaying.active || nowPlaying.canSkipPrevious;
    final canNext = !nowPlaying.active || nowPlaying.canSkipNext;
    final sub = compact ? '' : nowPlaying.subtitle;

    return Semantics(
      container: true,
      label: l10n?.rideMusicControls ?? 'Musiksteuerung',
      child: _shell(
        context,
        child: Row(
          children: [
            ChromeGlyph(
              playing ? 'play' : 'pause',
              size: 20,
              color: AppColors.accent,
            ),
            const SizedBox(width: AppSpacing.s),
            Expanded(
              child: GestureDetector(
                onLongPress: onOpenPlayer,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      nowPlaying.displayTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                      ),
                    ),
                    if (sub.isNotEmpty)
                      Text(
                        sub,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.meta(context),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            _btn(
              key: skipPrevKey,
              tooltip: l10n?.ridePrevTrack ?? 'Vorheriger Titel',
              icon: Icons.skip_previous,
              onPressed: canPrev ? onSkipPrevious : null,
            ),
            _btn(
              key: playPauseKey,
              tooltip: playing
                  ? (l10n?.ridePause ?? 'Pause')
                  : (l10n?.ridePlay ?? 'Abspielen'),
              mark: playing ? 'pause' : 'play',
              onPressed: onPlayPause,
            ),
            _btn(
              key: skipNextKey,
              tooltip: l10n?.rideNextTrack ?? 'Nächster Titel',
              icon: Icons.skip_next,
              onPressed: canNext ? onSkipNext : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _btn({
    required Key key,
    required String tooltip,
    IconData? icon,
    String? mark,
    required VoidCallback? onPressed,
  }) {
    return IconButton(
      key: key,
      tooltip: tooltip,
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
      style: IconButton.styleFrom(
        minimumSize: const Size(44, 44),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: EdgeInsets.zero,
      ),
      icon: mark != null
          ? ChromeGlyph(mark, size: 26)
          : Icon(icon, size: 26),
    );
  }
}
