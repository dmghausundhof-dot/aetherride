// Web-Chat-API Payload (Bike/Ride-Parität für Numeric-Guard-Engines).

import '../bike.dart';
import '../component.dart';
import '../ebike/range.dart';
import '../ride.dart';
import '../rider_profile.dart';
import '../setup.dart';
import 'coach_watch.dart';

String bikeCategoryApiId(BikeCategory c) => switch (c) {
      BikeCategory.mtbTrail => 'mtb_trail',
      BikeCategory.mtbAm => 'mtb_am',
      BikeCategory.mtbEnduro => 'mtb_enduro',
      BikeCategory.dh => 'dh',
      BikeCategory.gravel => 'gravel',
      BikeCategory.road => 'road',
      BikeCategory.urban => 'urban',
      BikeCategory.cargo => 'cargo',
      BikeCategory.folding => 'folding',
      BikeCategory.kids => 'kids',
      BikeCategory.emtb => 'emtb',
      BikeCategory.etrekking => 'etrekking',
      BikeCategory.hiking => 'hiking',
    };

String bikeTypeApiId(BikeCategory c) => switch (c) {
      BikeCategory.mtbTrail || BikeCategory.mtbAm => 'all_mountain',
      BikeCategory.mtbEnduro || BikeCategory.dh => 'enduro',
      BikeCategory.gravel => 'gravel',
      BikeCategory.road ||
      BikeCategory.urban ||
      BikeCategory.cargo ||
      BikeCategory.folding ||
      BikeCategory.kids =>
        'road',
      BikeCategory.emtb => 'e_mtb',
      BikeCategory.etrekking => 'e_gravel',
      BikeCategory.hiking => 'hiking',
    };

String? wheelApiId(WheelSize? w) => switch (w) {
      null => null,
      WheelSize.w275 => '27_5',
      WheelSize.w29 => '29',
      WheelSize.c700 => '700c',
      WheelSize.b650 => '650b',
    };

List<Map<String, dynamic>> _attrs(Map<String, dynamic> attrs) {
  return [
    for (final e in attrs.entries)
      if (e.key != BikeComponent.hoursAtInstallAttr)
        {
          'key': e.key,
          if (e.value is num) 'valueNum': e.value,
          if (e.value is String) 'valueText': e.value,
          'source': 'user_input',
          'verifiedAt': DateTime.now().toUtc().toIso8601String(),
        },
  ];
}

Map<String, dynamic> componentToChatJson(BikeComponent c) => {
      'id': c.id,
      'bikeId': c.bikeId,
      'slot': c.slot.apiId,
      if (c.catalogModelId != null) 'componentModelId': c.catalogModelId,
      if (c.manufacturer != null) 'manufacturer': c.manufacturer,
      if (c.model != null) 'model': c.model,
      'installedAt':
          (c.installedAt ?? DateTime.fromMillisecondsSinceEpoch(0))
              .toUtc()
              .toIso8601String(),
      if (c.removedAt != null)
        'removedAt': c.removedAt!.toUtc().toIso8601String(),
      'odometerKmAtInstall': c.odometerKm,
      'hoursAtInstall': c.hoursAtInstallResolved,
      'attributes': _attrs(c.attributes),
      'currentSettings': {
        for (final e in c.attributes.entries)
          if (e.value is num || e.value is String) e.key: e.value,
      },
    };

Map<String, dynamic> setupToChatJson(BikeSetup s) => {
      'id': s.id,
      'bikeId': s.bikeId,
      'version': s.version,
      'label': s.label,
      'conditions': s.conditions,
      'createdAt': s.createdAt.toUtc().toIso8601String(),
      'createdBy': s.createdBy,
      'isCurrent': s.isCurrent,
      if (s.parentSetupId != null) 'parentSetupId': s.parentSetupId,
      if (s.linkedRideId != null) 'linkedRideId': s.linkedRideId,
      'values': [for (final v in s.values) v.toJson()],
    };

