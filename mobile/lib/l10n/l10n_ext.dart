import 'package:flutter/widgets.dart';

import '../data/routing/offline_pack_catalog.dart';
import '../domain/ble/bike_ble_kind.dart';
import '../domain/ble/watch_candidate.dart';
import '../domain/bike.dart';
import '../domain/bike_assist.dart';
import '../domain/compatibility/rules.dart';
import '../domain/component.dart';
import '../domain/garage/die_box.dart';
import '../domain/garage/werkstatt_setup.dart';
import '../domain/hud_compass.dart';
import '../domain/post_ride/analyze.dart';
import '../domain/privacy/consents.dart';
import '../domain/ride.dart';
import '../domain/routing/battery_preset.dart';
import '../domain/routing/connectivity_chip.dart';
import '../domain/routing/tour_filters.dart';
import '../domain/routing/trail_difficulty.dart';
import '../domain/sport/discipline_ux.dart';
import '../data/routing/routing_client.dart';
import 'app_localizations.dart';

/// Null when the widget tree has no [AppLocalizations] (unit tests).
extension AetherL10nContext on BuildContext {
  AppLocalizations? get l10nOrNull =>
      Localizations.of<AppLocalizations>(this, AppLocalizations);
}

/// Sport-abhängige + Filter-Labels über [AppLocalizations].
///
/// Zentral gehalten, damit Discover-Filter und Parallel-Agenten dieselbe Map
/// nutzen (weniger Merge-Konflikt-Risiko als verstreute Switch-Blöcke).
extension AetherL10n on AppLocalizations {
  String homeSubtitle({BikeCategory? sport, String? weatherLine}) {
    final base = switch (sport?.family) {
      SportFamily.mtb => homeSubtitleMtb,
      SportFamily.gravel => homeSubtitleGravel,
      SportFamily.road => homeSubtitleRoad,
      SportFamily.urban => homeSubtitleUrban,
      SportFamily.ebike => homeSubtitleEbike,
      SportFamily.other || null => homeSubtitleDefault,
    };
    if (weatherLine == null || weatherLine.isEmpty) return base;
    return homeSubtitleWithWeather(weatherLine, base);
  }

  String tipHeroTitleFor(BikeCategory? sport) => switch (sport?.family) {
        SportFamily.mtb => tipHeroTitleMtb,
        SportFamily.gravel => tipHeroTitleGravel,
        SportFamily.road => tipHeroTitleRoad,
        SportFamily.urban => tipHeroTitleUrban,
        SportFamily.ebike => tipHeroTitleEbike,
        _ => tipHeroTitleDefault,
      };

  String tipHeroSubtitleFor(BikeCategory? sport) => switch (sport?.family) {
        SportFamily.mtb => tipHeroSubtitleMtb,
        SportFamily.gravel => tipHeroSubtitleGravel,
        SportFamily.road => tipHeroSubtitleRoad,
        SportFamily.urban => tipHeroSubtitleUrban,
        SportFamily.ebike => tipHeroSubtitleEbike,
        _ => tipHeroSubtitleDefault,
      };

  String chassisLayerLabelFor(BikeCategory? sport) =>
      (sport?.showsChassisLayer ?? true) ? chassisLayer : sensorLayer;

  String durationChipLabel(int minutes) {
    if (minutes <= 0) return durationAny;
    if (minutes == 45) return '~45';
    if (minutes == 60) return '~60';
    if (minutes == 90) return '~90';
    if (minutes == 150) return duration2to3h;
    return '~$minutes';
  }

  String tourSurfaceChip(TourSurfaceKey key) => switch (key) {
        TourSurfaceKey.asphalt => filterSurfaceAsphalt,
        TourSurfaceKey.gravel => filterSurfaceGravel,
        TourSurfaceKey.trail => filterSurfaceTrail,
        TourSurfaceKey.mixed => filterSurfaceMixed,
      };

  String tourSurfaceHint(TourSurfaceKey key) => switch (key) {
        TourSurfaceKey.asphalt => filterSurfaceAsphaltHint,
        TourSurfaceKey.gravel => filterSurfaceGravelHint,
        TourSurfaceKey.trail => filterSurfaceTrailHint,
        TourSurfaceKey.mixed => filterSurfaceMixedHint,
      };

  String tourSurfaceFull(String raw) {
    final key = TourFilters.parseSurface(raw);
    if (key == null) return raw;
    return switch (key) {
      TourSurfaceKey.asphalt => filterSurfaceAsphaltFull,
      TourSurfaceKey.gravel => filterSurfaceGravelFull,
      TourSurfaceKey.trail => filterSurfaceTrailFull,
      TourSurfaceKey.mixed => filterSurfaceMixedFull,
    };
  }

  String tourEffortChip(TourEffortKey key) => switch (key) {
        TourEffortKey.easy => filterEffortEasy,
        TourEffortKey.mid => filterEffortMid,
        TourEffortKey.hard => filterEffortHard,
      };

  String tourEffortHint(TourEffortKey key) => switch (key) {
        TourEffortKey.easy => filterEffortEasyHint,
        TourEffortKey.mid => filterEffortMidHint,
        TourEffortKey.hard => filterEffortHardHint,
      };

  String tourElevationChip(TourElevationKey key) => switch (key) {
        TourElevationKey.flat => filterElevFlat,
        TourElevationKey.hilly => filterElevHilly,
        TourElevationKey.alpine => filterElevAlpine,
      };

  String tourVisibilityChip(TourVisibilityKey key) => switch (key) {
        TourVisibilityKey.allMine => filterVisibilityAll,
        TourVisibilityKey.privateOnly => discoverPrivateCap,
        TourVisibilityKey.sharedOnly => filterVisibilityPublic,
      };

  String tourDistanceMaxChip(double km) {
    if (km == 20) return filterDistMax20;
    if (km == 40) return filterDistMax40;
    if (km == 70) return filterDistMax70;
    return '≤ ${km.toStringAsFixed(0)} km';
  }

  String trailDifficultyFriendly(TrailDifficulty d) => switch (d) {
        TrailDifficulty.s0 => trailDiffEasy,
        TrailDifficulty.s1 => trailDiffMedium,
        TrailDifficulty.s2 => trailDiffHard,
        TrailDifficulty.s3 => filterEffortHard,
        TrailDifficulty.s3plus => trailDiffVeryHard,
        TrailDifficulty.open => trailDiffUnrated,
      };

  String trailDifficultyTech(TrailDifficulty d) => switch (d) {
        TrailDifficulty.s0 => 'S0',
        TrailDifficulty.s1 => 'S1',
        TrailDifficulty.s2 => 'S2',
        TrailDifficulty.s3 => 'S3',
        TrailDifficulty.s3plus => 'S3+',
        TrailDifficulty.open => trailDiffOpen,
      };

  String tourFormChip(TourFormKey key) => switch (key) {
        TourFormKey.all => filterFormAll,
        TourFormKey.loop => filterLoopsOnly,
        TourFormKey.pointToPoint => filterFormPointToPoint,
        TourFormKey.downhill => filterFormDownhill,
      };

  String tourFormHint(TourFormKey key) => switch (key) {
        TourFormKey.all => '',
        TourFormKey.loop => filterLoopsOnlyTooltip,
        TourFormKey.pointToPoint => filterFormPointToPointTooltip,
        TourFormKey.downhill => filterFormDownhillTooltip,
      };

  String tourSportChip(TourSportKey key) => switch (key) {
        TourSportKey.mtb => bikeCatMtb,
        TourSportKey.emtb => bikeCatEmtb,
        TourSportKey.gravel => bikeCatGravel,
        TourSportKey.road => bikeCatRoad,
        TourSportKey.urban => bikeCatUrban,
        TourSportKey.hiking => bikeCatHiking,
        TourSportKey.dh => bikeCatDh,
      };

  String trailDifficultyFull(TrailDifficulty d) => d == TrailDifficulty.open
      ? trailDifficultyFriendly(d)
      : '${trailDifficultyFriendly(d)} (${trailDifficultyTech(d)})';

