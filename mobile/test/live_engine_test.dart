import 'package:aetherride_mobile/data/routing/routing_client.dart';
import 'package:aetherride_mobile/domain/bike.dart';
import 'package:aetherride_mobile/domain/routing/live_engine.dart';
import 'package:aetherride_mobile/domain/routing/nav_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LiveRoutingEngine', () {
    test('parse aliases and hybrid default', () {
      expect(LiveRoutingEngineX.parse('graphhopper'),
          LiveRoutingEngine.graphhopper);
      expect(LiveRoutingEngineX.parse('gh'), LiveRoutingEngine.graphhopper);
      expect(
        LiveRoutingEngineX.parse('openrouteservice'),
        LiveRoutingEngine.openrouteservice,
      );
      expect(
          LiveRoutingEngineX.parse('ors'), LiveRoutingEngine.openrouteservice);
      expect(LiveRoutingEngineX.parse('hybrid'), LiveRoutingEngine.hybrid);
      expect(LiveRoutingEngineX.parse(null), LiveRoutingEngine.hybrid);
      expect(LiveRoutingEngine.graphhopper.apiId, 'graphhopper');
      expect(LiveRoutingEngine.openrouteservice.apiId, 'openrouteservice');
      expect(LiveRoutingEngine.hybrid.apiId, isNull);
    });
  });

  group('engine vs costing', () {
    test('gravity approach stays auto/foot, never downhill bicycle', () {
      expect(
        approachRoutingProfile(BikeCategory.dh, ApproachKind.auto).apiId,
        'auto',
      );
      expect(
        approachRoutingProfile(BikeCategory.dh, ApproachKind.walk).apiId,
        'hiking',
      );
      expect(
        approachRoutingProfile(BikeCategory.dh, ApproachKind.auto),
        isNot(RoutingProfile.downhill),
      );
    });
  });
}