Map<String, dynamic> bikeToChatJson(
  Bike b, {
  List<BikeComponent> components = const [],
  List<BikeSetup> setups = const [],
}) {
  final iso = DateTime.now().toUtc().toIso8601String();
  return {
    'id': b.id,
    'name': b.name,
    'category': bikeCategoryApiId(b.category),
    'type': bikeTypeApiId(b.category),
    if (b.brand != null) 'brand': b.brand,
    if (b.model != null) 'model': b.model,
    if (b.year != null) 'year': b.year,
    if (b.catalogBikeId != null) 'catalogBikeId': b.catalogBikeId,
    if (b.frameSize != null) 'frameSize': b.frameSize,
    if (b.travelFrontMm != null) 'travelFrontMm': b.travelFrontMm,
    if (b.travelRearMm != null) 'travelRearMm': b.travelRearMm,
    if (wheelApiId(b.wheelSize) != null)
      'wheelSizeFront': wheelApiId(b.wheelSize),
    'isActive': b.isActive,
    'isEbike': b.hasElectricAssist,
    'createdAt': iso,
    'updatedAt': iso,
    'totalOdometerKm': b.odometerKm,
    'totalHours': b.hours,
    'components': [for (final c in components) componentToChatJson(c)],
    'setups': [for (final s in setups) setupToChatJson(s)],
  };
}

Map<String, dynamic> rideToChatJson(RideRecord r, {String sportType = 'enduro'}) {
  final m = r.summary;
  return {
    'id': r.id,
    'bikeId': r.bikeId,
    if (r.setupId != null) 'setupId': r.setupId,
    if (r.routeId != null) 'savedRouteId': r.routeId,
    'sportType': sportType,
    'startTime': r.startedAt.toUtc().toIso8601String(),
    if (r.endedAt != null) 'endTime': r.endedAt!.toUtc().toIso8601String(),
    'distanceM': r.distanceKm * 1000,
    'elevationGainM': r.elevationM,
    'durationSec': r.movingTimeSec,
    'summaryMetrics': {
      'gForcePeak': (m['gForcePeak'] as num?)?.toDouble() ??
          (m['peakG'] as num?)?.toDouble() ??
          0,
      'gForceRms': (m['gForceRms'] as num?)?.toDouble() ?? 0,
      'leanAngleMax': (m['leanAngleMax'] as num?)?.toDouble() ?? 0,
      'impactCount': (m['impactCount'] as num?)?.toInt() ?? 0,
      'flowScore': (m['flowScore'] as num?)?.toDouble() ??
          (m['avgFlow'] as num?)?.toDouble() ??
          0,
    },
    if (r.name != null) 'notes': r.name,
  };
}

Map<String, dynamic> buildChatApiBody({
  required String query,
  required String tool,
  required RiderProfile profile,
  required double effectiveWeightKg,
  required List<Bike> bikes,
  required Bike? active,
  required Map<String, List<BikeComponent>> componentsByBike,
  required Map<String, List<BikeSetup>> setupsByBike,
  required List<RideRecord> rides,
  RangeCalibration? calibration,
  List<CoachNotice> notices = const [],
  String lang = 'de',
}) {
  final sport = active != null ? bikeTypeApiId(active.category) : 'enduro';
  return {
    'query': query,
    'tool': tool,
    'lang': lang,
    'profile': {
      ...profile.toJson(),
      'riderWeightKg': effectiveWeightKg,
    },
    if (active != null)
      'bike': bikeToChatJson(
        active,
        components: componentsByBike[active.id] ?? const [],
        setups: setupsByBike[active.id] ?? const [],
      ),
    'bikes': [
      for (final b in bikes)
        bikeToChatJson(
          b,
          components: componentsByBike[b.id] ?? const [],
          setups: setupsByBike[b.id] ?? const [],
        ),
    ],
    'rides': [for (final r in rides) rideToChatJson(r, sportType: sport)],
    if (calibration != null) 'calibration': calibration.toJson(),
    if (notices.isNotEmpty)
      'notices': [for (final n in notices) n.toJson()],
  };
}
