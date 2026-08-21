import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/local/ride_prefs.dart';
import '../../l10n/l10n_ext.dart';
import 'nav_puck_image.dart';
import 'nav_puck_style_sheet.dart';

/// Profil: 3D-Fahrer (Standard) oder klassischer Pfeil, etwas kleiner.
class NavPuckProfileTile extends StatefulWidget {
  const NavPuckProfileTile({
    super.key,
    this.loadStyle,
    this.onSave,
  });

  static const tileKey = Key('nav-puck-profile-tile');

  /// Test seam — sonst [RidePrefs.navPuckStyleId].
  final Future<NavPuckStyle> Function()? loadStyle;

  /// Test seam — sonst [RidePrefs.setNavPuckStyleId].
  final Future<void> Function(NavPuckStyle)? onSave;

  @override
  State<NavPuckProfileTile> createState() => _NavPuckProfileTileState();
}

class _NavPuckProfileTileState extends State<NavPuckProfileTile> {
  NavPuckStyle _style = NavPuckStyle.rider;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final style = widget.loadStyle != null
        ? await widget.loadStyle!()
        : NavPuckStyleX.fromId(await RidePrefs.navPuckStyleId());
    if (!mounted) return;
    setState(() => _style = style);
  }

  Future<void> _pick() async {
    final l10n = context.l10nOrNull;
    final picked = await showNavPuckStyleSheet(
      context,
      current: _style,
      styles: navPuckProfileChoices(_style),
      hint: l10n?.rideNavPuckHintSimple,
    );
    if (picked == null || !mounted) return;
    if (widget.onSave != null) {
      await widget.onSave!(picked);
    } else {
      await RidePrefs.setNavPuckStyleId(picked.id);
    }
    if (!mounted) return;
    setState(() => _style = picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10nOrNull;
    final name = navPuckTitle(l10n, _style);
    final hint = l10n?.profileNavPuckHint ??
        '3D-Fahrer als Standard. Der klassische Pfeil ist etwas kleiner.';
    return ListTile(
      key: NavPuckProfileTile.tileKey,
      leading: AetherNavMark(size: 32, style: _style),
      title: Text(l10n?.rideNavPuckTitle ?? 'Navi-Symbol'),
      subtitle: Text('$name · $hint'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => unawaited(_pick()),
    );
  }
}
