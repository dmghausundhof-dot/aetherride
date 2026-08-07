/// Rider-Profil (Spiegel src/types RiderProfile + Sync).
class RiderProfile {
  const RiderProfile({
    this.style = 'flow',
    this.skillLevel = 3,
    this.riderWeightKg = 75,
    this.preferSteep = false,
    this.preferTechnical = false,
    this.preferFlow = true,
    this.eBikeAssistPreference = 'tour',
    this.avgRideDurationMin = 90,
    this.weeklyDistanceKm = 40,
  });

  final String style; // aggressive|flow|efficient|explorative
  final int skillLevel; // 1–5
  final double riderWeightKg;
  final bool preferSteep;
  final bool preferTechnical;
  final bool preferFlow;
  final String eBikeAssistPreference;
  final double avgRideDurationMin;
  final double weeklyDistanceKm;

  RiderProfile copyWith({
    String? style,
    int? skillLevel,
    double? riderWeightKg,
    bool? preferSteep,
    bool? preferTechnical,
    bool? preferFlow,
    String? eBikeAssistPreference,
    double? avgRideDurationMin,
    double? weeklyDistanceKm,
  }) {
    return RiderProfile(
      style: style ?? this.style,
      skillLevel: skillLevel ?? this.skillLevel,
      riderWeightKg: riderWeightKg ?? this.riderWeightKg,
      preferSteep: preferSteep ?? this.preferSteep,
      preferTechnical: preferTechnical ?? this.preferTechnical,
      preferFlow: preferFlow ?? this.preferFlow,
      eBikeAssistPreference:
          eBikeAssistPreference ?? this.eBikeAssistPreference,
      avgRideDurationMin: avgRideDurationMin ?? this.avgRideDurationMin,
      weeklyDistanceKm: weeklyDistanceKm ?? this.weeklyDistanceKm,
    );
  }

  Map<String, dynamic> toJson() => {
        'style': style,
        'skillLevel': skillLevel,
        'riderWeightKg': riderWeightKg,
        'preferences': {
          'preferSteep': preferSteep,
          'preferTechnical': preferTechnical,
          'preferFlow': preferFlow,
          'eBikeAssistPreference': eBikeAssistPreference,
        },
        'fitnessIndicators': {
          'avgRideDurationMin': avgRideDurationMin,
          'weeklyDistanceKm': weeklyDistanceKm,
        },
      };

  factory RiderProfile.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const RiderProfile();
    final prefs = json['preferences'] is Map
        ? Map<String, dynamic>.from(json['preferences'] as Map)
        : <String, dynamic>{};
    final fitness = json['fitnessIndicators'] is Map
        ? Map<String, dynamic>.from(json['fitnessIndicators'] as Map)
        : <String, dynamic>{};
    return RiderProfile(
      style: (json['style'] as String?) ?? 'flow',
      skillLevel: (json['skillLevel'] as num?)?.toInt() ?? 3,
      riderWeightKg: (json['riderWeightKg'] as num?)?.toDouble() ?? 75,
      preferSteep: prefs['preferSteep'] == true,
      preferTechnical: prefs['preferTechnical'] == true,
      preferFlow: prefs['preferFlow'] != false,
      eBikeAssistPreference:
          (prefs['eBikeAssistPreference'] as String?) ?? 'tour',
      avgRideDurationMin:
          (fitness['avgRideDurationMin'] as num?)?.toDouble() ?? 90,
      weeklyDistanceKm:
          (fitness['weeklyDistanceKm'] as num?)?.toDouble() ?? 40,
    );
  }
}

class FamilyRider {
  const FamilyRider({
    required this.id,
    required this.displayName,
    required this.weightKg,
    this.setupIds = const [],
    this.notes,
  });

  final String id;
  final String displayName;
  final double weightKg;
  final List<String> setupIds;
  final String? notes;

  Map<String, dynamic> toJson() => {
        'id': id,
        'displayName': displayName,
        'weightKg': weightKg,
        'setupIds': setupIds,
        if (notes != null) 'notes': notes,
      };

  factory FamilyRider.fromJson(Map<String, dynamic> json) {
    return FamilyRider(
      id: (json['id'] as String?) ?? '',
      displayName: (json['displayName'] as String?) ?? 'Fahrer',
      weightKg: (json['weightKg'] as num?)?.toDouble() ?? 70,
      setupIds: [
        for (final e in (json['setupIds'] as List? ?? const []))
          if (e is String) e,
      ],
      notes: json['notes'] as String?,
    );
  }
}