  String consentTitle(ConsentPurpose p) => switch (p) {
        ConsentPurpose.rawDataUpload => consentRawTitle,
        ConsentPurpose.heatmapContribution => consentHeatmapTitle,
        ConsentPurpose.productRecommendations => consentRecoTitle,
        ConsentPurpose.analytics => consentAnalyticsTitle,
        ConsentPurpose.healthData => consentHealthTitle,
      };

  String consentBody(ConsentPurpose p) => switch (p) {
        ConsentPurpose.rawDataUpload => consentRawBody,
        ConsentPurpose.heatmapContribution => consentHeatmapBody,
        ConsentPurpose.productRecommendations => consentRecoBody,
        ConsentPurpose.analytics => consentAnalyticsBody,
        ConsentPurpose.healthData => consentHealthBody,
      };

  String dieBoxChipLabel(String label) => switch (label) {
        'Licht' => dieBoxChipLight,
        'Schloss' => dieBoxChipLock,
        'Träger' => dieBoxChipRack,
        'Taschen' => dieBoxChipBags,
        'Reifen' => dieBoxChipTires,
        'Vario' => dieBoxChipDropper,
        'Bremsen' => dieBoxChipBrakes,
        'Park | Trail' => dieBoxChipParkTrail,
        'Federweg' => dieBoxChipTravel,
        'CSC' => dieBoxChipCsc,
        'Akku ehrlich' => dieBoxChipBatteryHonest,
        'SAG' => dieBoxChipSag,
        'Kette' => dieBoxChipChain,
        'Druck' => dieBoxChipPressure,
        'Cockpit' => dieBoxChipCockpit,
        _ => label,
      };

  DieBoxTodayItem localizeDieBoxItem(DieBoxTodayItem item) {
    switch (item.id) {
      case DieBoxItemId.setActive:
        return item.copyWith(
          title: dieBoxSetActiveTitle,
          hint: dieBoxSetActiveHint,
          cta: dieBoxSetActiveCta,
        );
      case DieBoxItemId.lightsMissing:
        return item.copyWith(
          title: dieBoxLightsTitle,
          hint: dieBoxLightsHint,
          cta: dieBoxLightsCta,
        );
      case DieBoxItemId.lockMissing:
        return item.copyWith(
          title: dieBoxLockTitle,
          hint: dieBoxLockHint,
          cta: dieBoxLockCta,
        );
      case DieBoxItemId.rackMissing:
        return item.copyWith(
          title: dieBoxRackTitle,
          hint: dieBoxRackHint,
          cta: dieBoxRackCta,
        );
      case DieBoxItemId.bagsMissing:
        return item.copyWith(
          title: dieBoxBagsTitle,
          hint: dieBoxBagsHint,
          cta: dieBoxBagsCta,
        );
      case DieBoxItemId.pressureUnknown:
        final tire = item.title.startsWith('Reifendruck');
        return item.copyWith(
          title: tire ? dieBoxTirePressureTitle : dieBoxPressureMissingTitle,
          hint: tire ? dieBoxTirePressureHint : dieBoxPressureMissingHint,
          cta: dieBoxPressureMissingCta,
        );
      case DieBoxItemId.travelUnknown:
        return item.copyWith(
          title: dieBoxTravelMissingTitle,
          hint: dieBoxTravelMissingHint,
          cta: dieBoxTravelMissingCta,
        );
      case DieBoxItemId.sagUnknown:
        return item.copyWith(
          title: dieBoxSagMissingTitle,
          hint: dieBoxSagMissingHint,
          cta: dieBoxSagMissingCta,
        );
      case DieBoxItemId.chainTeach:
        return item.copyWith(
          title: dieBoxChainTitle,
          hint: dieBoxChainHint,
          cta: dieBoxChainCta,
        );
      case DieBoxItemId.brakesUnknown:
        return item.copyWith(
          title: dieBoxBrakesTitle,
          hint: dieBoxBrakesHint,
          cta: dieBoxBrakesCta,
        );
      case DieBoxItemId.dueCare:
        final chain = item.slot == ComponentSlot.chain;
        final remaining = item.due?.remainingLabel;
        final source = item.due?.sourceLabel;
        final careHint = [
          if (remaining != null && remaining.isNotEmpty)
            maintRemainingFor(remaining),
          if (source != null && source.isNotEmpty) source,
        ].join(' · ');
        return item.copyWith(
          title: chain
              ? dieBoxChainDueTitle
              : maintIntervalLabel(item.due?.label ?? item.title),
          hint: chain ? dieBoxChainDueHint : careHint,
          cta: done,
        );
      case DieBoxItemId.parkTrail:
        return item.copyWith(
          title: dieBoxParkTrailTitle,
          hint: dieBoxParkTrailHint,
          cta: dieBoxParkTrailCta,
        );
      case DieBoxItemId.pairCsc:
        return item;
    }
  }

  String dieBoxReadiness(DieBoxReadiness r) => switch (r) {
        DieBoxReadiness.ready => dieBoxReady,
        DieBoxReadiness.almost => dieBoxAlmost,
        DieBoxReadiness.unknown => dieBoxUnknown,
      };

  String dieBoxSentenceFor(Bike bike, DieBoxPlan plan) {
    final kind = plan.setup.kind;
    final chips = {for (final c in plan.chips) c.label: c.known};
    bool known(String label) => chips[label] == true;

    if (kind == WerkstattKind.urban) {
      if (plan.readiness == DieBoxReadiness.ready) {
        return dieBoxSentenceEverydayReady(bike.name);
      }
      return dieBoxSentenceHome(bike.name);
    }
    if (kind == WerkstattKind.gravel) {
      final wheel = bike.wheelSize?.label;
      final bits = <String>[
        if (wheel != null) wheel,
        if (known('Druck')) dieBoxBitPressureLogged,
        if (known('Taschen')) dieBoxBitBagsYes,
      ];
      if (bits.isEmpty) {
        return plan.readiness == DieBoxReadiness.ready
            ? dieBoxSentenceEverydayReady(bike.name)
            : dieBoxSentenceHome(bike.name);
      }
      final joined = bits.join(' · ');
      return plan.readiness == DieBoxReadiness.ready
          ? dieBoxSentenceReadyBits(bike.name, joined)
          : dieBoxSentenceBits(bike.name, joined);
    }
    if (kind == WerkstattKind.road) {
      final wheel = bike.wheelSize?.label;
      final bits = <String>[
        if (wheel != null) wheel,
        if (known('Kette')) dieBoxBitChainYes,
        if (known('Druck')) dieBoxBitPressureLogged,
      ];
      if (bits.isEmpty) {
        return dieBoxSentenceHome(bike.name);
      }
      final joined = bits.join(' · ');
      return plan.readiness == DieBoxReadiness.ready
          ? dieBoxSentenceReadyBits(bike.name, joined)
          : dieBoxSentenceBits(bike.name, joined);
    }
    if (kind == WerkstattKind.mtb) {
      if (plan.showParkTrail && plan.parkSetup?.isCurrent == true) {
        return dieBoxSentencePark;
      }
      if ((bike.travelFrontMm ?? 0) == 0 && (bike.travelRearMm ?? 0) == 0) {
        return dieBoxSentenceHome(bike.name);
      }
      final travel = '${bike.travelFrontMm ?? '–'}/${bike.travelRearMm ?? '–'}';
      final drive = bike.hasElectricAssist ? dieBoxDriveAssist : '';
      return plan.readiness == DieBoxReadiness.ready
          ? dieBoxSentenceMtbReady(bike.name, travel, drive)
          : dieBoxSentenceMtb(bike.name, travel, drive);
    }
    return dieBoxSentenceFallback(bike.name);
  }

  String? lastRideHeroLineFor(RideRecord? ride) {
    if (ride == null) return null;
    if (ride.distanceKm >= 0.05) {
      return lastRideKm(ride.distanceKm.toStringAsFixed(1));
    }
    return lastRideNoGps;
  }

