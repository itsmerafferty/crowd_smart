import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/models.dart';
import '../config/api_config.dart';
import '../services/location_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Destination GPS coordinates map (matches destinations list in route screen)
// ─────────────────────────────────────────────────────────────────────────────
const _destinationCoords = <String, LatLng>{
  'My Current Location':      LatLng(16.4119, 120.5937), // Baguio center fallback
  'Burnham Park':             LatLng(16.4119, 120.5937),
  'Mines View Park':          LatLng(16.3988, 120.5960),
  'The Mansion':              LatLng(16.4154, 120.5937),
  'Camp John Hay':            LatLng(16.3963, 120.5779),
  'Good Shepherd Convent':    LatLng(16.3964, 120.5779),
  'Session Road':             LatLng(16.4090, 120.5970),
  'Baguio Night Market':      LatLng(16.4080, 120.5960),
  'Botanical Garden':         LatLng(16.4140, 120.5920),
};

// ─────────────────────────────────────────────────────────────────────────────
// Named waypoint anchors on real Baguio roads
// ─────────────────────────────────────────────────────────────────────────────
// These are real GPS points verified on actual Baguio City roads.
// Each route ID gets a distinct intermediate waypoint so the Directions API
// is forced to route through a completely different road corridor.
class _BaguioWaypoints {
  // Route A anchors – Session Road / Governor Pack Road corridor (east side)
  static const sessionRoadMid    = LatLng(16.4090, 120.5973); // Session Rd mid
  static const govPackRoad       = LatLng(16.4068, 120.5955); // Gov. Pack Rd
  static const magsaysayAve      = LatLng(16.4075, 120.5942); // Magsaysay Ave

  // Route B anchors – Leonard Wood Road / Military Cut-off (north/west corridor)
  static const leonardWoodSouth  = LatLng(16.4153, 120.5897); // Leonard Wood Rd
  static const militaryCutOff    = LatLng(16.4128, 120.5838); // Military Cut-off Rd
  static const campJohnHayGate   = LatLng(16.4000, 120.5792); // Camp John Hay gate

  // Route C anchors – Bokawkan Road / Trancoville (north side bypass)
  static const bokawkanNorth     = LatLng(16.4215, 120.5898); // Bokawkan Rd north
  static const aspinallAve       = LatLng(16.4188, 120.5845); // Aspinall Ave
  static const trancovilleRd     = LatLng(16.4160, 120.5795); // Trancoville / Rimando

  // South-bound anchors (Kennon direction)
  static const kennon            = LatLng(16.3980, 120.5880); // Kennon Rd
}

// ─────────────────────────────────────────────────────────────────────────────
// NavigationScreen
// ─────────────────────────────────────────────────────────────────────────────
class NavigationScreen extends StatefulWidget {
  final RouteOption route;
  final String origin;
  final String destination;

  const NavigationScreen({
    super.key,
    required this.route,
    required this.origin,
    required this.destination,
  });

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen>
    with TickerProviderStateMixin {
  GoogleMapController? _mapController;

  Set<Polyline> _polylines = {};
  Set<Marker>   _markers   = {};

  bool   _isLoadingRoute = true;
  bool   _hasDirections  = false;
  String _statusText     = 'Getting your location…';

  bool   _isNavigating  = false;
  double _elapsedSecs   = 0;
  Timer? _navTimer;

  // ── Location ───────────────────────────────────────────────────────────────
  final LocationService _locationService = LocationService();
  StreamSubscription<LatLng>?        _locationSub;
  StreamSubscription<LocationStatus>? _locationStatusSub;
  LatLng?         _userPosition;
  double?         _userHeading;
  LocationStatus  _locationStatus = LocationStatus.idle;
  bool            _followUser     = false;   // camera follows user when navigating

  late AnimationController _pulseCtrl;
  late AnimationController _slideCtrl;
  late Animation<Offset>   _slideAnim;

  // Effective origin: real GPS if "My Current Location", else fixed coord
  LatLng get _originLatLng {
    if (widget.origin == 'My Current Location' && _userPosition != null) {
      return _userPosition!;
    }
    return _destinationCoords[widget.origin] ?? const LatLng(16.4119, 120.5937);
  }

  LatLng get _destLatLng =>
      _destinationCoords[widget.destination] ?? const LatLng(16.4119, 120.5937);

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);

