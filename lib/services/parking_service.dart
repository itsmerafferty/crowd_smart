import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

/// A live parking spot fetched from Google Places API
class LiveParkingSpot {
  final String placeId;
  final String name;
  final String address;
  final LatLng position;
  final double distanceKm;
  final bool isOpen;
  final double? rating;
  final int totalSlots;
  final int availableSlots;
  final String fee;

  LiveParkingSpot({
    required this.placeId,
    required this.name,
    required this.address,
    required this.position,
    required this.distanceKm,
    required this.isOpen,
    this.rating,
    required this.totalSlots,
    required this.availableSlots,
    required this.fee,
  });

  double get occupancyRate =>
      totalSlots > 0 ? 1 - (availableSlots / totalSlots) : 0.5;

  Color get statusColor {
    if (occupancyRate < 0.5) return const Color(0xFF4CAF50);
    if (occupancyRate < 0.8) return const Color(0xFFFFA726);
    return const Color(0xFFE53935);
  }

  String get statusLabel {
    if (!isOpen) return 'Closed';
    if (occupancyRate < 0.5) return 'Available';
    if (occupancyRate < 0.8) return 'Filling Up';
    return 'Almost Full';
  }

  String get distanceLabel {
    if (distanceKm < 1.0) return '${(distanceKm * 1000).round()} m';
    return '${distanceKm.toStringAsFixed(1)} km';
  }
}

class ParkingService {
  static const String _baseUrl =
      'https://maps.googleapis.com/maps/api/place/nearbysearch/json';

  // Simulated slot data keyed by placeId (refreshed every 3 minutes)
  static final Map<String, _SlotData> _slotCache = {};
  static DateTime? _lastFetch;
  static final _random = Random();

  /// Fetch real parking lots near [userLocation] within [radiusMeters].
  /// Slot counts are simulated because Places API does not expose them.
  static Future<List<LiveParkingSpot>> fetchNearby({
    required LatLng userLocation,
    int radiusMeters = 1500,
  }) async {
    final url = Uri.parse(
      '$_baseUrl'
      '?location=${userLocation.latitude},${userLocation.longitude}'
      '&radius=$radiusMeters'
      '&type=parking'
      '&key=${ApiConfig.googleMapsApiKey}',
    );

    final response = await http.get(url).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw Exception('Places API error: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final status = data['status'] as String;
    if (status == 'ZERO_RESULTS') return [];
    if (status != 'OK') throw Exception('Places API status: $status');

    final results = data['results'] as List<dynamic>;
    final now = DateTime.now();
    final needsRefresh =
        _lastFetch == null || now.difference(_lastFetch!).inMinutes >= 3;

    final spots = <LiveParkingSpot>[];
    for (final r in results) {
      final placeId = r['place_id'] as String;
      final name = r['name'] as String? ?? 'Parking';
      final address = r['vicinity'] as String? ?? '';
      final lat = (r['geometry']['location']['lat'] as num).toDouble();
      final lng = (r['geometry']['location']['lng'] as num).toDouble();
      final pos = LatLng(lat, lng);
      final dist = _haversine(userLocation, pos);

      // Opening hours
      bool isOpen = true;
      final openNow = r['opening_hours'];
      if (openNow != null) {
        isOpen = openNow['open_now'] as bool? ?? true;
      }

      final ratingRaw = r['rating'];
      final rating =
          ratingRaw != null ? (ratingRaw as num).toDouble() : null;

      // Refresh or create simulated slot data
      if (needsRefresh || !_slotCache.containsKey(placeId)) {
        _slotCache[placeId] = _generateSlots(isOpen);
      }
      final slotData = _slotCache[placeId]!;

      spots.add(LiveParkingSpot(
        placeId: placeId,
        name: name,
        address: address,
        position: pos,
        distanceKm: dist,
        isOpen: isOpen,
        rating: rating,
        totalSlots: slotData.total,
        availableSlots: slotData.available,
        fee: _estimateFee(name),
      ));
    }

    if (needsRefresh) _lastFetch = now;

    spots.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    return spots;
  }

  static _SlotData _generateSlots(bool isOpen) {
    if (!isOpen) return _SlotData(total: 0, available: 0);
    final total = 50 + _random.nextInt(450); // 50–500 slots
    final occupancy = 0.1 + _random.nextDouble() * 0.85; // 10–95% full
    final available = (total * (1 - occupancy)).round().clamp(0, total);
    return _SlotData(total: total, available: available);
  }

  static String _estimateFee(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('sm') || lower.contains('mall')) return '₱50/hr';
    if (lower.contains('hotel') || lower.contains('resort')) return '₱60/hr';
    if (lower.contains('hospital') || lower.contains('medical')) return '₱30/hr';
    return '₱40/hr';
  }

  /// Haversine distance in km between two LatLng points
  static double _haversine(LatLng a, LatLng b) {
    const R = 6371.0;
    final dLat = _toRad(b.latitude - a.latitude);
    final dLon = _toRad(b.longitude - a.longitude);
    final sinLat = sin(dLat / 2);
    final sinLon = sin(dLon / 2);
    final c = sinLat * sinLat +
        cos(_toRad(a.latitude)) * cos(_toRad(b.latitude)) * sinLon * sinLon;
    return R * 2 * atan2(sqrt(c), sqrt(1 - c));
  }

  static double _toRad(double deg) => deg * pi / 180;

  /// Force-refresh the cached slot data (call after 3 min timer fires)
  static void invalidateCache() {
    _lastFetch = null;
  }
}

class _SlotData {
  final int total;
  final int available;
  _SlotData({required this.total, required this.available});
}

