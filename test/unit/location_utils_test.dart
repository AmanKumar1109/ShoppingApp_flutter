import 'package:flutter_test/flutter_test.dart';
import 'package:groceryhub/utils/location_utils.dart';

void main() {
  group('LocationUtils & BaharagoraHub Geofencing Tests', () {
    test('Hub coordinates match Baharagora exact coordinates', () {
      expect(BaharagoraHub.lat, closeTo(22.2760, 0.001));
      expect(BaharagoraHub.lng, closeTo(86.7193, 0.001));
      expect(BaharagoraHub.maxDeliveryRadiusKm, 5.0);
    });

    test('Distance from Hub to itself is ~0.0 km and serviceable', () {
      final distance = LocationUtils.calculateDistanceKm(
        BaharagoraHub.lat,
        BaharagoraHub.lng,
        BaharagoraHub.lat,
        BaharagoraHub.lng,
      );
      expect(distance, closeTo(0.0, 0.01));

      final result = LocationUtils.checkDeliveryServiceable(
        BaharagoraHub.lat,
        BaharagoraHub.lng,
      );
      expect(result.isServiceable, isTrue);
      expect(result.distanceKm, 0.0);
      expect(result.reason, isNull);
    });

    test('Coordinates within 5km boundary (e.g. 1.5 km away) are serviceable', () {
      // Offset latitude slightly (~1.5 km north)
      final testLat = BaharagoraHub.lat + 0.0135;
      final testLng = BaharagoraHub.lng;

      final result = LocationUtils.checkDeliveryServiceable(testLat, testLng);
      expect(result.isServiceable, isTrue);
      expect(result.distanceKm, lessThanOrEqualTo(5.0));
      expect(result.reason, isNull);
    });

    test('Coordinates outside 5km boundary (e.g. Jamshedpur) are blocked', () {
      // Jamshedpur coordinates (~70 km away)
      const jsrLat = 22.8046;
      const jsrLng = 86.2029;

      final result = LocationUtils.checkDeliveryServiceable(jsrLat, jsrLng);
      expect(result.isServiceable, isFalse);
      expect(result.distanceKm, greaterThan(5.0));
      expect(result.reason, contains('Delivery Unavailable'));
      expect(result.diffKm, greaterThan(0.0));
    });

    test('ETA calculation respects minimum buffer of 10 minutes', () {
      expect(LocationUtils.calculateETA(0.0), 10);
      expect(LocationUtils.calculateETA(1.0), 10);
      expect(LocationUtils.calculateETA(4.5), greaterThanOrEqualTo(15));
    });
  });
}

