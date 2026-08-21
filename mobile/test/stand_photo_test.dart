import 'package:aetherride_mobile/domain/garage/stand_photo.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('tall phone photo crops toward the ground', () {
    final r = standPhotoSourceRect(1200, 1600);
    expect(r.width, 1200);
    expect(r.height, lessThan(1600));
    expect(r.top, greaterThan(0));
  });

  test('wide photo crops the sides', () {
    final r = standPhotoSourceRect(4000, 1000);
    expect(r.height, 1000);
    expect(r.width, lessThan(4000));
    expect(r.left, greaterThan(0));
  });

  test('already-cropped stand strip is not cropped again', () {
    expect(standPhotoNeedsCrop(1000, 1600), isTrue);
    expect(standPhotoNeedsCrop(2350, 1000), isFalse);
    expect(standPhotoNeedsCrop(4000, 1000), isTrue);
  });
}