  String componentSlotLabel(ComponentSlot slot) => switch (slot) {
        ComponentSlot.frame => garageSlotFrame,
        ComponentSlot.fork => garageSlotFork,
        ComponentSlot.rearShock => garageSlotRearShock,
        ComponentSlot.headset => garageSlotHeadset,
        ComponentSlot.stem => garageSlotStem,
        ComponentSlot.handlebar => garageSlotHandlebar,
        ComponentSlot.grips => garageSlotGrips,
        ComponentSlot.seatpost => garageSlotSeatpost,
        ComponentSlot.saddle => garageSlotSaddle,
        ComponentSlot.frontHub => garageSlotFrontHub,
        ComponentSlot.rearHub => garageSlotRearHub,
        ComponentSlot.frontRim => garageSlotFrontRim,
        ComponentSlot.rearRim => garageSlotRearRim,
        ComponentSlot.tireFront => garageSlotTireFront,
        ComponentSlot.tireRear => garageSlotTireRear,
        ComponentSlot.cassette => garageSlotCassette,
        ComponentSlot.chain => garageSlotChain,
        ComponentSlot.crankset => garageSlotCrankset,
        ComponentSlot.bottomBracket => garageSlotBottomBracket,
        ComponentSlot.frontDerailleur => garageSlotFrontDerailleur,
        ComponentSlot.rearDerailleur => garageSlotRearDerailleur,
        ComponentSlot.shifter => garageSlotShifter,
        ComponentSlot.brakeFront => garageSlotBrakeFront,
        ComponentSlot.brakeRear => garageSlotBrakeRear,
        ComponentSlot.rotorFront => garageSlotRotorFront,
        ComponentSlot.rotorRear => garageSlotRotorRear,
        ComponentSlot.motor => garageSlotMotor,
        ComponentSlot.battery => garageSlotBattery,
        ComponentSlot.display => garageSlotDisplay,
        ComponentSlot.light => garageSlotLight,
        ComponentSlot.lock => garageSlotLock,
        ComponentSlot.rack => garageSlotRack,
        ComponentSlot.bags => garageSlotBags,
        ComponentSlot.other => garageSlotOther,
      };

  String componentGroupLabel(ComponentGroup group) => switch (group) {
        ComponentGroup.suspension => garageGroupSuspension,
        ComponentGroup.wheels => garageGroupWheels,
        ComponentGroup.cockpit => garageGroupCockpit,
        ComponentGroup.drivetrain => garageGroupDrivetrain,
        ComponentGroup.brakes => garageGroupBrakes,
        ComponentGroup.power => garageGroupPower,
        ComponentGroup.other => garageGroupOther,
      };

  String compatVerdictShort(CompatVerdict v) => switch (v) {
        CompatVerdict.compatible => garageVerdictFits,
        CompatVerdict.conditional => garageVerdictCheck,
        CompatVerdict.incompatible => garageVerdictNoFit,
        CompatVerdict.insufficientData => garageVerdictUnclear,
      };

  String batteryPresetTitle(RideBatteryPreset p) => switch (p) {
        RideBatteryPreset.pocket => rideBatteryPocket,
        RideBatteryPreset.lenker => rideBatteryLenker,
        RideBatteryPreset.ultra => rideBatteryUltra,
      };

  String batteryPresetSubtitle(RideBatteryPreset p) => switch (p) {
        RideBatteryPreset.pocket => rideBatteryPocketSub,
        RideBatteryPreset.lenker => rideBatteryLenkerSub,
        RideBatteryPreset.ultra => rideBatteryUltraSub,
      };

  String batteryPresetSnack(RideBatteryPreset p) => switch (p) {
        RideBatteryPreset.pocket => rideBatteryPocketSnack,
        RideBatteryPreset.lenker => rideBatteryLenkerSnack,
        RideBatteryPreset.ultra => rideBatteryUltraSnack,
      };

  String connectivityChipLabelFor(ConnectivityChipState state) =>
      switch (state) {
        ConnectivityChipState.live => rideChipLive,
        ConnectivityChipState.routeOffline => rideChipRouteOffline,
        ConnectivityChipState.offlineMapOk => rideChipOfflineMapOk,
        ConnectivityChipState.mapsMissing => rideChipMapsMissing,
      };

  String compassCardinalFor(double headingDeg) {
    final i = ((normalizeHeadingDeg(headingDeg) + 22.5) / 45).floor() % 8;
    return [
      rideCardinalN,
      rideCardinalNE,
      rideCardinalE,
      rideCardinalSE,
      rideCardinalS,
      rideCardinalSW,
      rideCardinalW,
      rideCardinalNW,
    ][i];
  }

  String hudPeekLabelFor(String domainLabel) => switch (domainLabel) {
        'Puls' => rideHeart,
        'Akku' => rideBatteryChip,
        'Assist' => rideAssist,
        'Lean' => rideLean,
        _ => domainLabel,
      };

  String hudSpeedCaptionFor(String domainCaption) => switch (domainCaption) {
        'Rad' => rideWheelSpeed,
        'km/h' => rideKmh,
        'Speed' || 'Tempo' => rideSpeed,
        _ => domainCaption,
      };

  String navInstructionFor(String raw) => switch (raw.trim()) {
        'Losfahren' => goRide,
        'Ziel erreicht' => navCueArrive,
        'Leicht links' => navCueSlightLeft,
        'Leicht rechts' => navCueSlightRight,
        'Links abbiegen' => navCueTurnLeft,
        'Rechts abbiegen' => navCueTurnRight,
        'Scharf links' => navCueSharpLeft,
        'Scharf rechts' => navCueSharpRight,
        _ => raw,
      };

  String liveHintFor(String id, {int? n}) => switch (id) {
        'bracket-run' => liveHintBracketRun('${n ?? 0}'),
        'impact-streak' => liveHintImpactStreak,
        'stand-setup' => liveHintStandSetup,
        _ => id,
      };

  String maintIntervalLabel(String de) => switch (de) {
        'Gabel Lower-Leg Service' => maintForkLower,
        'Gabel Vollservice (Feder/Dämpfer)' => maintForkFull,
        'Dämpfer Air-Can Service' => maintShockAir,
        'Dämpfer Vollservice' => maintShockFull,
        'Kettenverschleiß prüfen' => maintChainWear,
        'Kassette prüfen (nach 2–3 Ketten)' => maintCassetteCheck,
        'Bremsbeläge vorne prüfen' => maintPadsFront,
        'Bremsbeläge hinten prüfen' => maintPadsRear,
        'Tubeless-Milch erneuern' => maintSealant,
        'Dropper Lower-Post Service' => maintDropper,
        _ => de,
      };

  String maintRemainingFor(String raw) {
    if (raw == 'Kein Intervall') return maintNoInterval;
    return raw.split(' · ').map(_maintRemainingPart).join(' · ');
  }

  String _maintRemainingPart(String part) {
    final t = part.trim();
    final m = RegExp(r'^(\d+)\s+Tage$').firstMatch(t);
    if (m != null) return maintDays(m.group(1)!);
    return t;
  }

  String compatTitleFor(CompatibilityResult r) => switch (r.ruleCode) {
        'RL-DRV-011' => compatTitleDrv011,
        'RL-FRM-004' => compatTitleFrm004,
        'RL-SUS-007' => compatTitleSus007,
        'RL-SUS-012' => compatTitleSus012,
        'RL-BRK-003' => compatTitleBrk003,
        'RL-BRK-008' => compatTitleBrk008,
        'RL-BRK-008F' => compatTitleBrk008f,
        'RL-WHL-005' => compatTitleWhl005,
        'RL-WHL-005F' => compatTitleWhl005f,
        'RL-WHL-009' => compatTitleWhl009,
        'RL-CKP-002' => compatTitleCkp002,
        'RL-SPT-006' => compatTitleSpt006,
        'RL-BB-003' => compatTitleBb003,
        'RL-BB-003F' => compatTitleBb003f,
        'RL-EBK-002' => compatTitleEbk002,
        'RL-FRM-004F' => compatTitleFrm004f,
        _ => r.title,
      };

