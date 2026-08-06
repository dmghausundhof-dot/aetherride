/// Mirrors web `SyncPayload` (src/lib/sync/client.ts).
class SyncPayload {
  const SyncPayload({
    this.bikes,
    this.rides,
    this.setups,
    this.consents,
    this.privacyZones,
    this.familyRiders,
    this.riderProfile,
    this.subscriptionTier,
    this.commerceMode,
    this.activeBikeId,
    this.updatedAt,
    this.payloadVersion = 1,
  });

  final dynamic bikes;
  final dynamic rides;
  final dynamic setups;
  final dynamic consents;
  final dynamic privacyZones;
  final dynamic familyRiders;
  final dynamic riderProfile;
  final String? subscriptionTier;
  final dynamic commerceMode;
  final String? activeBikeId;
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
      riderProfile: json['riderProfile'],
      subscriptionTier: json['subscriptionTier'] as String?,
      commerceMode: json['commerceMode'],
      activeBikeId: json['activeBikeId'] as String?,
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
        if (riderProfile != null) 'riderProfile': riderProfile,
        if (subscriptionTier != null) 'subscriptionTier': subscriptionTier,
        if (commerceMode != null) 'commerceMode': commerceMode,
        if (activeBikeId != null) 'activeBikeId': activeBikeId,
        if (updatedAt != null) 'updatedAt': updatedAt,
        'payloadVersion': payloadVersion,
      };

  SyncPayload copyWith({
    dynamic bikes,
    dynamic rides,
    dynamic setups,
    dynamic consents,
    String? activeBikeId,
    String? updatedAt,
    int? payloadVersion,
  }) {
    return SyncPayload(
      bikes: bikes ?? this.bikes,
      rides: rides ?? this.rides,
      setups: setups ?? this.setups,
      consents: consents ?? this.consents,
      privacyZones: privacyZones,
      familyRiders: familyRiders,
      riderProfile: riderProfile,
      subscriptionTier: subscriptionTier,
      commerceMode: commerceMode,
      activeBikeId: activeBikeId ?? this.activeBikeId,
      updatedAt: updatedAt ?? this.updatedAt,
      payloadVersion: payloadVersion ?? this.payloadVersion,
    );
  }
}
