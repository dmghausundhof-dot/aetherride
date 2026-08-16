import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/community/public_profile_cloud.dart';
import '../../data/community/public_profile_store.dart';
import '../../l10n/app_localizations.dart';

/// Opt-in Public Profile — im Profil, nicht in der Leiste.
class PublicProfileSection extends StatefulWidget {
  const PublicProfileSection({super.key});

  @override
  State<PublicProfileSection> createState() => _PublicProfileSectionState();
}

class _PublicProfileSectionState extends State<PublicProfileSection> {
  final _store = PublicProfileStore();
  final _handle = TextEditingController();
  final _name = TextEditingController();
  final _bio = TextEditingController();
  final _region = TextEditingController();
  PublicProfileSettings _s = const PublicProfileSettings();
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _handle.dispose();
    _name.dispose();
    _bio.dispose();
    _region.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    var s = await _store.load();
    final cloud = await PublicProfileCloud.pullMine();
    if (cloud != null) {
      s = await _store.save(cloud);
    }
    if (!mounted) return;
    setState(() {
      _s = s;
      _handle.text = s.handle;
      _name.text = s.displayName;
      _bio.text = s.bio;
      _region.text = s.regionLabel;
      _ready = true;
    });
  }

  Future<void> _persist(PublicProfileSettings next) async {
    final saved = await _store.save(next);
    unawaited(PublicProfileCloud.push(saved));
    if (!mounted) return;
    setState(() => _s = saved);
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.publicProfileTitle),
          subtitle: Text(l10n.publicProfileHint),
          value: _s.enabled,
          onChanged: (v) => unawaited(_persist(_s.copyWith(enabled: v))),
        ),
        if (_s.enabled) ...[
          TextField(
            controller: _name,
            decoration: InputDecoration(labelText: l10n.profileDisplayName),
            onChanged: (v) => unawaited(_persist(_s.copyWith(displayName: v))),
          ),
          TextField(
            controller: _handle,
            decoration: InputDecoration(labelText: l10n.publicProfileHandle),
            onChanged: (v) => unawaited(_persist(_s.copyWith(handle: v))),
          ),
          TextField(
            controller: _bio,
            maxLines: 3,
            decoration: InputDecoration(labelText: l10n.publicProfileBio),
            onChanged: (v) => unawaited(_persist(_s.copyWith(bio: v))),
          ),
          TextField(
            controller: _region,
            decoration: InputDecoration(labelText: l10n.publicProfileRegion),
            onChanged: (v) => unawaited(_persist(_s.copyWith(regionLabel: v))),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.publicProfileShowRides),
            value: _s.showRideCount,
            onChanged: (v) =>
                unawaited(_persist(_s.copyWith(showRideCount: v))),
          ),
          Text(
            l10n.publicProfileFoot,
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
          ),
        ],
      ],
    );
  }
}
