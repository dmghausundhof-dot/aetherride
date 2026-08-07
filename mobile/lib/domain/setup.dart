// Immutable Setup-Snapshot — Spiegel src/types/garage.ts Setup (vereinfacht).

class SetupValue {
  const SetupValue({
    required this.adjusterKey,
    required this.valueNum,
    this.unit = 'clicks',
    this.slot,
    this.bikeComponentId,
  });

  final String adjusterKey;
  final double valueNum;
  final String unit;
  final String? slot;
  final String? bikeComponentId;

  Map<String, dynamic> toJson() => {
        'adjusterKey': adjusterKey,
        'valueNum': valueNum,
        'unit': unit,
        if (slot != null) 'slot': slot,
        if (bikeComponentId != null) 'bikeComponentId': bikeComponentId,
      };

  factory SetupValue.fromJson(Map<String, dynamic> json) {
    return SetupValue(
      adjusterKey: (json['adjusterKey'] as String?) ??
          (json['key'] as String?) ??
          'unknown',
      valueNum: (json['valueNum'] as num?)?.toDouble() ??
          (json['value'] as num?)?.toDouble() ??
          0,
      unit: (json['unit'] as String?) ?? 'clicks',
      slot: json['slot'] as String?,
      bikeComponentId: json['bikeComponentId'] as String?,
    );
  }
}

class BikeSetup {
  const BikeSetup({
    required this.id,
    required this.bikeId,
    required this.label,
    required this.values,
    required this.createdAt,
    this.immutable = true,
    this.isCurrent = false,
    this.conditions = 'general',
    this.version = 1,
    this.parentSetupId,
    this.linkedRideId,
    this.createdBy = 'user',
  });

  final String id;
  final String bikeId;
  final String label;
  final List<SetupValue> values;
  final DateTime createdAt;
  final bool immutable;
  final bool isCurrent;
  final String conditions;
  final int version;
  final String? parentSetupId;
  final String? linkedRideId;
  final String createdBy;

  double? valueFor(String adjusterKey) {
    for (final v in values) {
      if (v.adjusterKey == adjusterKey) return v.valueNum;
    }
    return null;
  }

  Map<String, double> get adjusterMap => {
        for (final v in values) v.adjusterKey: v.valueNum,
      };

  BikeSetup copyWith({
    String? label,
    List<SetupValue>? values,
    bool? isCurrent,
    String? conditions,
    int? version,
    String? parentSetupId,
    String? linkedRideId,
    String? createdBy,
  }) {
    return BikeSetup(
      id: id,
      bikeId: bikeId,
      label: label ?? this.label,
      values: values ?? this.values,
      createdAt: createdAt,
      immutable: immutable,
      isCurrent: isCurrent ?? this.isCurrent,
      conditions: conditions ?? this.conditions,
      version: version ?? this.version,
      parentSetupId: parentSetupId ?? this.parentSetupId,
      linkedRideId: linkedRideId ?? this.linkedRideId,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  /// Default-Baseline wenn noch kein Setup existiert.
  static List<SetupValue> defaultValues() => const [
        SetupValue(adjusterKey: 'fork.rebound', valueNum: 8, unit: 'clicks'),
        SetupValue(adjusterKey: 'fork.lsc', valueNum: 6, unit: 'clicks'),
        SetupValue(
          adjusterKey: 'rear_shock.rebound',
          valueNum: 8,
          unit: 'clicks',
        ),
        SetupValue(
          adjusterKey: 'tire_front.pressure_psi',
          valueNum: 22,
          unit: 'psi',
        ),
        SetupValue(
          adjusterKey: 'tire_rear.pressure_psi',
          valueNum: 24,
          unit: 'psi',
        ),
      ];
}