  String compatConditionFor(CompatibilityResult r) {
    final de = r.conditionText;
    if (de == null || de.isEmpty) return '';
    if (r.ruleCode == 'RL-BRK-003') return compatConditionBrk003;
    return de;
  }

  String? compatWorkshopFor(String? hint) {
    if (hint == null || hint.isEmpty) return hint;
    if (hint.startsWith('Sicherheitsrelevante')) return compatWorkshopHint;
    return hint;
  }

  String compatHowTo(String attrKey) {
    final k = attrKey.contains('.') ? attrKey.split('.').last : attrKey;
    return switch (k) {
      'freehub_standard' => howToFreehub,
      'rear_spacing' => howToRearSpacing,
      'eye_to_eye_mm' => howToEyeToEye,
      'stroke_mm' => howToStroke,
      'mount_type' => howToMountType,
      'steerer_type' => howToSteerer,
      'brake_mount' => howToBrakeMount,
      'brake_mount_rear' => howToBrakeMountRear,
      'rotor_mount' => howToRotorMount,
      'tire_width_mm' => howToTireWidth,
      'internal_rim_width_mm' => howToRimWidth,
      'max_tire_width_mm' => howToMaxTire,
      'handlebar_clamp_mm' => howToBarClamp,
      'stem_clamp_mm' => howToStemClamp,
      'seatpost_diameter_mm' => howToSeatpostDia,
      'min_insertion_mm' => howToMinInsert,
      'max_seatpost_insertion_mm' => howToMaxInsert,
      'crank_axle' => howToCrankAxle,
      'bb_standard' => howToBbStandard,
      'motor_interface' => howToMotorInterface,
      'axle_front' => howToAxleFront,
      _ => compatDatasheet,
    };
  }

  String compatAttrLabel(String attrKey) {
    final k = attrKey.contains('.') ? attrKey.split('.').last : attrKey;
    return switch (k) {
      'freehub_standard' => attrFreehub,
      'rear_spacing' => attrRearSpacing,
      'eye_to_eye_mm' => attrEyeToEye,
      'stroke_mm' => attrStroke,
      'mount_type' => attrMountType,
      'shock_eye_to_eye_mm' => attrShockEyeToEye,
      'shock_stroke_mm' => attrShockStroke,
      'shock_mount_type' => attrShockMount,
      'steerer_type' => attrSteerer,
      'brake_mount' => attrBrakeMount,
      'brake_mount_rear' => attrBrakeMountRear,
      'rotor_mount' => attrRotorMount,
      'tire_width_mm' => attrTireWidth,
      'internal_rim_width_mm' => attrRimWidth,
      'max_tire_width_mm' => attrMaxTire,
      'handlebar_clamp_mm' => attrBarClamp,
      'stem_clamp_mm' => attrStemClamp,
      'seatpost_diameter_mm' => attrSeatpostDia,
      'min_insertion_mm' => attrMinInsert,
      'max_seatpost_insertion_mm' => attrMaxInsert,
      'crank_axle' => attrCrankAxle,
      'bb_standard' => attrBbStandard,
      'motor_interface' => attrMotorInterface,
      'axle_front' => attrAxleFront,
      _ => k,
    };
  }

  String compatExplain(CompatibilityResult r) {
    if (r.verdict == CompatVerdict.insufficientData) {
      return compatMissingFacts;
    }
    if (r.explainDe == 'Regel erfüllt.') return compatRuleOk;
    if (r.explainDe == 'Bedingt kompatibel' ||
        (r.conditionText != null && r.explainDe == r.conditionText)) {
      final c = compatConditionFor(r);
      return c.isEmpty ? compatConditional : c;
    }
    return _compatFail(r);
  }

  String _compatFail(CompatibilityResult r) {
    final a = r.valuesA;
    final b = r.valuesB;
    String va(String k) => a[k] ?? '?';
    String vb(String k) => b[k] ?? '?';
    return switch (r.ruleCode) {
      'RL-DRV-011' =>
        compatFailDrv011(va('freehub_standard'), vb('freehub_standard')),
      'RL-FRM-004' => compatFailFrm004(va('rear_spacing'), vb('rear_spacing')),
      'RL-SUS-007' => compatFailSus007(
          va('eye_to_eye_mm'),
          va('stroke_mm'),
          va('mount_type'),
        ),
      'RL-SUS-012' => compatFailSus012(va('steerer_type'), vb('steerer_type')),
      'RL-BRK-003' =>
        compatFailBrk003(va('brake_mount'), vb('brake_mount_rear')),
      'RL-BRK-008' => compatFailBrk008(va('rotor_mount'), vb('rotor_mount')),
      'RL-BRK-008F' => compatFailBrk008f(va('rotor_mount'), vb('rotor_mount')),
      'RL-WHL-005' =>
        compatFailWhl005(va('tire_width_mm'), vb('internal_rim_width_mm')),
      'RL-WHL-005F' =>
        compatFailWhl005f(va('tire_width_mm'), vb('internal_rim_width_mm')),
      'RL-WHL-009' =>
        compatFailWhl009(va('tire_width_mm'), vb('max_tire_width_mm')),
      'RL-CKP-002' =>
        compatFailCkp002(va('handlebar_clamp_mm'), vb('stem_clamp_mm')),
      'RL-SPT-006' => compatFailSpt006(
          va('seatpost_diameter_mm'),
          vb('seatpost_diameter_mm'),
        ),
      'RL-BB-003' => compatFailBb003(va('crank_axle'), vb('crank_axle')),
      'RL-BB-003F' => compatFailBb003f(va('bb_standard'), vb('bb_standard')),
      'RL-EBK-002' =>
        compatFailEbk002(vb('motor_interface'), va('motor_interface')),
      'RL-FRM-004F' => compatFailFrm004f(va('axle_front'), vb('axle_front')),
      _ => r.explainDe,
    };
  }

  String postRideFactLine(String de) {
    final bike = RegExp(r'^Bike: (.+)$').firstMatch(de);
    if (bike != null) return postRideFactBike(bike.group(1)!);
    final soc = RegExp(r'^SOC (.+)%$').firstMatch(de);
    if (soc != null) return postRideFactSoc(soc.group(1)!);
    final ride = RegExp(
      r'^([\d.]+) km · (\d+) hm · ([\d.]+) min$',
    ).firstMatch(de);
    if (ride != null) {
      return postRideFactRide(
        ride.group(1)!,
        ride.group(2)!,
        ride.group(3)!,
      );
    }
    final lean = RegExp(
      r'^Flow ([\d.]+) · Peak ([\d.]+) g · (\d+) Impacts · Lean ([\d.]+)°$',
    ).firstMatch(de);
    if (lean != null) {
      return postRideFactMetricsLean(
        lean.group(1)!,
        lean.group(2)!,
        lean.group(3)!,
        lean.group(4)!,
      );
    }
    final metrics = RegExp(
      r'^Flow ([\d.]+) · Peak ([\d.]+) g · (\d+) Impacts$',
    ).firstMatch(de);
    if (metrics != null) {
      return postRideFactMetrics(
        metrics.group(1)!,
        metrics.group(2)!,
        metrics.group(3)!,
      );
    }
    return de;
  }

  String postRideObservationText(PostRideObservation o) {
    final p = o.params;
    return switch (o.id) {
      'impacts' => postRideObsImpacts(p['count'] ?? '?', p['km'] ?? '?'),
      'smooth' => postRideObsSmooth(p['km'] ?? '?'),
      'flow-high' => postRideObsFlowHigh(p['flow'] ?? '?'),
      'flow-low' => postRideObsFlowLow(p['flow'] ?? '?'),
      'peak-g' => postRideObsPeakG(p['g'] ?? '?'),
      'fb-harsh' => postRideObsFbHarsh(
          p['front'] == 'too_firm' ? postRideFrontTooFirm : postRideFrontOk,
          p['bumps'] == 'harsh' ? postRideBumpsHarsh : '—',
        ),
      'fb-soft' => postRideObsFbSoft,
      _ => o.text,
    };
  }