    _slideCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));

    _initLocation();
  }

  Future<void> _initLocation() async {
    // Subscribe to position updates
    _locationSub = _locationService.positionStream.listen((pos) {
      if (!mounted) return;
      setState(() {
        _userPosition = pos;
        _userHeading  = _locationService.currentHeading;
      });
      _updateUserMarker(pos);
      // Follow user when navigation is active
      if (_followUser && _mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(CameraPosition(
            target: pos,
            zoom: 17,
            bearing: _userHeading ?? 0,
            tilt: 45,
          )),
        );
      }
    });

    _locationStatusSub = _locationService.statusStream.listen((status) {
      if (!mounted) return;
      setState(() => _locationStatus = status);
      if (status == LocationStatus.denied || status == LocationStatus.disabled) {
        // Still load route with fixed coords
        _loadRoute();
      }
    });

    await _locationService.startTracking();

    // If GPS ready, reload route with real position; else load with fixed coords
    if (_locationService.isTracking) {
      setState(() => _userPosition = _locationService.currentPosition);
    }
    _loadRoute();
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    _locationSub?.cancel();
    _locationStatusSub?.cancel();
    _locationService.dispose();
    _pulseCtrl.dispose();
    _slideCtrl.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  // ── User location marker ───────────────────────────────────────────────────
  void _updateUserMarker(LatLng pos) {
    final updated = Set<Marker>.from(
      _markers.where((m) => m.markerId.value != 'user_location'),
    );
    updated.add(Marker(
      markerId: const MarkerId('user_location'),
      position: pos,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      infoWindow: InfoWindow(
        title: '📍 Your Location',
        snippet:
            '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}',
      ),
      zIndexInt: 3,
      anchor: const Offset(0.5, 0.5),
    ));
    if (mounted) setState(() => _markers = updated);
  }

  // ── Route calculation ──────────────────────────────────────────────────────

  /// Returns intermediate waypoints for this route that force the Directions
  /// API onto a genuinely different road corridor.
  List<LatLng> _waypointsFor(String routeId, LatLng origin, LatLng dest) {
    // Determine the general compass direction so we pick sensible waypoints
    final goingSouth = dest.latitude < origin.latitude;
    final goingWest  = dest.longitude < origin.longitude;

    switch (routeId) {
      case 'a':
        // Session Road / Gov. Pack Road – eastern city-centre corridor
        if (goingSouth && goingWest) {
          return [_BaguioWaypoints.sessionRoadMid, _BaguioWaypoints.govPackRoad];
        } else if (goingSouth) {
          return [_BaguioWaypoints.govPackRoad, _BaguioWaypoints.kennon];
        } else {
          return [_BaguioWaypoints.sessionRoadMid, _BaguioWaypoints.magsaysayAve];
        }

      case 'b':
        // Leonard Wood Road / Military Cut-off – northern/western ridge corridor
        if (goingWest) {
          return [_BaguioWaypoints.leonardWoodSouth, _BaguioWaypoints.militaryCutOff];
        } else if (goingSouth) {
          return [_BaguioWaypoints.militaryCutOff, _BaguioWaypoints.campJohnHayGate];
        } else {
          return [_BaguioWaypoints.leonardWoodSouth, _BaguioWaypoints.campJohnHayGate];
        }

      case 'c':
        // Bokawkan / Trancoville – northern bypass corridor
        if (goingSouth) {
          return [_BaguioWaypoints.bokawkanNorth, _BaguioWaypoints.aspinallAve];
        } else if (goingWest) {
          return [_BaguioWaypoints.aspinallAve, _BaguioWaypoints.trancovilleRd];
        } else {
          return [_BaguioWaypoints.bokawkanNorth, _BaguioWaypoints.trancovilleRd];
        }

      default:
        return [];
    }
  }

  Future<void> _loadRoute() async {
    if (!mounted) return;
    setState(() { _isLoadingRoute = true; _statusText = 'Calculating route…'; });

    // Route index used to pick an alternative (0=A, 1=B, 2=C)
    final routeIndex = widget.route.id == 'a' ? 0 : widget.route.id == 'b' ? 1 : 2;

    // Get distinct waypoints that force this route onto its named road
    final waypoints = _waypointsFor(widget.route.id, _originLatLng, _destLatLng);

    // Try to fetch real directions with waypoints forcing the correct road
    final apiPoints = await _fetchDirections(
      origin: _originLatLng,
      destination: _destLatLng,
      waypoints: waypoints,
      routeIndex: routeIndex,
    );
    if (!mounted) return;

    if (apiPoints != null && apiPoints.length >= 2) {
      _buildPolylinesFrom(apiPoints);
      setState(() {
        _isLoadingRoute = false;
        _hasDirections  = true;
        _statusText     = 'Route loaded · ${widget.route.duration}';
      });
    } else {
      // Fallback: draw straight segments through the road-anchor waypoints
      final fallback = [_originLatLng, ...waypoints, _destLatLng];
      _buildPolylinesFrom(fallback);
      setState(() {
        _isLoadingRoute = false;
        _hasDirections  = false;
        _statusText     = 'Estimated route · ${widget.route.duration}';
      });
    }

    _buildMarkers();
    _fitRoute();
    _slideCtrl.forward();
  }

  Future<List<LatLng>?> _fetchDirections({
    required LatLng origin,
    required LatLng destination,
    required List<LatLng> waypoints,
    required int routeIndex,
  }) async {
    try {
      // Build waypoint string – use 'via:' prefix so Google routes THROUGH
      // those points on the actual road rather than treating them as stops.
      String wayStr = '';
      if (waypoints.isNotEmpty) {
        final encoded = waypoints
            .map((p) => 'via:${p.latitude},${p.longitude}')
            .join('|');
        wayStr = '&waypoints=$encoded';
      }

      // Request alternatives so we have multiple real road options to choose from
      final url = 'https://maps.googleapis.com/maps/api/directions/json'
          '?origin=${origin.latitude},${origin.longitude}'
          '&destination=${destination.latitude},${destination.longitude}'
          '$wayStr'
          '&alternatives=true'
          '&key=${ApiConfig.googleMapsApiKey}';

      final client   = HttpClient();
      final request  = await client.getUrl(Uri.parse(url));
      final response = await request.close().timeout(const Duration(seconds: 10));
      final body     = await utf8.decodeStream(response);
      client.close();

      final json = jsonDecode(body) as Map<String, dynamic>;
      if (json['status'] != 'OK') {
        debugPrint('[Nav] Directions status: ${json['status']}');
        return null;
      }

      final routes = json['routes'] as List<dynamic>;
      if (routes.isEmpty) return null;

      // Pick the alternative that matches this route's index.
      // If only 1 alternative exists, use it (waypoints already force the road).
      final pickedRoute = routes[routeIndex < routes.length ? routeIndex : 0];
      final legs  = pickedRoute['legs'] as List<dynamic>;
      final points = <LatLng>[];

      for (final leg in legs) {
        for (final step in leg['steps'] as List<dynamic>) {
          final poly = step['polyline']['points'] as String;
          points.addAll(_decodePolyline(poly));
        }
      }
      return points;
    } catch (e) {
      debugPrint('[Nav] Directions API error: $e');
      return null;
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    final List<LatLng> poly = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0; result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      poly.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return poly;
  }

  void _buildPolylinesFrom(List<LatLng> points) {
    // Shadow / casing polyline
    final casing = Polyline(
      polylineId: const PolylineId('route_casing'),
      points: points,
      color: Colors.black.withValues(alpha: 0.25),
      width: 10,
    );
    // Main coloured polyline
    final main = Polyline(
      polylineId: const PolylineId('route_main'),
      points: points,
      color: widget.route.trafficColor,
      width: 7,
      startCap: Cap.roundCap,
      endCap:   Cap.roundCap,
      jointType: JointType.round,
    );
    setState(() => _polylines = {casing, main});
  }

  void _buildMarkers() {
    final markers = <Marker>{};

    // Origin marker (green)
    markers.add(Marker(
      markerId: const MarkerId('origin'),
      position: _originLatLng,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      infoWindow: InfoWindow(
        title: '🟢 ${widget.origin}',
        snippet: 'Starting point',
      ),
    ));

    // Destination marker (red)
    markers.add(Marker(
      markerId: const MarkerId('destination'),
      position: _destLatLng,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      infoWindow: InfoWindow(
        title: '📍 ${widget.destination}',
        snippet: '${widget.route.duration} · ${widget.route.distance}',
      ),
    ));

    // User location marker (if already known)
    if (_userPosition != null) {
      markers.add(Marker(
        markerId: const MarkerId('user_location'),
        position: _userPosition!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: InfoWindow(
          title: '📍 Your Location',
          snippet:
              '${_userPosition!.latitude.toStringAsFixed(5)}, ${_userPosition!.longitude.toStringAsFixed(5)}',
        ),
        zIndexInt: 3,
        anchor: const Offset(0.5, 0.5),
      ));
    }

    setState(() => _markers = markers);
  }

  void _fitRoute() {
    if (_mapController == null) return;
    final pts = [_originLatLng, _destLatLng];
    if (_userPosition != null) pts.add(_userPosition!);
    final bounds = _boundsFromLatLngList(pts);
    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
  }

  LatLngBounds _boundsFromLatLngList(List<LatLng> list) {
    double minLat = list.first.latitude,  maxLat = list.first.latitude;
    double minLng = list.first.longitude, maxLng = list.first.longitude;
    for (final p in list) {
      if (p.latitude  < minLat) minLat = p.latitude;
      if (p.latitude  > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    return LatLngBounds(
      southwest: LatLng(minLat - 0.005, minLng - 0.005),
      northeast: LatLng(maxLat + 0.005, maxLng + 0.005),
    );
  }

  // ── Navigation timer ───────────────────────────────────────────────────────
  void _startNavigation() {
    setState(() { _isNavigating = true; _followUser = true; });
    _navTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsedSecs++);
    });
    // Zoom to user position if available, otherwise origin
    final target = _userPosition ?? _originLatLng;
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(CameraPosition(
        target: target,
        zoom: 17,
        bearing: _userHeading ?? 0,
        tilt: 45,
      )),
    );
  }

  void _stopNavigation() {
    _navTimer?.cancel();
    setState(() { _isNavigating = false; _followUser = false; _elapsedSecs = 0; });
    _fitRoute();
  }

  void _goToMyLocation() {
    final pos = _userPosition ?? _locationService.currentPosition;
    if (pos != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(CameraPosition(
          target: pos,
          zoom: 17,
          bearing: _userHeading ?? 0,
          tilt: _isNavigating ? 45 : 0,
        )),
      );
      if (_isNavigating) setState(() => _followUser = true);
    }
  }

  String get _elapsedLabel {
    final m = (_elapsedSecs / 60).floor();
    final s = (_elapsedSecs % 60).floor();
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map
          GoogleMap(
            onMapCreated: (c) {
              _mapController = c;
              if (!_isLoadingRoute) _fitRoute();
            },
            initialCameraPosition: CameraPosition(
              target: LatLng(
                (_originLatLng.latitude  + _destLatLng.latitude)  / 2,
                (_originLatLng.longitude + _destLatLng.longitude) / 2,
              ),
              zoom: 14,
            ),
            markers:   _markers,
            polylines: _polylines,
            trafficEnabled: true,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: true,
            onCameraMove: (_) {
              // Disable follow when user drags the map manually
              if (_followUser) setState(() => _followUser = false);
            },
          ),

          // Top bar
          _buildTopBar(),

          // Live location status bar (shown when tracking)
          if (_locationStatus == LocationStatus.tracking)
            _buildLocationStatusBar(),

          // Route info bottom panel
          if (!_isLoadingRoute) _buildBottomPanel(),

          // Loading overlay
          if (_isLoadingRoute) _buildLoadingOverlay(),

          // Navigation active bar
          if (_isNavigating) _buildNavBar(),

          // FABs (right side)
          _buildFabs(),
        ],
      ),
    );
  }

  // ── FABs ───────────────────────────────────────────────────────────────────
  Widget _buildFabs() {
    final bottomOffset = _isNavigating ? 220.0 : 200.0;
    return Positioned(
      right: 14,
      bottom: bottomOffset,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // My location FAB
          FloatingActionButton.small(
            heroTag: 'nav_my_loc',
            backgroundColor: _followUser
                ? const Color(0xFF2196F3)
                : Colors.white,
            onPressed: _goToMyLocation,
            child: Icon(
              _locationStatus == LocationStatus.tracking
                  ? (_followUser ? Icons.navigation : Icons.my_location)
                  : Icons.location_searching,
              color: _followUser ? Colors.white : const Color(0xFF2196F3),
              size: 18,
            ),
          ),
          const SizedBox(height: 8),
          // Fit route FAB
          FloatingActionButton.small(
            heroTag: 'nav_fit',
            backgroundColor: Colors.white,
            onPressed: () { setState(() => _followUser = false); _fitRoute(); },
            child: const Icon(Icons.fit_screen,
                color: Color(0xFF4CAF50), size: 18),
          ),
        ],
      ),
    );
  }

  // ── Top bar ────────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Positioned(
      top: 0, left: 0, right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 12, offset: const Offset(0, 3)),
              ],
            ),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F7FA),
                    borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.arrow_back,
                      size: 18, color: Color(0xFF2D3748)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Navigation',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Color(0xFF2D3748))),
                    Text(
                      '${widget.origin}  →  ${widget.destination}',
                      style: const TextStyle(
                          fontSize: 10, color: Color(0xFF9CA3AF)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Traffic badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.route.trafficColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: widget.route.trafficColor.withValues(alpha: 0.4)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.circle, size: 8, color: widget.route.trafficColor),
                  const SizedBox(width: 4),
                  Text(widget.route.trafficCondition,
                      style: TextStyle(
                          fontSize: 10,
                          color: widget.route.trafficColor,
                          fontWeight: FontWeight.w600)),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  // ── Bottom panel ───────────────────────────────────────────────────────────
  Widget _buildBottomPanel() {
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: SlideTransition(
        position: _slideAnim,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(color: Colors.black26, blurRadius: 16, offset: Offset(0, -4)),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Handle
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 12),

            // Route name row
            Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: widget.route.trafficColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.route, color: widget.route.trafficColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(widget.route.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF2D3748))),
                  if (!_hasDirections)
                    const Text('Estimated route (connect to internet for live directions)',
                        style: TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
                ]),
              ),
              if (widget.route.isRecommended)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50),
                    borderRadius: BorderRadius.circular(8)),
                  child: const Text('⭐ Best',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                ),
            ]),

            const SizedBox(height: 14),

            // Stats row
            Row(children: [
              _statTile(Icons.access_time, widget.route.duration, 'Duration'),
              const SizedBox(width: 8),
              _statTile(Icons.near_me,    widget.route.distance,  'Distance'),
              const SizedBox(width: 8),
              _statTile(Icons.alt_route,
                  widget.route.via.length > 1
                      ? '${widget.route.via.length} roads'
                      : widget.route.via.first,
                  'Via'),
            ]),

            const SizedBox(height: 10),

            // Via label
            Row(children: [
              const Icon(Icons.turn_slight_right, size: 13, color: Color(0xFF9CA3AF)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'via ${widget.route.via.join(' → ')}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Directions source tag
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _hasDirections
                      ? const Color(0xFF4CAF50).withValues(alpha: 0.1)
                      : const Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: _hasDirections
                        ? const Color(0xFF4CAF50).withValues(alpha: 0.4)
                        : const Color(0xFFE5E7EB)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(
                    _hasDirections ? Icons.wifi : Icons.wifi_off,
                    size: 9,
                    color: _hasDirections
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFF9CA3AF)),
                  const SizedBox(width: 3),
                  Text(
                    _hasDirections ? 'Live route' : 'Estimated',
                    style: TextStyle(
                      fontSize: 9,
                      color: _hasDirections
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFF9CA3AF),
                      fontWeight: FontWeight.w600)),
                ]),
              ),
            ]),

            const SizedBox(height: 14),

            // Start / Stop navigation button
            SizedBox(
              width: double.infinity,
              child: _isNavigating
                  ? OutlinedButton.icon(
                      onPressed: _stopNavigation,
                      icon: const Icon(Icons.stop_circle_outlined, size: 18),
                      label: const Text('Stop Navigation'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFE53935),
                        side: const BorderSide(color: Color(0xFFE53935)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    )
                  : ElevatedButton.icon(
                      onPressed: _startNavigation,
                      icon: const Icon(Icons.navigation, size: 18),
                      label: const Text('Start Navigation',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                      ),
                    ),
            ),
          ]),
        ),
      ),
    );
  }

  // ── Loading overlay ────────────────────────────────────────────────────────
  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.white.withValues(alpha: 0.85),
      child: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const CircularProgressIndicator(
            color: Color(0xFF4CAF50), strokeWidth: 3),
          const SizedBox(height: 16),
          Text(_statusText,
              style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF2D3748),
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text('${widget.origin}  →  ${widget.destination}',
              style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
        ]),
      ),
    );
  }

  // ── Navigation active bar ──────────────────────────────────────────────────
  Widget _buildNavBar() {
    return Positioned(
      bottom: 190,
      left: 14,
      right: 72,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF4CAF50),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4CAF50).withValues(alpha: 0.4),
              blurRadius: 10, offset: const Offset(0, 3)),
          ],
        ),
        child: Row(children: [
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, __) => Opacity(
              opacity: 0.5 + _pulseCtrl.value * 0.5,
              child: const Icon(Icons.navigation, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 8),
          const Text('Navigating',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8)),
            child: Text(_elapsedLabel,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    fontFeatures: [FontFeature.tabularFigures()])),
          ),
        ]),
      ),
    );
  }

  // ── Stat tile ──────────────────────────────────────────────────────────────
  Widget _statTile(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(children: [
          Icon(icon, size: 16, color: const Color(0xFF6B7280)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748))),
          Text(label,
              style: const TextStyle(fontSize: 9, color: Color(0xFF9CA3AF))),
        ]),
      ),
    );
  }

  // ── Location status bar ────────────────────────────────────────────────────
  Widget _buildLocationStatusBar() {
    final pos = _userPosition;
    return Positioned(
      left: 12,
      right: 80,
      bottom: _isNavigating ? 230 : 210,
      child: GestureDetector(
        onTap: _goToMyLocation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _followUser ? const Color(0xFF2196F3) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (_, __) => Icon(
                  Icons.my_location,
                  size: 13,
                  color: _followUser
                      ? Colors.white.withValues(alpha: 0.5 + _pulseCtrl.value * 0.5)
                      : const Color(0xFF2196F3),
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  pos != null
                      ? '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}'
                      : 'Getting location…',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _followUser ? Colors.white : const Color(0xFF2196F3),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (_followUser) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('LIVE',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}












