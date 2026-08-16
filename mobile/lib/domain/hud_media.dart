/// Now-playing snapshot for the Ride HUD media chip.
class HudNowPlaying {
  const HudNowPlaying({
    required this.listenerEnabled,
    required this.musicActive,
    required this.active,
    required this.playing,
    required this.title,
    required this.artist,
    required this.appLabel,
    required this.packageName,
    required this.canSkipNext,
    required this.canSkipPrevious,
  });

  static const idle = HudNowPlaying(
    listenerEnabled: false,
    musicActive: false,
    active: false,
    playing: false,
    title: '',
    artist: '',
    appLabel: '',
    packageName: '',
    canSkipNext: true,
    canSkipPrevious: true,
  );

  final bool listenerEnabled;
  final bool musicActive;
  final bool active;
  final bool playing;
  final String title;
  final String artist;
  final String appLabel;
  final String packageName;
  final bool canSkipNext;
  final bool canSkipPrevious;

  String get displayTitle {
    final t = title.trim();
    return t.isEmpty ? 'Musik' : t;
  }

  String get subtitle {
    final parts = <String>[
      if (artist.trim().isNotEmpty) artist.trim(),
      if (appLabel.trim().isNotEmpty) appLabel.trim(),
    ];
    return parts.join(' · ');
  }

  HudNowPlaying copyWith({
    bool? listenerEnabled,
    bool? musicActive,
    bool? active,
    bool? playing,
    String? title,
    String? artist,
    String? appLabel,
    String? packageName,
    bool? canSkipNext,
    bool? canSkipPrevious,
  }) {
    return HudNowPlaying(
      listenerEnabled: listenerEnabled ?? this.listenerEnabled,
      musicActive: musicActive ?? this.musicActive,
      active: active ?? this.active,
      playing: playing ?? this.playing,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      appLabel: appLabel ?? this.appLabel,
      packageName: packageName ?? this.packageName,
      canSkipNext: canSkipNext ?? this.canSkipNext,
      canSkipPrevious: canSkipPrevious ?? this.canSkipPrevious,
    );
  }

  factory HudNowPlaying.fromMap(dynamic raw) {
    if (raw is! Map) return idle;
    final m = Map<Object?, Object?>.from(raw);
    String str(Object? v) => v is String ? v : '';
    bool flag(Object? v) => v == true;
    bool flagOrTrue(Object? v) => v != false;
    return HudNowPlaying(
      listenerEnabled: flag(m['listenerEnabled']),
      musicActive: flag(m['musicActive']),
      active: flag(m['active']),
      playing: flag(m['playing']),
      title: str(m['title']),
      artist: str(m['artist']),
      appLabel: str(m['appLabel']),
      packageName: str(m['packageName']),
      canSkipNext: flagOrTrue(m['canSkipNext']),
      canSkipPrevious: flagOrTrue(m['canSkipPrevious']),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is HudNowPlaying &&
      other.listenerEnabled == listenerEnabled &&
      other.musicActive == musicActive &&
      other.active == active &&
      other.playing == playing &&
      other.title == title &&
      other.artist == artist &&
      other.appLabel == appLabel &&
      other.packageName == packageName &&
      other.canSkipNext == canSkipNext &&
      other.canSkipPrevious == canSkipPrevious;

  @override
  int get hashCode => Object.hash(
        listenerEnabled,
        musicActive,
        active,
        playing,
        title,
        artist,
        appLabel,
        packageName,
        canSkipNext,
        canSkipPrevious,
      );
}

/// HUD media chrome kind. Controls are not a 5th Clean-Mode nav stat —
/// they are transport, like Pause.
enum HudMediaChipKind { hidden, controls, enablePrompt }

HudMediaChipKind hudMediaChipKind({
  required bool cleanMode,
  required bool listenerEnabled,
  required bool promptDismissed,
  required bool hasSession,
  required bool musicActive,
  required bool optimisticHold,
}) {
  if (hasSession || musicActive || optimisticHold) {
    return HudMediaChipKind.controls;
  }
  if (!cleanMode && !listenerEnabled && !promptDismissed) {
    return HudMediaChipKind.enablePrompt;
  }
  return HudMediaChipKind.hidden;
}

bool hudMediaOptimisticHoldActive(DateTime? until, DateTime now) {
  return until != null && now.isBefore(until);
}
