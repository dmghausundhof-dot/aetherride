import 'package:aetherride_mobile/domain/garage/stand_photo.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('tall phone photo crops toward the ground', () {
    final r = standPhotoSourceRect(1200, 1600);
    expect(r.width, 1200);
    expect(r.height, closeTo(600, 0.5));
    expect(r.top, greaterThan(0));
  });

  test('wide photo crops the sides, centered by default', () {
    final r = standPhotoSourceRect(4000, 1000);
    expect(r.height, 1000);
    expect(r.width, closeTo(2000, 0.5));
    expect(r.left, closeTo(1000, 0.5));
  });

  test('wide photo pan uses xBias', () {
    final left = standPhotoSourceRect(4000, 1000, xBias: 0);
    expect(left.left, 0);
    final right = standPhotoSourceRect(4000, 1000, xBias: 1);
    expect(right.left, closeTo(2000, 0.5));
  });

  test('already-cropped stand strip is not cropped again', () {
    expect(standPhotoNeedsCrop(1000, 1600), isTrue);
    expect(standPhotoNeedsCrop(2000, 1000), isFalse);
    expect(standPhotoNeedsCrop(4000, 1000), isTrue);
  });
}
