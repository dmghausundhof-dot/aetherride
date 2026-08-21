import 'package:aetherride_mobile/domain/bike.dart';
import 'package:aetherride_mobile/domain/routing/tour_match.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AM scores flow trails above gravel and S3+', () {
    final flow = tourMatchScore(
      bike: BikeCategory.mtbAm,
      categories: const [BikeCategory.mtbAm, BikeCategory.mtbTrail],
      surface: 'trail/root',
      mtbScale: 'S1',
      isLoop: true,
    );
    final gravel = tourMatchScore(
      bike: BikeCategory.mtbAm,
      categories: const [BikeCategory.gravel],
      surface: 'gravel/compacted',
      mtbScale: '',
    );
    final hard = tourMatchScore(
      bike: BikeCategory.mtbAm,
      categories: const [BikeCategory.mtbEnduro],
      surface: 'trail/root',
      mtbScale: 'S3+',
    );
    expect(flow, greaterThan(gravel));
    expect(flow, greaterThan(hard));
    expect(flow, inInclusiveRange(70, 99));
  });

  test('gravel bike loves compacted, not rooty S2+', () {
    final g = tourMatchScore(
      bike: BikeCategory.gravel,
      categories: const [BikeCategory.gravel],
      surface: 'gravel/compacted',
      mtbScale: '',
      isLoop: true,
    );
    final root = tourMatchScore(
      bike: BikeCategory.gravel,
      categories: const [BikeCategory.mtbAm],
      surface: 'trail/root',
      mtbScale: 'S2',
    );
    expect(g, greaterThan(root + 20));
    expect(g, greaterThanOrEqualTo(80));
  });

  test('enduro prefers technical character', () {
    final tech = tourMatchScore(
      bike: BikeCategory.mtbEnduro,
      categories: const [BikeCategory.mtbEnduro],
      surface: 'trail/root',
      mtbScale: 'S2',
    );
    final road = tourMatchScore(
      bike: BikeCategory.mtbEnduro,
      categories: const [BikeCategory.road],
      surface: 'asphalt/paved',
      mtbScale: '',
    );
    expect(tech, greaterThan(road));
    final reasons = tourMatchReasons(
      bike: BikeCategory.mtbEnduro,
      categories: const [BikeCategory.mtbEnduro],
      surface: 'trail/root',
      mtbScale: 'S2',
      score: tech,
    );
    expect(reasons, contains('Technischer Charakter'));
    expect(reasons.first, 'Passt zu deinem Rad');
  });

  test('score stays in 12–99', () {
    final low = tourMatchScore(
      bike: BikeCategory.road,
      categories: const [BikeCategory.mtbEnduro],
      surface: 'trail/root',
      mtbScale: 'S3+',
    );
    expect(low, greaterThanOrEqualTo(12));
    expect(low, lessThan(40));
  });
}
