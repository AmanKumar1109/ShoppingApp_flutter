import 'dart:math' as math;

/// Hub Location Specification for The Grocery Hub (Baharagora)
class BaharagoraHub {
  static const double lat = 22.2760625;
  static const double lng = 86.7193125;
  static const String name = 'THE GROCERY HUB';
  static const String address =
      'Dadu Complex, near Shitla Mandir, Baharagora, Jharkhand 832101';
  static const String pincode = '832101';
  static const double maxDeliveryRadiusKm = 5.0;
}

class ServiceabilityResult {
  final bool isServiceable;
  final double distanceKm;
  final double radiusLimitKm;
  final double diffKm;
  final String? reason;

  const ServiceabilityResult({
    required this.isServiceable,
    required this.distanceKm,
    this.radiusLimitKm = 5.0,
    required this.diffKm,
    this.reason,
  });
}

class LocationUtils {
  /// Calculates exact spherical Haversine distance between two coordinates in kilometers.
  static double calculateDistanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusKm = 6371.0;

    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180.0);
  }

  /// Validates whether coordinates fall within 5.0 km delivery boundary of Baharagora Hub.
  static ServiceabilityResult checkDeliveryServiceable(
    double lat,
    double lng, {
    double maxRadiusKm = 5.0,
  }) {
    final distanceKm = calculateDistanceKm(
      BaharagoraHub.lat,
      BaharagoraHub.lng,
      lat,
      lng,
    );

    final diffKm = distanceKm - maxRadiusKm;
    final isServiceable = distanceKm <= maxRadiusKm;

    return ServiceabilityResult(
      isServiceable: isServiceable,
      distanceKm: double.parse(distanceKm.toStringAsFixed(2)),
      radiusLimitKm: maxRadiusKm,
      diffKm: double.parse(diffKm.toStringAsFixed(2)),
      reason: isServiceable
          ? null
          : 'Delivery Unavailable: Address is ${distanceKm.toStringAsFixed(1)} km away. We deliver strictly within 5.0 km of Baharagora Hub.',
    );
  }

  /// Computes estimated delivery arrival time in minutes (minimum 10 minutes).
  static int calculateETA(double distanceKm, {double averageSpeedKmH = 20.0}) {
    if (distanceKm <= 0) return 10;
    final timeHours = distanceKm / averageSpeedKmH;
    final timeMinutes = (timeHours * 60).round() + 5; // +5 mins for packing & dispatch
    return math.max(10, timeMinutes);
  }
}