  String postRideSuggestionTitle(SetupChangeSuggestion s) => switch (s.kind) {
        'rebound-slow' => postRideSugReboundSlowTitle,
        'rebound-fast' => postRideSugReboundFastTitle,
        'pressure' => postRideSugPressureTitle,
        _ => s.title,
      };

  String postRideSuggestionContent(SetupChangeSuggestion s) => switch (s.kind) {
        'rebound-slow' => postRideSugReboundSlowContent(
            s.params['current'] ?? '?',
            s.params['next'] ?? '?',
          ),
        'rebound-fast' => postRideSugReboundFastContent(
            s.params['current'] ?? '?',
            s.params['next'] ?? '?',
          ),
        'pressure' => postRideSugPressureContent,
        _ => s.content,
      };

  String postRideSuggestionEffect(SetupChangeSuggestion s) => switch (s.kind) {
        'rebound-slow' => postRideSugReboundSlowEffect,
        'rebound-fast' => postRideSugReboundFastEffect,
        'pressure' => postRideSugPressureEffect,
        _ => s.expectedEffect,
      };

  String postRideSuggestionLimits(SetupChangeSuggestion s) => switch (s.kind) {
        'rebound-slow' || 'rebound-fast' => postRideSugLimitsClicks,
        'pressure' => postRideSugLimitsPressure,
        _ => s.limits,
      };

  String postRideReasonLine(String de) {
    return switch (de) {
      'Feedback „kleine Schläge rau“' => postRideReasonHarshBumps,
      'Feedback „Front zu hart“' => postRideReasonFrontFirm,
      'Hohe Schlagbelastung an der Front' => postRideReasonFrontLoad,
      'Feedback „taucht ab“' => postRideReasonDive,
      'Feedback „Front zu weich“' => postRideReasonFrontSoft,
      'Front zu weich / Dive' => postRideReasonSoftDive,
      'Peak ≥ 5 g bei längerer Fahrt' => postRideReasonPeakLong,
      _ => _postRideReasonDynamic(de),
    };
  }

  String _postRideReasonDynamic(String de) {
    final impacts = RegExp(r'^(\d+) Impacts / ([\d.]+) km$').firstMatch(de);
    if (impacts != null) {
      return postRideReasonImpacts(impacts.group(1)!, impacts.group(2)!);
    }
    final rms = RegExp(r'^RMS ([\d.]+) g$').firstMatch(de);
    if (rms != null) return postRideReasonRms(rms.group(1)!);
    return de;
  }

  String postRideConfidenceLabel(String confidence) => switch (confidence) {
        'high' => postRideConfHigh,
        'medium' => postRideConfMedium,
        'low' => postRideConfLow,
        _ => confidence,
      };

  String postRideAssistSegmentLabel(String raw) {
    final t = raw.trim();
    final approach = RegExp(r'^Schätzung: (\w+) \(Anfahrt\)$').firstMatch(t);
    if (approach != null) return postRideAssistApproach(approach.group(1)!);
    final climb =
        RegExp(r'^Schätzung: (\w+) \(Steigung, (\d+) %\)$').firstMatch(t);
    if (climb != null) {
      return postRideAssistClimb(climb.group(1)!, climb.group(2)!);
    }
    final rest = RegExp(r'^Schätzung: (\w+) \(Rest\)$').firstMatch(t);
    if (rest != null) return postRideAssistRest(rest.group(1)!);
    return t;
  }

  String postRideAssistDisclaimerFor(String raw) {
    final t = raw.trim();
    if (t.startsWith('Schätzungen aus Leistungs')) {
      return postRideAssistDisclaimer;
    }
    return t;
  }

  String bleKindLabel(BikeBleKind kind) => switch (kind) {
        BikeBleKind.bosch => 'Bosch',
        BikeBleKind.shimano => 'Shimano',
        BikeBleKind.yamaha => 'Yamaha',
        BikeBleKind.csc => rideBikeSensor,
        BikeBleKind.power => bleKindPower,
        BikeBleKind.otherDrive => bleKindOtherDrive,
      };

  String bleConnectTipFor(BikeBleKind kind) => switch (kind) {
        BikeBleKind.bosch => bleTipBosch,
        BikeBleKind.shimano => bleTipShimano,
        BikeBleKind.yamaha => bleTipYamaha,
        BikeBleKind.otherDrive => bleTipOtherDrive,
        BikeBleKind.csc => bleTipCsc,
        BikeBleKind.power => bleTipPower,
      };

  String blePairLeadFor({required bool isEbike}) =>
      isEbike ? blePairLeadEbike : blePairLeadSensor;

  String bleScanName(BikeBleScanHit hit) {
    final n = hit.name.trim();
    return n.isEmpty ? bleKindLabel(hit.kind) : n;
  }

  List<({String brand, String line})> bleConnectNotesFor({
    required bool isEbike,
  }) {
    if (!isEbike) {
      return [(brand: bleNoteSensorBrand, line: bleNoteSensorLine)];
    }
    return [
      (brand: 'Bosch', line: bleNoteBoschLine),
      (brand: 'Shimano', line: bleNoteShimanoLine),
      (brand: 'Yamaha / TQ', line: bleNoteYamahaLine),
      (brand: 'Fazua', line: bleNoteFazuaLine),
      (brand: bleNoteOtherBrand, line: bleNoteOtherLine),
    ];
  }

  String bleDriveFailFor(BikeBleKind kind, {String? detail}) {
    final lead = switch (kind) {
      BikeBleKind.bosch => bleDriveFailBosch,
      BikeBleKind.shimano => bleDriveFailShimano,
      BikeBleKind.yamaha => bleDriveFailYamaha,
      _ => bleDriveFailGeneric,
    };
    if (detail == null || detail.trim().isEmpty) return lead;
    return '$lead ${bleStatusDetailFor(detail)}';
  }

  String watchHonestyLabelFor(WatchHonesty h) => switch (h) {
        WatchHonesty.hrBroadcast => watchHonestyHr,
        WatchHonesty.garminNeedsBroadcast => watchHonestyGarmin,
        WatchHonesty.appleUnsupported => watchHonestyApple,
        WatchHonesty.galaxyLimited => watchHonestyGalaxy,
        WatchHonesty.unknown => watchHonestyUnknown,
      };

  String watchConnectTipFor(WatchHonesty h) => switch (h) {
        WatchHonesty.hrBroadcast => watchTipHr,
        WatchHonesty.garminNeedsBroadcast => watchTipGarmin,
        WatchHonesty.appleUnsupported => watchTipApple,
        WatchHonesty.galaxyLimited => watchTipGalaxy,
        WatchHonesty.unknown => watchTipUnknown,
      };

  List<({String brand, String line})> watchConnectNotesFor() => [
        (brand: watchNotePolarBrand, line: watchNotePolarLine),
        (brand: 'Garmin', line: watchNoteGarminLine),
        (brand: 'Apple Watch', line: watchNoteAppleLine),
        (brand: 'Galaxy', line: watchNoteGalaxyLine),
      ];

  String watchScanName(WatchBleScanHit hit) {
    final n = hit.name.trim();
    return n.isEmpty ? watchHrSensorFallback : n;
  }

