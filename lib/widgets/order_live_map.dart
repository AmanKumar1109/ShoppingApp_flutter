import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/route_service.dart';
import '../utils/location_utils.dart';

class OrderLiveMap extends StatefulWidget {
  final double destinationLat;
  final double destinationLng;
  final String orderStatus;
  final String destinationAddress;
  final double? liveRiderLat;
  final double? liveRiderLng;
  final double height;

  const OrderLiveMap({
    super.key,
    required this.destinationLat,
    required this.destinationLng,
    required this.orderStatus,
    required this.destinationAddress,
    this.liveRiderLat,
    this.liveRiderLng,
    this.height = 260.0,
  });

  @override
  State<OrderLiveMap> createState() => _OrderLiveMapState();
}

class _OrderLiveMapState extends State<OrderLiveMap>
    with SingleTickerProviderStateMixin {
  late final MapController _mapController;
  late final AnimationController _pulseController;
  Timer? _riderSimTimer;
  double _riderProgress = 0.45;
  bool _isSatellite = false;

  List<LatLng> _routePoints = [];
  double _roadDistanceKm = 0.0;
  int _roadDurationMins = 15;

  final LatLng _hubLatLng = const LatLng(
    BaharagoraHub.lat,
    BaharagoraHub.lng,
  );

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _loadRoadRoute();
    _startRiderSimulationIfOutForDelivery();
  }

  Future<void> _loadRoadRoute() async {
    // Wait for the page slide transition (280ms) to finish cleanly
    await Future.delayed(const Duration(milliseconds: 280));
    if (!mounted) return;
    final result = await RouteService.fetchRoadRoute(_destLatLng);
    if (mounted) {
      setState(() {
        _routePoints = result.points;
        _roadDistanceKm = result.distanceKm;
        _roadDurationMins = result.durationMins;
      });
      // Adjust camera to fit the full road route
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _fitBounds();
      });
    }
  }

  void _startRiderSimulationIfOutForDelivery() {
    _riderSimTimer?.cancel();
    final status = widget.orderStatus.toLowerCase();

    if (status == 'out for delivery') {
      _riderSimTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
        if (!mounted) return;
        setState(() {
          _riderProgress += 0.03;
          if (_riderProgress > 0.95) {
            _riderProgress = 0.15; // Loop simulation for smooth live preview
          }
        });
      });
    } else if (status == 'delivered') {
      _riderProgress = 1.0;
    } else {
      _riderProgress = 0.05; // At store hub
    }
  }

  @override
  void didUpdateWidget(covariant OrderLiveMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.destinationLat != widget.destinationLat ||
        oldWidget.destinationLng != widget.destinationLng) {
      _loadRoadRoute();
    }
    if (oldWidget.orderStatus != widget.orderStatus) {
      _startRiderSimulationIfOutForDelivery();
    }
  }

  @override
  void dispose() {
    _riderSimTimer?.cancel();
    _pulseController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  LatLng get _destLatLng => LatLng(widget.destinationLat, widget.destinationLng);

  LatLng get _riderLatLng {
    if (widget.liveRiderLat != null && widget.liveRiderLng != null) {
      return LatLng(widget.liveRiderLat!, widget.liveRiderLng!);
    }
    final points = _routePoints.isNotEmpty
        ? _routePoints
        : RouteService.getDeliveryRoute(_destLatLng);
    return RouteService.getRiderPosition(points, _riderProgress);
  }

  void _fitBounds() {
    final pointsToFit = <LatLng>[
      _hubLatLng,
      _destLatLng,
      _riderLatLng,
      if (_routePoints.isNotEmpty) ..._routePoints,
    ];

    final bounds = LatLngBounds.fromPoints(pointsToFit);

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayPoints = _routePoints.isNotEmpty
        ? _routePoints
        : RouteService.getDeliveryRoute(_destLatLng);

    final statusLower = widget.orderStatus.toLowerCase();
    final isOutForDelivery = statusLower == 'out for delivery';
    final isDelivered = statusLower == 'delivered';

    // Google Maps Roadmap & Satellite Tile URLs
    final tileUrl = _isSatellite
        ? 'https://mt1.google.com/vt/lyrs=s,h&x={x}&y={y}&z={z}'
        : 'https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}';

    return Container(
      height: widget.height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFEEEEEE), width: 1.2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: LatLng(
                  (BaharagoraHub.lat + widget.destinationLat) / 2,
                  (BaharagoraHub.lng + widget.destinationLng) / 2,
                ),
                initialZoom: 14.2,
                minZoom: 10.0,
                maxZoom: 19.0,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: tileUrl,
                  userAgentPackageName: 'com.thegroceryhub.app',
                  maxZoom: 19,
                ),

                // Real Turn-by-Turn Delivery Route Polyline
                PolylineLayer(
                  polylines: [
                    // Outer shadow polyline
                    Polyline(
                      points: displayPoints,
                      strokeWidth: 6.0,
                      color: const Color(0xFF19251B).withValues(alpha: 0.7),
                    ),
                    // Inner bright polyline
                    Polyline(
                      points: displayPoints,
                      strokeWidth: 3.5,
                      color: const Color(0xFFF7C415),
                    ),
                  ],
                ),

                // Markers Layer
                MarkerLayer(
                  markers: [
                    // 1. Store Hub Marker
                    Marker(
                      point: _hubLatLng,
                      width: 44,
                      height: 44,
                      child: Tooltip(
                        message: 'The Grocery Hub (Store)',
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF19251B),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFF7C415),
                              width: 2.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.storefront_rounded,
                              color: Color(0xFFF7C415),
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // 2. Customer Destination Marker
                    Marker(
                      point: _destLatLng,
                      width: 40,
                      height: 40,
                      child: Tooltip(
                        message: widget.destinationAddress,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withValues(alpha: 0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.location_on_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // 3. Live Delivery Rider Marker (when active or out for delivery)
                    if (!isDelivered)
                      Marker(
                        point: _riderLatLng,
                        width: 50,
                        height: 50,
                        child: AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            return Stack(
                              alignment: Alignment.center,
                              children: [
                                if (isOutForDelivery)
                                  Container(
                                    width: 46 + (_pulseController.value * 8),
                                    height: 46 + (_pulseController.value * 8),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: const Color(0xFF10B981).withValues(
                                        alpha: 0.25 * (1 - _pulseController.value),
                                      ),
                                    ),
                                  ),
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.25),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.two_wheeler_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ],
            ),

            // Top Status & Road ETA Pill Overlay
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF19251B).withValues(alpha: 0.90),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isOutForDelivery
                            ? const Color(0xFF4ADE80)
                            : (isDelivered
                                ? const Color(0xFF60A5FA)
                                : const Color(0xFFF7C415)),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isDelivered
                          ? 'Delivered to Doorstep'
                          : (isOutForDelivery
                              ? 'Rider on Way • ~${_roadDurationMins}m (${_roadDistanceKm.toStringAsFixed(1)}km)'
                              : 'Preparing at Hub • ~${_roadDurationMins}m'),
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Floating Controls (Layer Toggle & Recenter)
            Positioned(
              bottom: 12,
              right: 12,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Layer Toggle (Satellite vs Roadmap)
                  FloatingActionButton.small(
                    heroTag: 'map_layer_toggle',
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF19251B),
                    elevation: 3,
                    onPressed: () {
                      setState(() => _isSatellite = !_isSatellite);
                    },
                    tooltip: _isSatellite ? 'Roadmap View' : 'Satellite View',
                    child: Icon(
                      _isSatellite
                          ? Icons.map_outlined
                          : Icons.satellite_alt_outlined,
                      size: 18,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Recenter on Hub & Destination
                  FloatingActionButton.small(
                    heroTag: 'map_recenter',
                    backgroundColor: const Color(0xFF19251B),
                    foregroundColor: const Color(0xFFF7C415),
                    elevation: 3,
                    onPressed: _fitBounds,
                    tooltip: 'Recenter Map',
                    child: const Icon(
                      Icons.my_location_rounded,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
