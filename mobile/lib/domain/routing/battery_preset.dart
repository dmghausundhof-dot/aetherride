/// Mid-ride battery / display presets (N-04 / N-09).
///
/// Default is battery-saving: no Keep-Screen-On until opt-in (Lenker / Ultra).
enum RideBatteryPreset {
  /// Voice + haptic; screen may sleep. Default.
  pocket,

  /// Keep-Screen-On after consent — costs battery.
  lenker,

  /// Wake briefly on nav cues / alerts — costs battery.
  ultra,
}

extension RideBatteryPresetX on RideBatteryPreset {
  String get id => name;

  String get titleDe => switch (this) {
        RideBatteryPreset.pocket => 'Pocket',
        RideBatteryPreset.lenker => 'Lenker',
        RideBatteryPreset.ultra => 'Ultra',
      };

  String get subtitleDe => switch (this) {
        RideBatteryPreset.pocket => 'Stimme + Haptik, Display darf aus',
        RideBatteryPreset.lenker => 'Display an lassen',
        RideBatteryPreset.ultra => 'Display nur bei Abbiegen wecken',
      };

  /// True for modes that cost more battery (label „kostet Akku“).
  bool get costsBattery =>
      this == RideBatteryPreset.lenker || this == RideBatteryPreset.ultra;

  /// Continuous Keep-Screen-On (wakelock).
  bool get keepScreenOn => this == RideBatteryPreset.lenker;

  /// Brief wake on TTS / off-route / critical cues.
  bool get wakeOnCue => this == RideBatteryPreset.ultra;

  static RideBatteryPreset fromId(String? raw) {
    switch (raw) {
      case 'lenker':
        return RideBatteryPreset.lenker;
      case 'ultra':
        return RideBatteryPreset.ultra;
      case 'pocket':
      default:
        return RideBatteryPreset.pocket;
    }
  }
}