  String bleStatusDetailFor(String raw) {
    final t = raw.trim();
    final exact = switch (t) {
      'Bluetooth aus' => bleStatusBtOff,
      'Radsensor-Suche fehlgeschlagen' => bleStatusScanFailed,
      'Kein Radsensor gefunden' => bleStatusNoSensor,
      'Kein Rad, Antrieb oder Sensor in Reichweite' => bleStatusNoneInRange,
      'Antrieb gesehen — in der Werkstatt koppeln (Bosch/Shimano)' =>
        bleStatusDriveSeen,
      'Kein Radsensor in Reichweite' => bleStatusNoCscInRange,
      'Radsensor getrennt' => bleStatusSensorDisconnected,
      'Verbindung verloren — Display prüfen, Flow/E-TUBE schließen, in der Werkstatt erneut koppeln.' =>
        bleStatusReconnectLost,
      'Verbindung abgelehnt — andere Fitness-App schließen, Uhr nah halten.' =>
        bleGattWatchRejected,
      'Timeout — Uhr nah halten, Broadcast-Herzfrequenz prüfen.' =>
        bleGattWatchTimeout,
      'Uhr-Verbindung fehlgeschlagen' => bleGattWatchFailed,
      'Verbindung abgelehnt — Bosch Flow schließen, Display an, 10–20 cm.' =>
        bleGattRejectedBosch,
      'Verbindung abgelehnt — E-TUBE schließen, Display an, nah halten.' =>
        bleGattRejectedShimano,
      'Verbindung abgelehnt — Bosch Flow / Shimano E-TUBE schließen, Display an, nah halten.' =>
        bleGattRejectedGeneric,
      'Timeout — Display wecken, Flow zu, nah halten. Motorwerte nur mit CSC oder offiziellem LDI.' =>
        bleGattTimeoutBosch,
      'Timeout — E-TUBE zu, in 15 s nach Power/Taster tippen.' =>
        bleGattTimeoutShimano,
      'Timeout — Hersteller-App zu, Display an. Tempo über CSC-Sensor.' =>
        bleGattTimeoutDrive,
      'Timeout — Sensor wecken, näher rangehen.' => bleGattTimeoutSensor,
      'Verbindung fehlgeschlagen' => bleConnectFailed,
      'Display braucht Bluetooth-Kopplung für den Akku.' => bleStatusNeedBond,
      'System-Kopplung …' => bleStatusBonding,
      'Uhr in der Liste wählen' => watchStatusPickFromList,
      'Uhr-Suche fehlgeschlagen' => watchStatusScanFailed,
      'Uhr verbunden (Sim)' => watchStatusConnectedSim,
      'Uhr getrennt' => watchStatusDisconnected,
      'Uhr gefunden, aber ohne Standard-Puls-Service' => watchStatusNoHrService,
      'Uhr getrennt — Broadcast prüfen, in der Nähe erneut koppeln.' =>
        watchStatusReconnectLost,
      _ => null,
    };
    if (exact != null) return exact;

    final retry = RegExp(r'^Verbinde … Retry (\d+)/(\d+)$').firstMatch(t);
    if (retry != null) {
      return bleStatusRetry(retry.group(1)!, retry.group(2)!);
    }
    final attempt = RegExp(r'^Verbinde … Versuch (\d+)/(\d+)$').firstMatch(t);
    if (attempt != null) {
      return bleStatusAttempt(attempt.group(1)!, attempt.group(2)!);
    }
    final recon = RegExp(r'^Verbinde erneut … \((\d+)/(\d+)\)$').firstMatch(t);
    if (recon != null) {
      return bleStatusReconnect(recon.group(1)!, recon.group(2)!);
    }
    final wRecon =
        RegExp(r'^Uhr verbindet erneut … \((\d+)/(\d+)\)$').firstMatch(t);
    if (wRecon != null) {
      return watchStatusReconnect(wRecon.group(1)!, wRecon.group(2)!);
    }
    final driveNeedBond = RegExp(
      r'^(.+) · erkannt — Akku nach Bluetooth-Kopplung in der Werkstatt$',
    ).firstMatch(t);
    if (driveNeedBond != null) {
      return bleStatusDriveNeedBond(_bleWho(driveNeedBond.group(1)!));
    }
    final drive = RegExp(
      r'^(.+) · erkannt — Tempo über CSC, Akku nur mit Standard-GATT$',
    ).firstMatch(t);
    if (drive != null) {
      return bleStatusDriveNoLive(_bleWho(drive.group(1)!));
    }
    final connected = RegExp(r'^(.+) verbunden$').firstMatch(t);
    if (connected != null) {
      return bleConnectedNamed(_bleWho(connected.group(1)!));
    }
    if (t.contains(' · ')) {
      return t.split(' · ').map(_bleStatusToken).join(' · ');
    }
    return t;
  }

  String bikeCategoryShort(BikeCategory c) => switch (c) {
        BikeCategory.mtbTrail => bikeCatMtbTrail,
        BikeCategory.mtbAm => bikeCatMtb,
        BikeCategory.mtbEnduro => bikeCatEnduro,
        BikeCategory.dh => bikeCatDh,
        BikeCategory.gravel => bikeCatGravel,
        BikeCategory.road => bikeCatRoad,
        BikeCategory.urban => bikeCatUrban,
        BikeCategory.cargo => bikeCatCargo,
        BikeCategory.folding => bikeCatFolding,
        BikeCategory.kids => bikeCatKids,
        BikeCategory.emtb => bikeCatEmtb,
        BikeCategory.etrekking => bikeCatEtrekking,
        BikeCategory.hiking => bikeCatHiking,
      };

  String bikeCategoryLabel(Bike bike) {
    if (bike.hasElectricAssist) {
      return switch (bike.category) {
        BikeCategory.emtb ||
        BikeCategory.mtbTrail ||
        BikeCategory.mtbAm ||
        BikeCategory.mtbEnduro ||
        BikeCategory.dh =>
          bikeCatEmtb,
        BikeCategory.etrekking => bikeCatEtrekking,
        BikeCategory.gravel => bikeCatEgravel,
        BikeCategory.urban => bikeCatEcity,
        BikeCategory.cargo => bikeCatEcargo,
        BikeCategory.folding => bikeCatEfolding,
        BikeCategory.kids => bikeCatEkids,
        BikeCategory.road => bikeCatEroad,
        BikeCategory.hiking => bikeCatHiking,
      };
    }
    return bikeCategoryShort(bike.category);
  }

  String bikeCategoryBlurb(BikeCategory c) => switch (c) {
        BikeCategory.mtbTrail => bikeBlurbMtbTrail,
        BikeCategory.mtbAm => bikeBlurbMtb,
        BikeCategory.mtbEnduro => bikeBlurbEnduro,
        BikeCategory.dh => bikeBlurbDh,
        BikeCategory.gravel => bikeBlurbGravel,
        BikeCategory.road => bikeBlurbRoad,
        BikeCategory.urban => bikeBlurbUrban,
        BikeCategory.cargo => bikeBlurbCargo,
        BikeCategory.folding => bikeBlurbFolding,
        BikeCategory.kids => bikeBlurbKids,
        BikeCategory.emtb => bikeBlurbEmtb,
        BikeCategory.etrekking => bikeBlurbEtrekking,
        BikeCategory.hiking => bikeBlurbHiking,
      };

  String onboardingSportLabel(BikeCategory c) =>
      c == BikeCategory.mtbTrail ? onboardSportTrail : bikeCategoryShort(c);

  String onboardingSportBlurb(BikeCategory c) => c == BikeCategory.mtbTrail
      ? bikeBlurbMtbTrailFocus
      : bikeCategoryBlurb(c);

  String sportsSummaryLine({
    required BikeCategory? primary,
    required List<BikeCategory> sports,
  }) {
    if (primary == null && sports.isEmpty) return '';
    final haupt = primary ?? sports.first;
    final others = [
      for (final s in sports)
        if (s != haupt) bikeCategoryShort(s),
    ];
    final label = bikeCategoryShort(haupt);
    if (others.isEmpty) return sportsSummaryPrimary(label);
    return sportsSummaryPrimaryAlso(label, others.join(', '));
  }

  String hofResidentSportLabel(Bike bike, {bool hasMotor = false}) {
    if (hasMotor && !bike.hasElectricAssist) {
      return bikeCategoryLabel(bike.copyWith(isEbike: true));
    }
    return bikeCategoryLabel(bike);
  }

