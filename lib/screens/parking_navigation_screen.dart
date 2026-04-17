import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../services/location_service.dart';
import '../services/parking_service.dart';

class ParkingNavigationScreen extends StatefulWidget {
  final LiveParkingSpot parking;

  const ParkingNavigationScreen({super.key, required this.parking});

  @override
  State<ParkingNavigationScreen> createState() =>
      _ParkingNavigationScreenState();
}

class _ParkingNavigationScreenState extends State<ParkingNavigationScreen>
    with TickerProviderStateMixin {
  // ── Map / Route ────────────────────────────────────────────────────────────
  GoogleMapController? _mapController;
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};
  bool _isLoading = true;
  String _duration = '';
  String _distance = '';
  List<String> _steps = [];

  // ── Location ───────────────────────────────────────────────────────────────
  final _locationService = LocationService();
  StreamSubscription<LatLng>? _locationSub;
  LatLng? _userPosition;
  double? _userHeading;
  bool _isNavigating = false;
  bool _followUser = false;
  Timer? _navTimer;
  double _elapsedSecs = 0;

  // ── Anim ───────────────────────────────────────────────────────────────────
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);
    _initLocation();
  }

  Future<void> _initLocation() async {
    _locationSub = _locationService.positionStream.listen((pos) {
      if (!mounted) return;
      setState(() {
        _userPosition = pos;
        _userHeading = _locationService.currentHeading;
      });
      _updateUserMarker(pos);
      if (_followUser && _mapController != null) {
        _mapController!.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(
            target: pos,
            zoom: 17,
            bearing: _userHeading ?? 0,
            tilt: 45,
          ),
        ));
      }
    });

    await _locationService.startTracking();
    if (_locationService.currentPosition != null) {
      setState(() => _userPosition = _locationService.currentPosition);
    }
    await _loadRoute();
  }

  Future<void> _loadRoute() async {
    setState(() {
      _isLoading = true;
    });

    final origin = _userPosition ??
        const LatLng(ApiConfig.baguioLat, ApiConfig.baguioLng);
    final dest = widget.parking.position;

    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=${origin.latitude},${origin.longitude}'
        '&destination=${dest.latitude},${dest.longitude}'
        '&mode=driving'
        '&key=${ApiConfig.googleMapsApiKey}',
      );

      final response =
          await http.get(url).timeout(const Duration(seconds: 10));
      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (data['status'] == 'OK') {
        final route = data['routes'][0];
        final leg = route['legs'][0];
        _duration = leg['duration']['text'] as String;
        _distance = leg['distance']['text'] as String;

        // Decode polyline
        final encoded =
            route['overview_polyline']['points'] as String;
        final points = _decodePolyline(encoded);

        // Extract turn-by-turn steps
        _steps = (leg['steps'] as List)
            .map((s) => _stripHtml(s['html_instructions'] as String))
            .toList();

        final polyline = Polyline(
          polylineId: const PolylineId('parking_route'),
          color: const Color(0xFF1565C0),
          width: 5,
          points: points,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          jointType: JointType.round,
        );

        final markers = <Marker>{
          // Destination marker
          Marker(
            markerId: const MarkerId('parking_dest'),
            position: dest,
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueRed),
            infoWindow: InfoWindow(
              title: widget.parking.name,
              snippet: widget.parking.address,
            ),
          ),
        };

        // User marker
        if (_userPosition != null) {
          markers.add(_buildUserMarker(_userPosition!));
        }

        setState(() {
          _polylines = {polyline};
          _markers = markers;
          _isLoading = false;
        });

        // Fit bounds to show full route
        await Future.delayed(const Duration(milliseconds: 300));
        if (_mapController != null) {
          final bounds = _boundsFromLatLngList([origin, dest, ...points]);
          _mapController!.animateCamera(
            CameraUpdate.newLatLngBounds(bounds, 80),
          );
        }
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _updateUserMarker(LatLng pos) {
    final updated = Set<Marker>.from(
        _markers.where((m) => m.markerId.value != 'user_location'));
    updated.add(_buildUserMarker(pos));
    if (mounted) setState(() => _markers = updated);
  }

  Marker _buildUserMarker(LatLng pos) => Marker(
        markerId: const MarkerId('user_location'),
        position: pos,
        icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: '📍 You'),
        anchor: const Offset(0.5, 0.5),
      );

  void _startNavigation() {
    setState(() {
      _isNavigating = true;
      _followUser = true;
      _elapsedSecs = 0;
    });
    _navTimer =
        Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsedSecs++);
    });
    // Snap camera to user
    if (_userPosition != null && _mapController != null) {
      _mapController!.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(
          target: _userPosition!,
          zoom: 17,
          bearing: _userHeading ?? 0,
          tilt: 45,
        ),
      ));
    }
  }

  void _stopNavigation() {
    _navTimer?.cancel();
    setState(() {
      _isNavigating = false;
      _followUser = false;
    });
    // Zoom back to full route
    if (_polylines.isNotEmpty) {
      final points =
          _polylines.first.points;
      if (points.isNotEmpty && _mapController != null) {
        final bounds = _boundsFromLatLngList(points);
        _mapController!.animateCamera(
            CameraUpdate.newLatLngBounds(bounds, 80));
      }
    }
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    _locationSub?.cancel();
    _locationService.dispose();
    _pulseCtrl.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Map ────────────────────────────────────────────────────────────
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _userPosition ??
                  const LatLng(ApiConfig.baguioLat, ApiConfig.baguioLng),
              zoom: 15,
            ),
            onMapCreated: (c) {
              _mapController = c;
              if (!_isLoading && _polylines.isNotEmpty) {
                final bounds = _boundsFromLatLngList(
                    _polylines.first.points);
                c.animateCamera(
                    CameraUpdate.newLatLngBounds(bounds, 80));
              }
            },
            polylines: _polylines,
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            trafficEnabled: true,
            mapToolbarEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: true,
            mapType: MapType.normal,
          ),

          // ── Loading overlay ────────────────────────────────────────────────
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 12),
                    Text('Calculating route…',
                        style:
                            TextStyle(color: Colors.white, fontSize: 14)),
                  ],
                ),
              ),
            ),

          // ── Top bar ────────────────────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
              ],
            ),
          ),

          // ── Bottom panel ───────────────────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomPanel(),
          ),

          // ── Re-center button ───────────────────────────────────────────────
          Positioned(
            right: 16,
            bottom: _isNavigating ? 200 : 220,
            child: FloatingActionButton.small(
              heroTag: 'recenter',
              backgroundColor: Colors.white,
              onPressed: () {
                if (_userPosition != null && _mapController != null) {
                  _mapController!.animateCamera(
                      CameraUpdate.newLatLng(_userPosition!));
                }
              },
              child: const Icon(Icons.my_location,
                  color: Color(0xFF1565C0)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.arrow_back,
                  size: 20, color: Color(0xFF2D3748)),
            ),
          ),
          const SizedBox(width: 10),
          const Icon(Icons.local_parking,
              color: Color(0xFF1565C0), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.parking.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Color(0xFF2D3748)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(widget.parking.address,
                    style: const TextStyle(
                        fontSize: 10, color: Color(0xFF9CA3AF)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          if (_duration.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(_duration,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Color(0xFF1565C0))),
                Text(_distance,
                    style: const TextStyle(
                        fontSize: 10, color: Color(0xFF9CA3AF))),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildBottomPanel() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, -3))
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 6),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2)),
          ),

          // Parking info row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: widget.parking.statusColor
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.local_parking,
                      color: widget.parking.statusColor, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.parking.statusLabel,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: widget.parking.statusColor)),
                      Text(
                        '${widget.parking.availableSlots} of ${widget.parking.totalSlots} slots available  •  ${widget.parking.fee}',
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF9CA3AF)),
                      ),
                    ],
                  ),
                ),
                // Elapsed time when navigating
                if (_isNavigating)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Elapsed',
                          style: TextStyle(
                              fontSize: 9, color: Color(0xFF9CA3AF))),
                      Text(_formatElapsed(_elapsedSecs),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Color(0xFF1565C0))),
                    ],
                  ),
              ],
            ),
          ),

          const Divider(height: 12, indent: 16, endIndent: 16),

          // First step instruction
          if (_steps.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.turn_right_outlined,
                      color: Color(0xFF1565C0), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _steps.first,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF2D3748)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 10),

          // Action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                // Recalculate / overview button
                Expanded(
                  flex: 1,
                  child: OutlinedButton.icon(
                    onPressed: _loadRoute,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Recalc',
                        style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1565C0),
                      side: const BorderSide(color: Color(0xFF1565C0)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Start / Stop navigation
                Expanded(
                  flex: 2,
                  child: _isNavigating
                      ? ElevatedButton.icon(
                          onPressed: _stopNavigation,
                          icon: const Icon(Icons.stop, size: 18),
                          label: const Text('Stop Navigation'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE53935),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        )
                      : ElevatedButton.icon(
                          onPressed:
                              _polylines.isEmpty ? null : _startNavigation,
                          icon: const Icon(Icons.navigation, size: 18),
                          label: const Text('Start Navigation'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1565C0),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey.shade300,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  String _formatElapsed(double secs) {
    final m = (secs ~/ 60).toString().padLeft(2, '0');
    final s = (secs % 60).toInt().toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _stripHtml(String html) =>
      html.replaceAll(RegExp(r'<[^>]+>'), ' ').replaceAll('  ', ' ').trim();

  List<LatLng> _decodePolyline(String encoded) {
    final list = <LatLng>[];
    int idx = 0;
    int lat = 0, lng = 0;
    while (idx < encoded.length) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(idx++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lat += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(idx++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lng += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      list.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return list;
  }

  LatLngBounds _boundsFromLatLngList(List<LatLng> pts) {
    double minLat = pts.first.latitude,
        maxLat = pts.first.latitude,
        minLng = pts.first.longitude,
        maxLng = pts.first.longitude;
    for (final p in pts) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }
}





