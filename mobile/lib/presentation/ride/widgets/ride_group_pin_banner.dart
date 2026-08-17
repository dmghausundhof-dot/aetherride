import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/community/ride_group_store.dart';
import '../../../l10n/app_localizations.dart';

/// Opt-in vor Losfahren — nicht 11-px-Text unter der Karte.
class RideGroupPinBanner extends StatefulWidget {
  const RideGroupPinBanner({super.key, this.routeId});

  final String? routeId;

  @override
  State<RideGroupPinBanner> createState() => _RideGroupPinBannerState();
}

class _RideGroupPinBannerState extends State<RideGroupPinBanner> {
  final _store = RideGroupStore();
  String? _title;
  String? _groupId;
  bool _on = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(RideGroupPinBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.routeId != widget.routeId) _load();
  }

  Future<void> _load() async {
    final g = await _store.groupForRide(widget.routeId);
    if (!mounted) return;
    if (g == null) {
      setState(() {
        _title = null;
        _groupId = null;
      });
      return;
    }
    final me = await _store.localMember(g.id);
    if (!mounted) return;
    setState(() {
      _title = g.title;
      _groupId = g.id;
      _on = me?.liveOptIn ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_groupId == null || _title == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    return Material(
      color: Theme.of(context).cardColor.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: FilterChip(
        selected: _on,
        showCheckmark: false,
        label: Text(
          '${_on ? l10n.platzPinsOnHud : l10n.platzPinsOff} — $_title',
        ),
        onSelected: (on) async {
          await _store.setLiveOptIn(_groupId!, on);
          if (!mounted) return;
          setState(() => _on = on);
        },
      ),
    );
  }
}
