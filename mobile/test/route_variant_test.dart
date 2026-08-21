import 'package:aetherride_mobile/domain/routing/route_variant.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parseRouteVariant and apiId', () {
    expect(parseRouteVariant('flatter'), RouteVariant.flatter);
    expect(parseRouteVariant('UNPAVED'), RouteVariant.unpaved);
    expect(parseRouteVariant('nope'), RouteVariant.planned);
    expect(RouteVariant.flatter.apiId, 'flatter');
    expect(RouteVariant.unpaved.apiId, 'unpaved');
  });

  test('planVariantChanged matches Web planEditKey variant delta', () {
    expect(
      planVariantChanged(
        before: RouteVariant.planned,
        after: RouteVariant.flatter,
      ),
      isTrue,
    );
    expect(
      planVariantChanged(
        before: RouteVariant.flatter,
        after: RouteVariant.flatter,
      ),
      isFalse,
    );
  });
}
