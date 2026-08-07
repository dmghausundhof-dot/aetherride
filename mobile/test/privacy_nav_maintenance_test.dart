import 'package:flutter_test/flutter_test.dart';

import 'package:aetherride_mobile/domain/bike.dart';
import 'package:aetherride_mobile/domain/component.dart';
import 'package:aetherride_mobile/domain/maintenance/intervals.dart';
import 'package:aetherride_mobile/domain/privacy/consents.dart';
import 'package:aetherride_mobile/domain/ride.dart';
import 'package:aetherride_mobile/domain/routing/nav_cues.dart';
import 'package:aetherride_mobile/data/export/gpx.dart';
import 'package:aetherride_mobile/data/export/json_export.dart';

void main() {
  test('consent purpose api ids match web', () {
    expect(ConsentPurpose.rawDataUpload.apiId, 'raw_data_upload');
    expect(ConsentPurpose.heatmapContribution.apiId, 'heatmap_contribution');
    expect(consentLabels.length, ConsentPurpose.values.length);
  });

  test('listDueMaintenance flags overdue chain', () {
    const bike = Bike(
      id: 'b1',
      name: 'T',
      category: BikeCategory.mtbAm,
      hours: 60,
    );
    final comps = [
      BikeComponent(
        id: 'c1',
        bikeId: 'b1',
        slot: ComponentSlot.chain,
        odometerKm: 1200,
        installedAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
      BikeComponent(
        id: 'c2',
        bikeId: 'b1',
        slot: ComponentSlot.fork,
        odometerKm: 100,
        installedAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
    ];
    final due = listDueMaintenance(bike: bike, components: comps);
    expect(due.any((a) => a.slot == ComponentSlot.chain), isTrue);
    expect(due.any((a) => a.slot == ComponentSlot.fork), isTrue);
  });

  test('buildNavCues and nextCue from geometry', () {
    // Gentle turn after ~200m of eastbound then northbound travel
    final geometry = <List<double>>[];
    for (var i = 0; i < 20; i++) {
      geometry.add([12.0 + i * 0.0003, 47.4]);
    }
    for (var i = 1; i <= 20; i++) {
      geometry.add([12.0 + 19 * 0.0003, 47.4 + i * 0.0003]);
    }
    final cues = buildNavCues(geometry);
    expect(cues, isNotEmpty);
    expect(cues.last.instruction, 'Ziel erreicht');
    final nxt = nextCue(cues, 0);
    expect(nxt, isNotNull);
    expect(cueBannerText(nxt!.cue, nxt.remainingM), contains('In'));
  });

  test('rideToGpx and fullJsonExport produce content', () {
    final ride = RideRecord(
      id: 'ride-abcdef01',
      bikeId: 'b1',
      startedAt: DateTime.utc(2026, 4, 1, 10),
      endedAt: DateTime.utc(2026, 4, 1, 11),
      distanceKm: 12.5,
      movingTimeSec: 3600,
      elevationM: 400,
      track: const [
        {'lat': 47.45, 'lng': 12.15, 'elev': 800, 'time': 0},
        {'lat': 47.46, 'lng': 12.16, 'elev': 850, 'time': 60},
      ],
    );
    final gpx = rideToGpx(ride, bikeName: 'Demo');
    expect(gpx, contains('<gpx'));
    expect(gpx, contains('47.45'));
    final json = fullJsonExport(
      bikes: const [
        Bike(id: 'b1', name: 'Demo', category: BikeCategory.emtb),
      ],
      rides: [ride],
    );
    expect(json, contains('aetherride-portable-v1'));
    expect(json, contains('ride-abcdef01'));
  });
}
