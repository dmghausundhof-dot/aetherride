import 'package:aetherride_mobile/data/routing/coverage_label.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const city = [8.2, 48.9, 8.6, 49.2];
  const envelope = [8.0, 47.4, 10.6, 49.8];

  test('city pack name shows at browse zoom, hides in street view', () {
    expect(
      coverageNameVisibleAtZoom(zoom: 8, bbox: city, packId: 'karlsruhe'),
      isTrue,
    );
    expect(
      coverageNameVisibleAtZoom(zoom: 10.5, bbox: city, packId: 'karlsruhe'),
      isTrue,
    );
    expect(
      coverageNameVisibleAtZoom(zoom: 12, bbox: city, packId: 'karlsruhe'),
      isFalse,
    );
    expect(
      coverageNameVisibleAtZoom(zoom: 5.5, bbox: city, packId: 'karlsruhe'),
      isFalse,
    );
    expect(
      coverageOverlayVisible(zoom: 8, bbox: city, packId: 'karlsruhe'),
      isTrue,
    );
    expect(
      coverageOverlayVisible(zoom: 12, bbox: city, packId: 'karlsruhe'),
      isFalse,
    );
  });

  test('suggested wash is sage, not chrome', () {
    final active = coverageWashPaint(
      kind: CoverageWashKind.active,
      dimmed: false,
    );
    final suggested = coverageWashPaint(
      kind: CoverageWashKind.suggested,
      dimmed: false,
    );
    expect(active.fillColor, '#FF6A00');
    expect(suggested.fillColor, '#7A8B73');
    expect(suggested.fillColor, isNot(active.fillColor));
    expect(coverageWashDashed(CoverageWashKind.suggested), isTrue);
    expect(coverageWashDashed(CoverageWashKind.active), isFalse);
    final dim = coverageWashPaint(
      kind: CoverageWashKind.suggested,
      dimmed: true,
    );
    expect(dim.fillOpacity, lessThan(suggested.fillOpacity));
    final emphSug = coverageWashPaint(
      kind: CoverageWashKind.suggested,
      dimmed: true,
      emphasized: true,
    );
    final emphActive = coverageWashPaint(
      kind: CoverageWashKind.active,
      dimmed: false,
      emphasized: true,
    );
    expect(emphSug.fillOpacity, greaterThan(suggested.fillOpacity));
    expect(emphSug.fillOpacity, greaterThan(dim.fillOpacity));
    expect(emphActive.fillOpacity, greaterThan(active.fillOpacity));
    expect(active.cornerWidth, greaterThan(active.lineWidth));
    expect(suggested.cornerWidth, greaterThan(suggested.lineWidth));
    expect(emphSug.cornerWidth, greaterThan(emphSug.lineWidth));
    expect(kCoverageOutlineFilter, ['==', 'role', 'outline']);
    expect(kCoverageCornersFilter, ['==', 'role', 'corners']);
  });

  test('chip caption keeps short names and first token of long ones', () {
    expect(coverageChipCaption('Karlsruhe'), 'Karlsruhe');
    expect(coverageChipCaption('Schwarzwald Süd'), 'Schwarzwald');
    expect(coverageChipCaption('Rhein-Neckar'), 'Rhein-Neckar');
    expect(coverageGlanceName('Rhein-Neckar / Heidelberg'), 'Rhein-Neckar');
    expect(
      coverageChipCaption('Rhein-Neckar / Heidelberg'),
      'Rhein-Neckar',
    );
    expect(coverageChipCaption(''), '');
    expect(coverageChipCaption('Baden-Württemberg'), 'Baden-Württem…');
  });

  test('suggested coverage geojson is a closed polygon plus line', () {
    final empty = coverageBboxFeatureCollection(null);
    expect(empty['features'], isEmpty);
    final fc = coverageBboxFeatureCollection(city);
    final features = fc['features'] as List;
    expect(features, hasLength(6));
    final poly = features[0]['geometry'] as Map;
    final line = features[1]['geometry'] as Map;
    expect(poly['type'], 'Polygon');
    expect(line['type'], 'LineString');
    final ring = (poly['coordinates'] as List).first as List;
    expect(ring.first, ring.last);
    expect(ring, hasLength(9));
    expect(kCoverageSuggestedDasharray, [2.4, 1.8]);
    expect(offlinePackCoverageCorners(city), hasLength(4));
    expect(offlinePackCoverageCorners(city).first, hasLength(3));
  });

  test('envelope never paints a country wash', () {
    expect(
      coverageOverlayVisible(
        zoom: 7.5,
        bbox: envelope,
        packId: 'de-baden-wuerttemberg',
      ),
      isFalse,
    );
    expect(
      coverageNameVisibleAtZoom(
        zoom: 7.5,
        bbox: envelope,
        packId: 'de-baden-wuerttemberg',
      ),
      isFalse,
    );
  });

  test('active label sits on the north rim, not the centroid', () {
    final p = coverageLabelLngLat(bbox: city, kind: CoverageLabelKind.active);
    expect(p.lng, closeTo(8.4, 1e-9));
    expect(p.lat, closeTo(48.9 + (49.2 - 48.9) * 0.88, 1e-9));
    expect(p.lat, greaterThan((48.9 + 49.2) / 2));
  });

  test('suggested label shifts east of the active name', () {
    final a = coverageLabelLngLat(bbox: city, kind: CoverageLabelKind.active);
    final s = coverageLabelLngLat(
      bbox: city,
      kind: CoverageLabelKind.suggested,
    );
    expect(s.lng, greaterThan(a.lng));
  });

  test('label slides along the rim when a pin sits on it', () {
    final rest = coverageLabelLngLat(
      bbox: city,
      kind: CoverageLabelKind.active,
    );
    final nudged = coverageLabelLngLat(
      bbox: city,
      kind: CoverageLabelKind.active,
      avoid: [(lng: rest.lng, lat: rest.lat)],
    );
    expect(nudged.lng, lessThan(rest.lng));
    expect(nudged.lat, rest.lat);
  });

  test('zoom band changes when the name would appear or vanish', () {
    expect(coverageNameZoomBand(5), 0);
    expect(coverageNameZoomBand(7), 1);
    expect(coverageNameZoomBand(8.7), 2);
    expect(coverageNameZoomBand(10), 3);
    expect(coverageNameZoomBand(12), 4);
  });

  test('bbox contains, point-in, rider outside, suggested occludes', () {
    const inner = [8.3, 49.0, 8.5, 49.1];
    expect(coverageBboxContains(city, inner), isTrue);
    expect(coverageBboxContains(inner, city), isFalse);
    expect(coverageBboxContains(city, city), isTrue);
    expect(
      coveragePointInBbox(lng: 8.4, lat: 49.05, bbox: city),
      isTrue,
    );
    expect(
      coveragePointInBbox(lng: 8.0, lat: 49.05, bbox: city),
      isFalse,
    );
    expect(
      coverageRiderOutside(
        lng: 8.4,
        lat: 49.05,
        bbox: city,
        routingReady: true,
      ),
      isFalse,
    );
    expect(
      coverageRiderOutside(
        lng: 9.2,
        lat: 49.5,
        bbox: city,
        routingReady: true,
      ),
      isTrue,
    );
    expect(
      coverageRiderOutside(
        lng: 9.2,
        lat: 49.5,
        bbox: city,
        routingReady: false,
      ),
      isFalse,
    );
    expect(
      coverageSuggestedOccludesActive(active: inner, suggested: city),
      isTrue,
    );
    expect(
      coverageSuggestedOccludesActive(active: city, suggested: inner),
      isFalse,
    );
    expect(
      coverageSuggestedOccludesActive(active: city, suggested: city),
      isTrue,
    );
  });

  test('coverage seats under trails, tour lines, and pins', () {
    expect(
      coverageSeatBelowLayerId(
          ['hillshade', 'ar-offline-coverage-active-fill']),
      isNull,
    );
    expect(
      coverageSeatBelowLayerId(['hillshade', 'bike-overlay-mtb', 'flowline-x']),
      'bike-overlay-mtb',
    );
    expect(
      coverageSeatBelowLayerId(['osm-live-path']),
      'osm-live-path',
    );
    expect(
      coverageSeatBelowLayerId(['flowline-plan-paved-line']),
      'flowline-plan-paved-line',
    );
    expect(
      coverageSeatBelowLayerId(['flowline-plan-pack-out-line']),
      'flowline-plan-pack-out-line',
    );
    expect(
      coverageSeatBelowLayerId(['abcd1234_0']),
      'abcd1234_0',
    );
  });

  test('plan line splits at the padded pack edge', () {
    expect(
      coverageSplitLineByBbox(
        lineLngLat: const [
          [8.3, 49.0],
        ],
        bbox: city,
        routingReady: true,
      ),
      isEmpty,
    );
    final idle = coverageSplitLineByBbox(
      lineLngLat: const [
        [8.3, 49.0],
        [8.4, 49.05],
      ],
      bbox: city,
      routingReady: false,
    );
    expect(idle, hasLength(1));
    expect(idle.single.outside, isFalse);

    final inside = coverageSplitLineByBbox(
      lineLngLat: const [
        [8.3, 49.0],
        [8.4, 49.05],
      ],
      bbox: city,
      routingReady: true,
    );
    expect(inside, hasLength(1));
    expect(inside.single.outside, isFalse);
    expect(inside.single.coords, hasLength(2));

    final outside = coverageSplitLineByBbox(
      lineLngLat: const [
        [8.0, 49.0],
        [8.05, 49.0],
      ],
      bbox: city,
      routingReady: true,
    );
    expect(outside, hasLength(1));
    expect(outside.single.outside, isTrue);

    final mixed = coverageSplitLineByBbox(
      lineLngLat: const [
        [8.0, 49.0],
        [8.4, 49.0],
      ],
      bbox: city,
      routingReady: true,
    );
    expect(mixed, hasLength(2));
    expect(mixed.first.outside, isTrue);
    expect(mixed.last.outside, isFalse);
    expect(mixed.first.coords.last[0], closeTo(8.19, 1e-9));
    expect(mixed.last.coords.first[0], closeTo(8.19, 1e-9));

    final through = coverageSplitLineByBbox(
      lineLngLat: const [
        [8.0, 49.0],
        [8.8, 49.0],
      ],
      bbox: city,
      routingReady: true,
    );
    expect(through, hasLength(3));
    expect(through[0].outside, isTrue);
    expect(through[1].outside, isFalse);
    expect(through[2].outside, isTrue);
    expect(
      coverageLinePartsInside(
        lineLngLat: const [
          [8.0, 49.0],
          [8.8, 49.0],
        ],
        bbox: city,
        routingReady: true,
      ),
      hasLength(1),
    );
  });
}
