import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class PublicProfileSettings {
  const PublicProfileSettings({
    this.enabled = false,
    this.handle = '',
    this.displayName = '',
    this.bio = '',
    this.sports = const [],
    this.showRideCount = true,
    this.regionLabel = '',
  });

  final bool enabled;
  final String handle;
  final String displayName;
  final String bio;
  final List<String> sports;
  final bool showRideCount;
  final String regionLabel;

  PublicProfileSettings copyWith({
    bool? enabled,
    String? handle,
    String? displayName,
    String? bio,
    List<String>? sports,
    bool? showRideCount,
    String? regionLabel,
  }) =>
      PublicProfileSettings(
        enabled: enabled ?? this.enabled,
        handle: handle ?? this.handle,
        displayName: displayName ?? this.displayName,
        bio: bio ?? this.bio,
        sports: sports ?? this.sports,
        showRideCount: showRideCount ?? this.showRideCount,
        regionLabel: regionLabel ?? this.regionLabel,
      );

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'handle': handle,
        'displayName': displayName,
        'bio': bio,
        'sports': sports,
        'showRideCount': showRideCount,
        'regionLabel': regionLabel,
      };

  factory PublicProfileSettings.fromJson(Map raw) {
    return PublicProfileSettings(
      enabled: raw['enabled'] == true,
      handle: '${raw['handle'] ?? ''}',
      displayName: '${raw['displayName'] ?? ''}',
      bio: '${raw['bio'] ?? ''}',
      sports: [
        for (final e in (raw['sports'] as List? ?? const []))
          if (e is String) e,
      ],
      showRideCount: raw['showRideCount'] != false,
      regionLabel: '${raw['regionLabel'] ?? ''}',
    );
  }
}

class PublicProfileStore {
  PublicProfileStore({Future<Directory> Function()? dirProvider})
      : _dirProvider = dirProvider ?? getApplicationDocumentsDirectory;

  final Future<Directory> Function() _dirProvider;
  PublicProfileSettings? _cache;

  Future<File> _file() async {
    final dir = await _dirProvider();
    return File(p.join(dir.path, 'public_profile_local.json'));
  }

  Future<PublicProfileSettings> load() async {
    final cached = _cache;
    if (cached != null) return cached;
    try {
      final f = await _file();
      if (!await f.exists()) return _cache = const PublicProfileSettings();
      final decoded = jsonDecode(await f.readAsString());
      if (decoded is! Map) return _cache = const PublicProfileSettings();
      return _cache = PublicProfileSettings.fromJson(decoded);
    } catch (_) {
      return _cache = const PublicProfileSettings();
    }
  }

  Future<PublicProfileSettings> save(PublicProfileSettings next) async {
    var handle = next.handle.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '');
    if (handle.length > 24) handle = handle.substring(0, 24);
    final clean = next.copyWith(
      handle: handle,
      bio: next.bio.length > 280 ? next.bio.substring(0, 280) : next.bio,
      displayName: next.displayName.length > 40
          ? next.displayName.substring(0, 40)
          : next.displayName,
    );
    _cache = clean;
    try {
      final f = await _file();
      await f.writeAsString(jsonEncode(clean.toJson()));
    } catch (_) {}
    return clean;
  }
}