  /// Discover-Chip: Wege-/Tour-Familie. Enduro-Garage → MTB, kein Navi-Modus.
  String discoverChipLabel(RoutingProfile profile) =>
      switch (discoverChipFamilyId(profile)) {
        'mtb' => bikeCatMtb,
        'emtb' => bikeCatEmtb,
        'gravel' => bikeCatGravel,
        'road' => bikeCatRoad,
        'urban' => bikeCatUrban,
        'ebike' => bikeCatEtrekking,
        'hiking' => bikeCatHiking,
        _ => bikeCatMtb,
      };

  String bikeAssistModeLabel(BikeAssistMode mode) =>
      mode == BikeAssistMode.ebike ? garageEbikeBadge : garageMuscle;

  String bikeAssistSubtypeLabel(BikeCategory category, BikeAssistMode mode) {
    if (mode == BikeAssistMode.muscle) {
      return bikeCategoryShort(category);
    }
    return switch (category) {
      BikeCategory.emtb => bikeCatEmtb,
      BikeCategory.etrekking => bikeCatEtrekking,
      BikeCategory.gravel => bikeCatEgravel,
      BikeCategory.urban => bikeCatEcity,
      BikeCategory.cargo => bikeCatEcargo,
      BikeCategory.folding => bikeCatEfolding,
      BikeCategory.kids => bikeCatEkids,
      BikeCategory.road => bikeCatEroad,
      BikeCategory.mtbTrail => bikeCatEmtbTrail,
      BikeCategory.mtbAm => bikeCatEmtb,
      BikeCategory.mtbEnduro => bikeCatEenduro,
      BikeCategory.dh => bikeCatEdh,
      BikeCategory.hiking => bikeCatHiking,
    };
  }

  String garageLogActivityLabel(String raw) {
    final t = raw.trim();
    return switch (t) {
      'Kilometerstand aktualisiert' || 'odo_updated' => garageLogOdoUpdated,
      'Betriebsstunden aktualisiert' ||
      'hours_updated' =>
        garageLogHoursUpdated,
      'gpx_import' => garageLogGpxImport,
      'import_placeholder' => garageLogImportPlaceholder,
      'Druck gemerkt' => dieBoxPressureLogged,
      'Kette gemessen' || 'chain_measured' => dieBoxChainLogged,
      _ => t,
    };
  }

  String demoCityLabel(String id, [String? fallback]) => switch (id) {
        'wiesloch' => fallback ?? 'Wiesloch',
        'heidelberg' => fallback ?? 'Heidelberg',
        'mannheim' => fallback ?? 'Mannheim',
        'berlin' => fallback ?? 'Berlin',
        'hamburg' => fallback ?? 'Hamburg',
        'muenchen' => demoCityMuenchen,
        'koeln' => demoCityKoeln,
        'frankfurt' => fallback ?? 'Frankfurt',
        'stuttgart' => fallback ?? 'Stuttgart',
        'zuerich' => demoCityZuerich,
        'wien' => demoCityWien,
        'innsbruck' => fallback ?? 'Innsbruck',
        'konstanz' => demoCityKonstanz,
        'paris' => demoCityParis,
        'lyon' => fallback ?? 'Lyon',
        'strasbourg' => demoCityStrasbourg,
        'nice' => demoCityNice,
        'annecy' => fallback ?? 'Annecy',
        _ => fallback ?? id,
      };

  String overlayRegionNameFor(String id, [String? fallback]) {
    return switch (id) {
      'rhein-neckar' => overlayRheinNeckar,
      'schwarzwald-nord' => overlaySchwarzwaldNord,
      'bodensee' => overlayBodensee,
      'stuttgart' => overlayStuttgart,
      'muenchen' => overlayMuenchen,
      'nuernberg' => overlayNuernberg,
      'frankfurt-rhein-main' => overlayFrankfurtRheinMain,
      'koeln-rhein' => overlayKoelnRhein,
      'hamburg' => overlayHamburg,
      'berlin' => overlayBerlin,
      'dresden-elbland' => overlayDresdenElbland,
      'wien' => overlayWien,
      'salzburg' => overlaySalzburg,
      'innsbruck' => overlayInnsbruck,
      'zuerich' => overlayZuerich,
      'bern' => overlayBern,
      'basel' => overlayBasel,
      'ruhrgebiet' => overlayRuhrgebiet,
      'duesseldorf' => overlayDuesseldorf,
      'hannover' => overlayHannover,
      'leipzig' => overlayLeipzig,
      'freiburg' => overlayFreiburg,
      'karlsruhe' => overlayKarlsruhe,
      'augsburg' => overlayAugsburg,
      'kiel' => overlayKiel,
      'rostock' => overlayRostock,
      'kassel' => overlayKassel,
      'trier-mosel' => overlayTrierMosel,
      'pfalz' => overlayPfalz,
      'sauerland' => overlaySauerland,
      'eifel-trails' => overlayEifelTrails,
      'harz' => overlayHarz,
      'thueringer-wald' => overlayThueringerWald,
      'bayerischer-wald' => overlayBayerischerWald,
      'allgaeu' => overlayAllgaeu,
      'chiemgau' => overlayChiemgau,
      'saarbruecken' => overlaySaarbruecken,
      'muenster' => overlayMuenster,
      'aachen' => overlayAachen,
      'luebeck' => overlayLuebeck,
      'bremen' => overlayBremen,
      'magdeburg' => overlayMagdeburg,
      'erfurt' => overlayErfurt,
      'koblenz' => overlayKoblenz,
      'graz' => overlayGraz,
      'linz' => overlayLinz,
      'klagenfurt' => overlayKlagenfurt,
      'villach' => overlayVillach,
      'bregenz' => overlayBregenz,
      'kitzbuehel' => overlayKitzbuehel,
      'genf' => overlayGenf,
      'lausanne' => overlayLausanne,
      'luzern' => overlayLuzern,
      'st-gallen' => overlayStGallen,
      'lugano' => overlayLugano,
      'interlaken' => overlayInterlaken,
      'chur' => overlayChur,
      'zermatt' => overlayZermatt,
      'st-moritz' => overlayStMoritz,
      'davos' => overlayDavos,
      'strasbourg' => overlayStrasbourg,
      'alsace-vins' => overlayAlsaceVins,
      'vosges' => overlayVosges,
      'nancy-moselle' => overlayNancyMoselle,
      'jura-fr' => overlayJuraFr,
      'annecy' => overlayAnnecy,
      'morzine' => overlayMorzine,
      'lyon' => overlayLyon,
      'grenoble' => overlayGrenoble,
      'dijon' => overlayDijon,
      'chambery' => overlayChambery,
      'paris' => overlayParis,
      'lille' => overlayLille,
      'nice' => overlayNice,
      'marseille' => overlayMarseille,
      'bordeaux' => overlayBordeaux,
      'toulouse' => overlayToulouse,
      'nantes' => overlayNantes,
      _ => fallback ?? id,
    };
  }

  String seasonLabelFor(String? raw) {
    final s = raw?.trim();
    if (s == null || s.isEmpty) return '';
    return switch (s.toLowerCase()) {
      'year_round' || 'ganzjaehrig' || 'ganzjährig' => seasonYearRound,
      'spring_summer' ||
      'fruehling_sommer' ||
      'frühling–sommer' ||
      'frühling-sommer' =>
        seasonSpringSummer,
      'autumn' || 'herbst' => seasonAutumn,
      'winter' => seasonWinter,
      _ => s,
    };
  }

