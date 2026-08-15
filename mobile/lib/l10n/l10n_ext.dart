import '../domain/bike.dart';
import '../domain/routing/tour_filters.dart';
import '../domain/routing/trail_difficulty.dart';
import '../domain/sport/discipline_ux.dart';
import 'app_localizations.dart';

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
        TrailDifficulty.s3plus => trailDiffVeryHard,
        TrailDifficulty.open => trailDiffUnrated,
      };

  String trailDifficultyTech(TrailDifficulty d) => switch (d) {
        TrailDifficulty.s0 => 'S0',
        TrailDifficulty.s1 => 'S1',
        TrailDifficulty.s2 => 'S2',
        TrailDifficulty.s3plus => 'S3+',
        TrailDifficulty.open => trailDiffOpen,
      };

  String trailDifficultyFull(TrailDifficulty d) => d == TrailDifficulty.open
      ? trailDifficultyFriendly(d)
      : '${trailDifficultyFriendly(d)} (${trailDifficultyTech(d)})';
}
