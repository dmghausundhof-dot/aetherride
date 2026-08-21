import 'dart:math' as math;

import 'package:aetherride_mobile/domain/tours/tour_line.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fitTourLine needs two points', () {
    expect(fitTourLine(const []), isNull);
    expect(
      fitTourLine(const [
        [8.6, 49.4],
      ]),
      isNull,
    );
  });

  test('open line is not a loop and stays in pad', () {
    final line = fitTourLine(const [
      [8.6, 49.4],
      [8.7, 49.5],
    ]);
    expect(line, isNotNull);
    expect(line!.loop, isFalse);
    expect(line.points.length, 2);
    expect(line.start.x, inInclusiveRange(8, 56));
    expect(line.end.y, inInclusiveRange(8, 56));
  });

  test('closed ring is a loop', () {
    final loop = fitTourLine(const [
      [8.68, 49.4],
      [8.7, 49.41],
      [8.72, 49.4],
      [8.7, 49.39],
      [8.68, 49.4],
    ]);
    expect(loop, isNotNull);
    expect(loop!.loop, isTrue);
    expect(loop.points.length, 5);
  });

  test('downsample keeps ends', () {
    final many = [
      for (var i = 0; i < 400; i++)
        [8.6 + i * 0.001, 49.4 + math.sin(i / 12) * 0.01],
    ];
    final sampled = downsampleLngLats(many, 64);
    expect(sampled.length, 64);
    expect(sampled.first, many.first);
    expect(sampled.last, many.last);
  });

  test('aspect: north-south vs east-west', () {
    final ns = fitTourLine(const [
      [8.7, 49.3],
      [8.7, 49.5],
    ]);
    final ew = fitTourLine(const [
      [8.6, 49.4],
      [8.9, 49.4],
    ]);
    expect((ns!.start.x - ns.end.x).abs(), lessThan(1));
    expect((ew!.start.y - ew.end.y).abs(), lessThan(1));
    expect((ns.end.y - ns.start.y).abs(), greaterThan(20));
    expect((ew.end.x - ew.start.x).abs(), greaterThan(20));
  });

  test('wide box still padded', () {
    final wide = fitTourLine(
      const [
        [8.6, 49.4],
        [8.8, 49.45],
        [8.7, 49.5],
      ],
      width: 128,
      height: 64,
    );
    expect(wide, isNotNull);
    expect(wide!.start.x, inInclusiveRange(8, 120));
    expect(wide.start.y, inInclusiveRange(7, 57));
  });

  test('trackCoordsOf prefers merged coordinates', () {
    expect(
      trackCoordsOf(
        coordinates: const [
          [1.0, 2.0],
        ],
        tour: const [
          [3.0, 4.0],
          [5.0, 6.0],
        ],
      ),
      [
        [3.0, 4.0],
        [5.0, 6.0],
      ],
    );
    expect(
      trackCoordsOf(
        coordinates: const [
          [1.0, 2.0],
          [3.0, 4.0],
        ],
        tour: const [
          [9.0, 9.0],
          [8.0, 8.0],
        ],
      ),
      [
        [1.0, 2.0],
        [3.0, 4.0],
      ],
    );
  });
}