  String sportTagLabel(String? raw) {
    final t = raw?.trim();
    if (t == null || t.isEmpty) return '';
    return switch (t.toLowerCase()) {
      'road' || 'rennrad' => bikeCatRoad,
      'mtb' => bikeCatMtb,
      'gravel' => bikeCatGravel,
      'city' || 'urban' => bikeCatUrban,
      'ebike' || 'e-bike' || 'e-mtb' || 'emtb' => sportTagEbike,
      'touring' => sportTagTouring,
      'etrekking' || 'e-trekking' => bikeCatEtrekking,
      'hiking' || 'zu fuß' || 'zu fuss' => bikeCatHiking,
      'enduro' => bikeCatEnduro,
      'downhill' || 'dh' => bikeCatDh,
      'trail' => onboardSportTrail,
      _ => t,
    };
  }

  String surfaceMixLine({
    Map<String, dynamic>? mix,
    String? freeText,
  }) {
    final text = freeText?.trim();
    if (text != null && text.isNotEmpty) return text;
    if (mix == null || mix.isEmpty) return '';
    final parts = <String>[];
    for (final e in mix.entries) {
      final n = e.value is num ? (e.value as num).round() : null;
      if (n == null || n <= 0) continue;
      final label = switch (e.key) {
        'asphalt' => filterSurfaceAsphalt,
        'gravel' => filterSurfaceGravel,
        'trail' => filterSurfaceTrail,
        _ => e.key,
      };
      parts.add('$label $n%');
    }
    return parts.join(' · ');
  }

  String offlinePacksReadyLabel(int ready) =>
      ready == 1 ? offlinePacksReadyOne : offlinePacksReadyCount(ready);

  String offlinePackSubtitleFor(
    OfflinePackRow r, {
    required bool active,
    required bool installed,
  }) {
    if (active) return offlineSubActive;
    if (installed) return offlineSubInstalled;
    if (!r.isReady) {
      if (r.id == kBundledOfflineGraphRegionId) return offlineSubDemoGraph;
      return offlineSubNotBuilt;
    }
    final size = formatPackBytes(r.bytes);
    return size.isEmpty ? offlineSubLoad : offlineSubLoadSized(size);
  }

  String extractedGraphErrorFor(ExtractedGraphCheck check, String name) =>
      switch (check) {
        ExtractedGraphCheck.ok => '',
        ExtractedGraphCheck.missing => offlineGraphMissing(name),
        ExtractedGraphCheck.shaMismatch => offlineGraphSha(name),
        ExtractedGraphCheck.bundledMislabel => offlineGraphDemoMismatch(name),
      };

  String honestOfflineEngineCopyFor({
    required String valhallaStatus,
    String? engineHint,
  }) {
    final tiles = engineHint == 'valhalla' ||
        valhallaStatus.toLowerCase().contains('valhalla-tiles');
    if (tiles) {
      return offlineEngineStatusLineFor(
        valhallaStatus: valhallaStatus,
        engineHint: engineHint,
      );
    }
    final linked = valhallaStatus.contains('Valhalla-Feature verfügbar') ||
        valhallaStatus.contains('libvalhalla gelinkt') ||
        valhallaStatus.contains('valhalla_linked');
    if (linked) return offlineEngineLinkedNoTiles;
    return offlineEngineTilesNotBuilt;
  }

  String offlineEngineStatusLineFor({
    required String valhallaStatus,
    String? engineHint,
  }) {
    final mapped = valhallaStatusFor(valhallaStatus);
    final h = engineHint?.trim();
    if (h == null || h.isEmpty) return mapped;
    if (valhallaStatus.contains(h) || mapped.contains(h)) return mapped;
    return '$mapped · $h';
  }

  String valhallaStatusFor(String raw) {
    final t = raw.trim();
    return switch (t) {
      'keine Tiles' => offlineNoTiles,
      'FFI fehlt — graph-only / Valhalla-Flag nicht gelinkt' =>
        offlineFfiMissing,
      'Valhalla-Tiles · libvalhalla gelinkt' => offlineValhallaTilesLinked,
      _ => _valhallaStatusRest(t),
    };
  }

  String _valhallaStatusRest(String t) {
    final unlinked =
        RegExp(r'^Valhalla-Tiles · UNLINKED \(Code (.+)\)$').firstMatch(t);
    if (unlinked != null) {
      return offlineValhallaTilesUnlinked(unlinked.group(1)!);
    }
    final feat = RegExp(r'^(.+) · Valhalla-Feature verfügbar$').firstMatch(t);
    if (feat != null) {
      return '${feat.group(1)} · $offlineValhallaFeature';
    }
    final notLinked = RegExp(r'^(.+) · Valhalla nicht gelinkt$').firstMatch(t);
    if (notLinked != null) {
      return '${notLinked.group(1)} · $offlineValhallaNotLinked';
    }
    if (t.contains(' · ')) {
      return t.split(' · ').map(_offlineStatusToken).join(' · ');
    }
    return t;
  }

  String _offlineStatusToken(String tok) => switch (tok.trim()) {
        'keine Tiles' => offlineNoTiles,
        'Valhalla-Feature verfügbar' => offlineValhallaFeature,
        'Valhalla nicht gelinkt' => offlineValhallaNotLinked,
        _ => tok.trim(),
      };

  String offlineErrorDetail(String raw) {
    var t = raw.trim();
    if (t.startsWith('Exception: ')) t = t.substring('Exception: '.length);
    final sha = RegExp(
      r'^SHA-256 stimmt mit keinem Download überein \(erwartet (.+)\)$',
    ).firstMatch(t);
    if (sha != null) return offlineShaMismatch(sha.group(1)!);
    final folder = RegExp(
      r'^Ordner (.+) enthält keinen gültigen Graph für diese Region$',
    ).firstMatch(t);
    if (folder != null) return offlineInvalidGraphFolder(folder.group(1)!);
    final remote = RegExp(
      r'^Kein Remote-Pack für (.+)\. Catalog-Stubs aktivieren keinen fremden Demo-Graph\.$',
    ).firstMatch(t);
    if (remote != null) {
      return offlineNoRemotePack(
        overlayRegionNameFor(remote.group(1)!, remote.group(1)),
      );
    }
    // Name in DE error may be the region display name, not the id.
    final missing = RegExp(r'^Kein Graph in (.+)$').firstMatch(t);
    if (missing != null) return offlineGraphMissing(missing.group(1)!);
    final gsha = RegExp(r'^Graph-SHA von (.+) stimmt nicht$').firstMatch(t);
    if (gsha != null) return offlineGraphSha(gsha.group(1)!);
    final demo = RegExp(
      r'^Demo-Graph Schwarzwald passt nicht zu (.+)$',
    ).firstMatch(t);
    if (demo != null) return offlineGraphDemoMismatch(demo.group(1)!);
    return switch (t) {
      'Download leer' => offlineDownloadEmpty,
      'Kein Graph nach Extract' => offlineNoGraphAfterExtract,
      _ => t,
    };
  }

  String naeheLocationLabel({
    required bool hasOrigin,
    String? raw,
  }) {
    final t = raw?.trim() ?? '';
    if (hasOrigin) {
      if (t.isEmpty || t == '~60 Min um dich') return naeheAroundYou;
      return t;
    }
    if (t.isEmpty || t == '~60 Min in deiner Region') {
      return naeheInYourRegion;
    }
    return t;
  }

  String _bleWho(String who) => switch (who.trim()) {
        'Sensor' => bleWordSensor,
        'Uhr' => bleWordWatch,
        'Radsensor' => rideBikeSensor,
        'E-Antrieb' => bleKindOtherDrive,
        'Powermeter' => bleKindPower,
        _ => who.trim(),
      };

  String _bleStatusToken(String tok) {
    final t = tok.trim();
    final batt = RegExp(r'^Uhr-Akku (\d+) %$').firstMatch(t);
    if (batt != null) return watchStatusBattery(batt.group(1)!);
    return switch (t) {
      'Akku' => rideBatteryChip,
      'Puls' => rideHeart,
      'Sensor' => bleWordSensor,
      'Uhr' => bleWordWatch,
      'Radsensor' => rideBikeSensor,
      'E-Antrieb' => bleKindOtherDrive,
      'Powermeter' => bleKindPower,
      _ => t,
    };
  }
}
