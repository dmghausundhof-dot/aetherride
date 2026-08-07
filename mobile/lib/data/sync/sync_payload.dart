/// Mirrors web `SyncPayload` (src/lib/sync/client.ts).
class SyncPayload {
  const SyncPayload({
    this.bikes,
    this.rides,
    this.setups,
    this.consents,
    this.privacyZones,
    this.familyRiders,
    this.activeFamilyRiderId,
    this.riderProfile,
    this.subscriptionTier,
    this.commerceMode,
    this.activeBikeId,
    this.savedRoutes,
    this.freeTierExtraBike,
    this.updatedAt,
    this.payloadVersion = 1,
  });

  final dynamic bikes;
  final dynamic rides;
  final dynamic setups;
  final dynamic consents;
  final dynamic privacyZones;
  final dynamic familyRiders;
  final String? activeFamilyRiderId;
  final dynamic riderProfile;
  final String? subscriptionTier;
  final dynamic commerceMode;
  final String? activeBikeId;
  final dynamic savedRoutes;
  final bool? freeTierExtraBike;
  final String? updatedAt;
  final int payloadVersion;

  factory SyncPayload.fromJson(Map<String, dynamic> json) {
    return SyncPayload(
      bikes: json['bikes'],
      rides: json['rides'],
      setups: json['setups'],
      consents: json['consents'],
      privacyZones: json['privacyZones'],
      familyRiders: json['familyRiders'],
      activeFamilyRiderId: json['activeFamilyRiderId'] as String?,
      riderProfile: json['riderProfile'],
      subscriptionTier: json['subscriptionTier'] as String?,
      commerceMode: json['commerceMode'],
      activeBikeId: json['activeBikeId'] as String?,
      savedRoutes: json['savedRoutes'] ?? json['saved_routes'],
      freeTierExtraBike: json['freeTierExtraBike'] as bool?,
      updatedAt: json['updatedAt'] as String?,
      payloadVersion: (json['payloadVersion'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
        if (bikes != null) 'bikes': bikes,
        if (rides != null) 'rides': rides,
        if (setups != null) 'setups': setups,
        if (consents != null) 'consents': consents,
        if (privacyZones != null) 'privacyZones': privacyZones,
        if (familyRiders != null) 'familyRiders': familyRiders,
        if (activeFamilyRiderId != null)
          'activeFamilyRiderId': activeFamilyRiderId,
        if (riderProfile != null) 'riderProfile': riderProfile,
        if (subscriptionTier != null) 'subscriptionTier': subscriptionTier,
        if (commerceMode != null) 'commerceMode': commerceMode,
        if (activeBikeId != null) 'activeBikeId': activeBikeId,
        if (savedRoutes != null) 'savedRoutes': savedRoutes,
        if (freeTierExtraBike != null) 'freeTierExtraBike': freeTierExtraBike,
        if (updatedAt != null) 'updatedAt': updatedAt,
        'payloadVersion': payloadVersion,
      };

  SyncPayload copyWith({
    dynamic bikes,
    dynamic rides,
    dynamic setups,
    dynamic consents,
    dynamic privacyZones,
    dynamic familyRiders,
    String? activeFamilyRiderId,
    dynamic riderProfile,
    dynamic savedRoutes,
    String? subscriptionTier,
    dynamic commerceMode,
    bool? freeTierExtraBike,
    String? activeBikeId,
    String? updatedAt,
    int? payloadVersion,
  }) {
    return SyncPayload(
      bikes: bikes ?? this.bikes,
      rides: rides ?? this.rides,
      setups: setups ?? this.setups,
      consents: consents ?? this.consents,
      privacyZones: privacyZones ?? this.privacyZones,
      familyRiders: familyRiders ?? this.familyRiders,
      activeFamilyRiderId:
          activeFamilyRiderId ?? this.activeFamilyRiderId,
      riderProfile: riderProfile ?? this.riderProfile,
      subscriptionTier: subscriptionTier ?? this.subscriptionTier,
      commerceMode: commerceMode ?? this.commerceMode,
      activeBikeId: activeBikeId ?? this.activeBikeId,
      savedRoutes: savedRoutes ?? this.savedRoutes,
      freeTierExtraBike: freeTierExtraBike ?? this.freeTierExtraBike,
      updatedAt: updatedAt ?? this.updatedAt,
      payloadVersion: payloadVersion ?? this.payloadVersion,
    );
  }
}
