import 'package:aetherride_mobile/data/routing/bike_overlay.dart';
import 'package:aetherride_mobile/data/routing/osm_trail_network_client.dart';
import 'package:aetherride_mobile/data/routing/sgrade_live.dart';
import 'package:aetherride_mobile/domain/routing/bike_overlay_class.dart';
import 'package:aetherride_mobile/domain/routing/trail_difficulty.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('overlay feature shares osm-way identity and shows S3', () {
    final trail = overlayFeatureToTrail({
      'properties': {
        'osm_id': 'way/4242',
        'name': 'Flow Line',
        'mtb_scale': 'S3',
        'highway': 'path',
      },
      'geometry': {
        'type': 'LineString',
        'coordinates': [
          [8.4, 48.6],
          [8.41, 48.61],
        ],
      },
    });
    expect(trail, isNotNull);
    expect(trail!.id, 'osm-way-4242');
    expect(trail.osmWayId, '4242');
      expect(trail.difficulty, TrailDifficulty.s3);
      expect(trailDifficultyLabel(trail.difficulty), 'S3');
    expect(trail.hasOsmName, isTrue);
    expect(trail.url, contains('/way/4242'));
  });

  test('sac_scale on overlay props is not mapped to S-scale', () {
    final trail = overlayFeatureToTrail({
      'properties': {
        'osm_id': '7',
        'highway': 'path',
        'sac_scale': 'mountain_hiking',
      },
      'geometry': {
        'type': 'LineString',
        'coordinates': [
          [8.4, 48.6],
          [8.41, 48.61],
        ],
      },
    });
    expect(trail, isNotNull);
    expect(trail!.difficulty, TrailDifficulty.open);
    expect(parseOsmWayId('osm-way-99'), '99');
    expect(parseOsmWayId(''), isNull);
  });

  test('map tap queries live S-grade and OSM path layers, not only packs', () {
    expect(kBikeOverlayQueryLayerIds, contains(kOsmSGradeLayerId));
    expect(kBikeOverlayQueryLayerIds, contains(kOsmLivePathLayerId));
  });

  test('live streets follow Wege, paths follow Trails', () {
    expect(kOsmLiveLayerClass[kOsmLiveStreetLayerId], BikeOverlayClass.urban);
    expect(kOsmLiveLayerClass[kOsmLiveCyclewayLayerId], BikeOverlayClass.road);
    expect(kOsmLiveLayerClass[kOsmLivePathLayerId], BikeOverlayClass.mtbUnrated);
    expect(kOsmLiveLayerClass[kOsmLiveTrackLayerId], BikeOverlayClass.gravel);
  });

  test('farm tracks hide only when hideFarmTracks is set', () {
    expect(
      osmLiveTrackLayerVisible(classVisible: true, hideFarmTracks: true),
      isFalse,
    );
    expect(
      osmLiveTrackLayerVisible(classVisible: true, hideFarmTracks: false),
      isTrue,
    );
    expect(
      osmLiveTrackLayerVisible(classVisible: false, hideFarmTracks: true),
      isFalse,
    );
  });
}
