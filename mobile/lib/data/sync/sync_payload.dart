/// Mirrors web `SyncPayload` (src/lib/sync/client.ts) — payloadVersion 2.
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
    this.rangeCalibration,
    this.maintenanceLogs,
    this.maintenanceIntervals,
    this.rideFeedbacks,
    this.recommendations,
    this.wishlistIds,
    this.bikePhotos,
    this.activeBikeId,
    this.savedRoutes,
    this.routeCollections,
    this.savedRouteMeta,
    this.preferredSport,
    this.onboardingDone,
    this.freeTierExtraBike,
    this.updatedAt,
    this.payloadVersion = 2,
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
  final dynamic rangeCalibration;
  final dynamic maintenanceLogs;
  final dynamic maintenanceIntervals;
  final dynamic rideFeedbacks;
  final dynamic recommendations;
  final dynamic wishlistIds;
  final dynamic bikePhotos;
  final String? activeBikeId;
  final dynamic savedRoutes;
  final dynamic routeCollections;
  final dynamic savedRouteMeta;
  final dynamic preferredSport;
  final bool? onboardingDone;
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
      rangeCalibration: json['rangeCalibration'],
      maintenanceLogs: json['maintenanceLogs'],
      maintenanceIntervals: json['maintenanceIntervals'],
      rideFeedbacks: json['rideFeedbacks'],
      recommendations: json['recommendations'],
      wishlistIds: json['wishlistIds'],
      bikePhotos: json['bikePhotos'],
      activeBikeId: json['activeBikeId'] as String?,
      savedRoutes: json['savedRoutes'] ?? json['saved_routes'],
      routeCollections: json['routeCollections'],
      savedRouteMeta: json['savedRouteMeta'],
      preferredSport: json['preferredSport'],
      onboardingDone: json['onboardingDone'] as bool?,
      freeTierExtraBike: json['freeTierExtraBike'] as bool?,
      updatedAt: json['updatedAt'] as String?,
      payloadVersion: (json['payloadVersion'] as num?)?.toInt() ?? 2,
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
        if (rangeCalibration != null) 'rangeCalibration': rangeCalibration,
        if (maintenanceLogs != null) 'maintenanceLogs': maintenanceLogs,
        if (maintenanceIntervals != null)
          'maintenanceIntervals': maintenanceIntervals,
        if (rideFeedbacks != null) 'rideFeedbacks': rideFeedbacks,
        if (recommendations != null) 'recommendations': recommendations,
        if (wishlistIds != null) 'wishlistIds': wishlistIds,
        if (bikePhotos != null) 'bikePhotos': bikePhotos,
        if (activeBikeId != null) 'activeBikeId': activeBikeId,
        if (savedRoutes != null) 'savedRoutes': savedRoutes,
        if (routeCollections != null) 'routeCollections': routeCollections,
        if (savedRouteMeta != null) 'savedRouteMeta': savedRouteMeta,
        if (preferredSport != null) 'preferredSport': preferredSport,
        if (onboardingDone != null) 'onboardingDone': onboardingDone,
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
    dynamic routeCollections,
    dynamic savedRouteMeta,
    String? subscriptionTier,
    dynamic commerceMode,
    dynamic rangeCalibration,
    dynamic maintenanceLogs,
    dynamic maintenanceIntervals,
    dynamic rideFeedbacks,
    dynamic recommendations,
    dynamic wishlistIds,
    dynamic bikePhotos,
    dynamic preferredSport,
    bool? onboardingDone,
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
      rangeCalibration: rangeCalibration ?? this.rangeCalibration,
      maintenanceLogs: maintenanceLogs ?? this.maintenanceLogs,
      maintenanceIntervals:
          maintenanceIntervals ?? this.maintenanceIntervals,
      rideFeedbacks: rideFeedbacks ?? this.rideFeedbacks,
      recommendations: recommendations ?? this.recommendations,
      wishlistIds: wishlistIds ?? this.wishlistIds,
      bikePhotos: bikePhotos ?? this.bikePhotos,
      activeBikeId: activeBikeId ?? this.activeBikeId,
      savedRoutes: savedRoutes ?? this.savedRoutes,
      routeCollections: routeCollections ?? this.routeCollections,
      savedRouteMeta: savedRouteMeta ?? this.savedRouteMeta,
      preferredSport: preferredSport ?? this.preferredSport,
      onboardingDone: onboardingDone ?? this.onboardingDone,
      freeTierExtraBike: freeTierExtraBike ?? this.freeTierExtraBike,
      updatedAt: updatedAt ?? this.updatedAt,
      payloadVersion: payloadVersion ?? this.payloadVersion,
    );
  }
}
