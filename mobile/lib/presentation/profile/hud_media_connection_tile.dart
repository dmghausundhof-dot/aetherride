import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../native/hud_media_channel.dart';
import '../shared/chrome_glyph.dart';

/// Where the HUD media-session row lives. Profile is the primary control;
/// privacy keeps a short data-access pointer.
enum HudMediaConnectionCopy { profile, privacy }

/// Glanceable MediaSession / notification-listener connection.
///
/// Tap opens Android listener settings — the OS owns the grant, so this is
/// not an in-app switch. Status refreshes when the app resumes.
class HudMediaConnectionTile extends StatefulWidget {
  const HudMediaConnectionTile({
    super.key,
    this.copy = HudMediaConnectionCopy.profile,
    this.contentPadding,
    @visibleForTesting this.listenerEnabled,
    @visibleForTesting this.onOpenSettings,
  });

  final HudMediaConnectionCopy copy;
  final EdgeInsetsGeometry? contentPadding;

  /// Test seam: skip [HudMediaChannel.listenerEnabled].
  final ValueGetter<bool>? listenerEnabled;

  /// Test seam: skip [HudMediaChannel.openListenerSettings].
  final Future<void> Function()? onOpenSettings;

  static const tileKey = Key('hud-media-connection-tile');

  @override
  State<HudMediaConnectionTile> createState() => _HudMediaConnectionTileState();
}

class _HudMediaConnectionTileState extends State<HudMediaConnectionTile>
    with WidgetsBindingObserver {
  bool _enabled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _enabled = widget.listenerEnabled?.call() ?? false;
    unawaited(_refresh());
  }

  @override
  void didUpdateWidget(HudMediaConnectionTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.listenerEnabled != oldWidget.listenerEnabled) {
      unawaited(_refresh());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refresh());
    }
  }

  Future<void> _refresh() async {
    final on = widget.listenerEnabled?.call() ??
        await HudMediaChannel.listenerEnabled();
    if (!mounted) return;
    setState(() => _enabled = on);
  }

  Future<void> _openSettings() async {
    final open = widget.onOpenSettings ?? HudMediaChannel.openListenerSettings;
    await open();
    if (mounted) await _refresh();
  }

  String _subtitle(AppLocalizations l10n) => switch (widget.copy) {
        HudMediaConnectionCopy.profile => l10n.hudMediaProfileHint,
        HudMediaConnectionCopy.privacy => l10n.hudMediaPrivacyHint,
      };

  @override
  Widget build(BuildContext context) {
    final testSeam = widget.listenerEnabled != null;
    if (!testSeam && !HudMediaChannel.supported) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    return ListTile(
      key: HudMediaConnectionTile.tileKey,
      contentPadding: widget.contentPadding,
      leading: const ChromeGlyph('play', size: 22),
      title: Text(l10n.hudMediaTitle),
      subtitle: Text(
        _subtitle(l10n),
        style: const TextStyle(fontSize: 12, color: AppColors.muted),
      ),
      trailing: Text(
        _enabled ? l10n.onLabel : l10n.offLabel,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: _enabled ? AppColors.accent : AppColors.muted,
        ),
      ),
      onTap: () => unawaited(_openSettings()),
    );
  }
}
