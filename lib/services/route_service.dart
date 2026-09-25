import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../utils/location_utils.dart';

class RouteResult {
  final List<LatLng> points;
  final double distanceKm;
  final int durationMins;
  final bool isFromRoadNetwork;

  const RouteResult({
    required this.points,
    required this.distanceKm,
    required this.durationMins,
    required this.isFromRoadNetwork,
  });
}

class RouteService {
  /// Option to provide your Google Maps Directions API Key.
  static const String googleMapsApiKey =
      'AIzaSyBDr3yesdrQTjW4t4lniRZuwZ8GuhcMB8k';

  // In-memory cache for calculated routes
  static final Map<String, RouteResult> _routeCache = {};

  /// Fetches exact turn-by-turn road polyline from Baharagora Hub to Destination
  static Future<RouteResult> fetchRoadRoute(LatLng destination) async {
    final hub = const LatLng(BaharagoraHub.lat, BaharagoraHub.lng);
    final cacheKey =
        '${hub.latitude},${hub.longitude}->${destination.latitude},${destination.longitude}';

    if (_routeCache.containsKey(cacheKey)) {
      return _routeCache[cacheKey]!;
    }

    // 1. Try Google Directions API if key is provided
    if (googleMapsApiKey.isNotEmpty) {
      try {
        final url = Uri.parse(
          'https://maps.googleapis.com/maps/api/directions/json?origin=${hub.latitude},${hub.longitude}&destination=${destination.latitude},${destination.longitude}&mode=driving&key=$googleMapsApiKey',
        );
        final response = await http
            .get(url)
            .timeout(const Duration(seconds: 5));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['status'] == 'OK' && (data['routes'] as List).isNotEmpty) {
            final route = data['routes'][0];
            final legs = route['legs'][0];
            final distanceKm = (legs['distance']['value'] as num) / 1000.0;
            final durationMins = ((legs['duration']['value'] as num) / 60.0)
                .round();
            final polylineStr = route['overview_polyline']['points'];
            final decodedPoints = _decodePolyline(polylineStr);

            final result = RouteResult(
              points: decodedPoints,
              distanceKm: distanceKm,
              durationMins: durationMins,
              isFromRoadNetwork: true,
            );
            _routeCache[cacheKey] = result;
            return result;
          }
        }
      } catch (e) {
        debugPrint('Google Directions API error, falling back to OSRM: $e');
      }
    }

    // 2. Try OSRM Real Road Routing Engine (100% Free, No Key Required, Exact Turn-by-Turn Road Geometry)
    try {
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/${hub.longitude},${hub.latitude};${destination.longitude},${destination.latitude}?overview=full&geometries=geojson',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 'Ok' && (data['routes'] as List).isNotEmpty) {
          final route = data['routes'][0];
          final distanceKm = (route['distance'] as num) / 1000.0;
          final durationMins =
              ((route['duration'] as num) / 60.0).round() + 5; // +5 mins prep
          final coordinates = route['geometry']['coordinates'] as List;

          final roadPoints = coordinates.map((coord) {
            final lng = (coord[0] as num).toDouble();
            final lat = (coord[1] as num).toDouble();
            return LatLng(lat, lng);
          }).toList();

          final result = RouteResult(
            points: roadPoints,
            distanceKm: double.parse(distanceKm.toStringAsFixed(2)),
            durationMins: durationMins < 10 ? 10 : durationMins,
            isFromRoadNetwork: true,
          );
          _routeCache[cacheKey] = result;
          return result;
        }
      }
    } catch (e) {
      debugPrint('OSRM Road Routing error, falling back to approximation: $e');
    }

    // 3. Fallback to geometric interpolation
    final fallbackPoints = getDeliveryRoute(destination);
    final distanceKm = LocationUtils.calculateDistanceKm(
      hub.latitude,
      hub.longitude,
      destination.latitude,
      destination.longitude,
    );
    final etaMins = LocationUtils.calculateETA(distanceKm);

    final fallbackResult = RouteResult(
      points: fallbackPoints,
      distanceKm: double.parse(distanceKm.toStringAsFixed(2)),
      durationMins: etaMins,
      isFromRoadNetwork: false,
    );
    _routeCache[cacheKey] = fallbackResult;
    return fallbackResult;
  }

  /// Generates approximate fallback route waypoints
  static List<LatLng> getDeliveryRoute(LatLng destination) {
    final hub = const LatLng(BaharagoraHub.lat, BaharagoraHub.lng);

    final distance = LocationUtils.calculateDistanceKm(
      hub.latitude,
      hub.longitude,
      destination.latitude,
      destination.longitude,
    );

    if (distance < 0.2) {
      return [hub, destination];
    }

    final dLat = destination.latitude - hub.latitude;
    final dLng = destination.longitude - hub.longitude;

    return [
      hub,
      LatLng(hub.latitude + dLat * 0.25, hub.longitude + dLng * 0.15),
      LatLng(hub.latitude + dLat * 0.55, hub.longitude + dLng * 0.60),
      LatLng(hub.latitude + dLat * 0.85, hub.longitude + dLng * 0.90),
      destination,
    ];
  }

  /// Calculates interpolated rider position based on progress (0.0 to 1.0) along the route.
  static LatLng getRiderPosition(List<LatLng> route, double progress) {
    if (route.isEmpty) {
      return const LatLng(BaharagoraHub.lat, BaharagoraHub.lng);
    }
    if (route.length == 1 || progress <= 0.0) {
      return route.first;
    }
    if (progress >= 1.0) {
      return route.last;
    }

    final totalSegments = route.length - 1;
    final exactSegment = progress * totalSegments;
    final index = exactSegment.floor().clamp(0, totalSegments - 1);
    final segmentProgress = exactSegment - index;

    final p1 = route[index];
    final p2 = route[index + 1];

    final lat = p1.latitude + (p2.latitude - p1.latitude) * segmentProgress;
    final lng = p1.longitude + (p2.longitude - p1.longitude) * segmentProgress;

    return LatLng(lat, lng);
  }

  /// Decodes Google polyline string format into LatLng list
  static List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }
}
