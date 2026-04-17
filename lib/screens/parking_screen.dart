import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/parking_service.dart';
import '../services/location_service.dart';
import '../config/api_config.dart';
import 'parking_navigation_screen.dart';

class ParkingScreen extends StatefulWidget {
  const ParkingScreen({super.key});

  @override
  State<ParkingScreen> createState() => _ParkingScreenState();
}

class _ParkingScreenState extends State<ParkingScreen> {
  List<LiveParkingSpot> _spots = [];
  bool _loading = true;
  bool _refreshing = false;
  String? _error;
  LatLng? _userLocation;
  DateTime? _lastUpdated;
  String _sortBy = 'Distance';
  Timer? _refreshTimer;

  final _locationService = LocationService();

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _locationService.startTracking();
    final pos = _locationService.currentPosition;
    _userLocation = pos ?? const LatLng(ApiConfig.baguioLat, ApiConfig.baguioLng);
    await _fetchParking();
    _refreshTimer = Timer.periodic(const Duration(minutes: 3), (_) {
      ParkingService.invalidateCache();
      _fetchParking(silent: true);
    });
  }

  Future<void> _fetchParking({bool silent = false}) async {
    if (!mounted) return;
    setState(() {
      if (silent) {
        _refreshing = true;
      } else {
        _loading = true;
        _error = null;
      }
    });
    try {
      final spots = await ParkingService.fetchNearby(
        userLocation: _userLocation!,
        radiusMeters: 2000,
      );
      if (!mounted) return;
      setState(() {
        _spots = spots;
        _loading = false;
        _refreshing = false;
        _error = null;
        _lastUpdated = DateTime.now();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _refreshing = false;
        _error = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  List<LiveParkingSpot> get _sorted {
    final list = List<LiveParkingSpot>.from(_spots);
    if (_sortBy == 'Distance') {
      list.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    } else if (_sortBy == 'Available') {
      list.sort((a, b) => b.availableSlots.compareTo(a.availableSlots));
    } else if (_sortBy == 'Occupancy') {
      list.sort((a, b) => a.occupancyRate.compareTo(b.occupancyRate));
    }
    return list;
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _locationService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Parking Near You',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2D3748),
        elevation: 0,
        actions: [
          if (_refreshing)
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Center(
                child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
              onPressed: () {
                ParkingService.invalidateCache();
                _fetchParking(silent: true);
              },
            ),
          PopupMenuButton<String>(
            initialValue: _sortBy,
            onSelected: (v) => setState(() => _sortBy = v),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'Distance', child: Text('Sort by Distance')),
              PopupMenuItem(value: 'Available', child: Text('Sort by Availability')),
              PopupMenuItem(value: 'Occupancy', child: Text('Sort by Occupancy')),
            ],
            icon: const Icon(Icons.sort),
          ),
        ],
      ),
      body: _loading
          ? const _LoadingView()
          : _error != null
              ? _ErrorView(error: _error!, onRetry: _fetchParking)
              : _spots.isEmpty
                  ? const _EmptyView()
                  : Column(
                      children: [
                        _buildSummaryBanner(),
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: () async {
                              ParkingService.invalidateCache();
                              await _fetchParking(silent: true);
                            },
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              itemCount: _sorted.length,
                              itemBuilder: (_, i) => _buildParkingCard(_sorted[i]),
                            ),
                          ),
                        ),
                      ],
                    ),
    );
  }

  Widget _buildSummaryBanner() {
    final totalAvail = _spots.fold(0, (s, p) => s + p.availableSlots);
    final updatedText = _lastUpdated != null
        ? 'Updated ${_timeAgo(_lastUpdated!)}'
        : 'Loading…';

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF1565C0), Color(0xFF42A5F5)]),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF1565C0).withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.local_parking, color: Colors.white, size: 36),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${_spots.length} parking areas found',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
                const SizedBox(height: 2),
                Text('$totalAvail total available slots',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8)),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle,
                        color: Color(0xFF69F0AE), size: 8),
                    SizedBox(width: 4),
                    Text('LIVE',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(updatedText,
                  style: const TextStyle(
                      color: Colors.white60, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildParkingCard(LiveParkingSpot spot) {
    final pct = spot.occupancyRate;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border:
            spot.isOpen ? null : Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: spot.statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.local_parking,
                    color: spot.statusColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(spot.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF2D3748))),
                    const SizedBox(height: 2),
                    Text(spot.address,
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF9CA3AF))),
                    if (spot.rating != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star,
                              color: Color(0xFFFFC107), size: 13),
                          const SizedBox(width: 3),
                          Text(spot.rating!.toStringAsFixed(1),
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF718096),
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: spot.statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8)),
                child: Text(spot.statusLabel,
                    style: TextStyle(
                        fontSize: 11,
                        color: spot.statusColor,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),

          if (spot.isOpen) ...[
            const SizedBox(height: 14),
            // Occupancy bar
            Row(
              children: [
                const Text('Occupancy',
                    style: TextStyle(
                        fontSize: 11, color: Color(0xFF9CA3AF))),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      backgroundColor: const Color(0xFFF5F7FA),
                      valueColor: AlwaysStoppedAnimation<Color>(
                          spot.statusColor),
                      minHeight: 8,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text('${(pct * 100).round()}%',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: spot.statusColor)),
              ],
            ),
            const SizedBox(height: 12),
            // Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _stat(Icons.check_circle_outline,
                    '${spot.availableSlots}', 'Available',
                    const Color(0xFF4CAF50)),
                _stat(Icons.directions_car, '${spot.totalSlots}',
                    'Total', const Color(0xFF2196F3)),
                _stat(Icons.near_me, spot.distanceLabel, 'Distance',
                    const Color(0xFF9C27B0)),
                _stat(Icons.attach_money, spot.fee, 'Fee',
                    const Color(0xFFFFA726)),
              ],
            ),
          ] else ...[
            const SizedBox(height: 10),
            const Row(
              children: [
                Icon(Icons.access_time,
                    size: 13, color: Color(0xFF9CA3AF)),
                SizedBox(width: 4),
                Text('Currently closed',
                    style: TextStyle(
                        fontSize: 11, color: Color(0xFF9CA3AF))),
              ],
            ),
          ],

          const SizedBox(height: 12),
          // Navigate button  ← opens in-app map with route
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: spot.isOpen
                  ? () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ParkingNavigationScreen(parking: spot),
                        ),
                      )
                  : null,
              icon: const Icon(Icons.navigation, size: 16),
              label:
                  Text(spot.isOpen ? 'Navigate Here' : 'Closed'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade200,
                disabledForegroundColor: Colors.grey,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(
      IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 3),
        Text(value,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color)),
        Text(label,
            style: const TextStyle(
                fontSize: 9, color: Color(0xFF9CA3AF))),
      ],
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }
}

// ── Helper widgets ───────────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Finding parking near you…',
              style: TextStyle(color: Color(0xFF718096))),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off,
                size: 56, color: Color(0xFFE53935)),
            const SizedBox(height: 16),
            const Text('Could not load parking data',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748))),
            const SizedBox(height: 8),
            Text(error,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFF9CA3AF))),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                  foregroundColor: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_parking,
              size: 56, color: Color(0xFF9CA3AF)),
          SizedBox(height: 16),
          Text('No parking areas found nearby',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748))),
          SizedBox(height: 8),
          Text('Pull down to refresh or try again later',
              style: TextStyle(
                  fontSize: 12, color: Color(0xFF9CA3AF))),
        ],
      ),
    );
  }
}
