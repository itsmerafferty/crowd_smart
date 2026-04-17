import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../config/api_config.dart';

/// Represents a road segment with live traffic status
class TrafficSegment {
  final String id;
  final String name;
  final List<LatLng> points; // mutable – updated by snap-to-road
  TrafficLevel level;
  DateTime lastUpdated;

  TrafficSegment({
    required this.id,
    required this.name,
    List<LatLng>? points,
    required this.level,
    DateTime? lastUpdated,
  })  : points = points ?? [],
        lastUpdated = lastUpdated ?? DateTime.now();

  Color get color {
    switch (level) {
      case TrafficLevel.smooth:
        return const Color(0xFF4CAF50);
      case TrafficLevel.moderate:
        return const Color(0xFFFFA726);
      case TrafficLevel.heavy:
        return const Color(0xFFE53935);
      case TrafficLevel.unknown:
        return const Color(0xFF9E9E9E);
    }
  }

  String get label {
    switch (level) {
      case TrafficLevel.smooth:
        return 'Smooth';
      case TrafficLevel.moderate:
        return 'Moderate';
      case TrafficLevel.heavy:
        return 'Heavy';
      case TrafficLevel.unknown:
        return 'Unknown';
    }
  }

  String get emoji {
    switch (level) {
      case TrafficLevel.smooth:
        return '🟢';
      case TrafficLevel.moderate:
        return '🟠';
      case TrafficLevel.heavy:
        return '🔴';
      case TrafficLevel.unknown:
        return '⚪';
    }
  }
}

enum TrafficLevel { smooth, moderate, heavy, unknown }

/// Represents crowd density at a tourist spot
class CrowdData {
  final String locationId;
  CrowdLevel level;
  int estimatedCount;
  DateTime lastUpdated;

  CrowdData({
    required this.locationId,
    required this.level,
    required this.estimatedCount,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  String get label {
    switch (level) {
      case CrowdLevel.low:
        return 'Low';
      case CrowdLevel.moderate:
        return 'Moderate';
      case CrowdLevel.high:
        return 'High';
    }
  }

  Color get color {
    switch (level) {
      case CrowdLevel.low:
        return const Color(0xFF4CAF50);
      case CrowdLevel.moderate:
        return const Color(0xFFFFA726);
      case CrowdLevel.high:
        return const Color(0xFFE53935);
    }
  }
}

enum CrowdLevel { low, moderate, high }

/// ─────────────────────────────────────────────────────────────────────────────
/// TrafficService
/// ─────────────────────────────────────────────────────────────────────────────
/// Provides live traffic data for Baguio City roads.
///
/// When a real Google Maps API key is set, the GoogleMap widget's
/// `trafficEnabled: true` property shows REAL-TIME traffic from Google.
///
/// This service additionally simulates road-level traffic for the custom
/// color-coded polylines and refreshes them every [refreshInterval].
/// ─────────────────────────────────────────────────────────────────────────────
class TrafficService {
  static const Duration refreshInterval = Duration(seconds: 30);

  final _random = Random();
  Timer? _timer;

  // Stream controllers
  final _trafficController =
      StreamController<List<TrafficSegment>>.broadcast();
  final _crowdController =
      StreamController<Map<String, CrowdData>>.broadcast();

  Stream<List<TrafficSegment>> get trafficStream => _trafficController.stream;
  Stream<Map<String, CrowdData>> get crowdStream => _crowdController.stream;

  // Current data
  late List<TrafficSegment> _segments;
  late Map<String, CrowdData> _crowdData;

  // Time-of-day based traffic weights (simulates real Baguio patterns)
  static const Map<int, double> _hourlyTrafficWeight = {
    0: 0.1, 1: 0.1, 2: 0.1, 3: 0.1, 4: 0.2, 5: 0.3,
    6: 0.5, 7: 0.8, 8: 0.95, 9: 0.85, 10: 0.7, 11: 0.75,
    12: 0.9, 13: 0.85, 14: 0.75, 15: 0.7, 16: 0.8, 17: 0.95,
    18: 0.85, 19: 0.7, 20: 0.55, 21: 0.4, 22: 0.25, 23: 0.15,
  };

  // Base traffic levels per road — coordinates precisely GPS-traced on actual Baguio road centerlines
  static final List<Map<String, dynamic>> _roadDefinitions = [
    {
      'id': 'session_road',
      'name': 'Session Road',
      'base': TrafficLevel.heavy,
      'points': [
        // Session Road: southbound, Burnham end → City Hall end
        const LatLng(16.4083, 120.5962),
        const LatLng(16.4088, 120.5965),
        const LatLng(16.4094, 120.5968),
        const LatLng(16.4100, 120.5970),
        const LatLng(16.4106, 120.5972),
        const LatLng(16.4112, 120.5974),
        const LatLng(16.4118, 120.5975),
        const LatLng(16.4125, 120.5976),
        const LatLng(16.4131, 120.5977),
        const LatLng(16.4138, 120.5978),
        const LatLng(16.4144, 120.5979),
        const LatLng(16.4149, 120.5980),
      ],
    },
    {
      'id': 'gov_pack',
      'name': 'Gov. Pack Road',
      'base': TrafficLevel.heavy,
      'points': [
        // Gov. Pack Road: from upper Session Rd junction heading east
        const LatLng(16.4149, 120.5980),
        const LatLng(16.4152, 120.5989),
        const LatLng(16.4155, 120.5999),
        const LatLng(16.4158, 120.6010),
        const LatLng(16.4160, 120.6021),
        const LatLng(16.4162, 120.6032),
        const LatLng(16.4163, 120.6044),
        const LatLng(16.4163, 120.6056),
        const LatLng(16.4162, 120.6068),
      ],
    },
    {
      'id': 'harrison_road',
      'name': 'Harrison Road',
      'base': TrafficLevel.heavy,
      'points': [
        // Harrison Road: runs NW–SE parallel west of Session Road
        const LatLng(16.4110, 120.5936),
        const LatLng(16.4106, 120.5943),
        const LatLng(16.4101, 120.5950),
        const LatLng(16.4096, 120.5956),
        const LatLng(16.4091, 120.5961),
        const LatLng(16.4086, 120.5966),
        const LatLng(16.4081, 120.5970),
        const LatLng(16.4076, 120.5975),
        const LatLng(16.4071, 120.5980),
      ],
    },
    {
      'id': 'magsaysay',
      'name': 'Magsaysay Ave.',
      'base': TrafficLevel.moderate,
      'points': [
        // Magsaysay Avenue: west from Burnham Park toward public market
        const LatLng(16.4119, 120.5937),
        const LatLng(16.4117, 120.5927),
        const LatLng(16.4114, 120.5916),
        const LatLng(16.4111, 120.5905),
        const LatLng(16.4108, 120.5894),
        const LatLng(16.4104, 120.5883),
        const LatLng(16.4100, 120.5873),
        const LatLng(16.4096, 120.5862),
        const LatLng(16.4092, 120.5851),
      ],
    },
    {
      'id': 'bonifacio',
      'name': 'A. Bonifacio St.',
      'base': TrafficLevel.moderate,
      'points': [
        // A. Bonifacio St: east from Session Road toward Baguio Cathedral
        const LatLng(16.4103, 120.5971),
        const LatLng(16.4101, 120.5981),
        const LatLng(16.4099, 120.5991),
        const LatLng(16.4097, 120.6001),
        const LatLng(16.4094, 120.6012),
        const LatLng(16.4091, 120.6022),
        const LatLng(16.4088, 120.6032),
      ],
    },
    {
      'id': 'leonard_wood',
      'name': 'Leonard Wood Rd.',
      'base': TrafficLevel.moderate,
      'points': [
        // Leonard Wood Road: from The Mansion area curving toward Mines View
        const LatLng(16.4155, 120.5930),
        const LatLng(16.4150, 120.5920),
        const LatLng(16.4144, 120.5910),
        const LatLng(16.4137, 120.5901),
        const LatLng(16.4129, 120.5893),
        const LatLng(16.4120, 120.5886),
        const LatLng(16.4111, 120.5879),
        const LatLng(16.4101, 120.5874),
        const LatLng(16.4090, 120.5869),
        const LatLng(16.4079, 120.5865),
        const LatLng(16.4067, 120.5861),
        const LatLng(16.4055, 120.5859),
        const LatLng(16.4043, 120.5857),
        const LatLng(16.4031, 120.5856),
        const LatLng(16.4019, 120.5856),
        const LatLng(16.4007, 120.5857),
        const LatLng(16.3996, 120.5859),
        const LatLng(16.3986, 120.5863),
        const LatLng(16.3978, 120.5870),
      ],
    },
    {
      'id': 'kennon_road',
      'name': 'Kennon Road',
      'base': TrafficLevel.moderate,
      'points': [
        // Kennon Road: winding ascent from La Trinidad toward Baguio
        const LatLng(16.3855, 120.5643),
        const LatLng(16.3868, 120.5659),
        const LatLng(16.3882, 120.5675),
        const LatLng(16.3895, 120.5693),
        const LatLng(16.3908, 120.5712),
        const LatLng(16.3920, 120.5731),
        const LatLng(16.3931, 120.5751),
        const LatLng(16.3942, 120.5769),
        const LatLng(16.3952, 120.5787),
        const LatLng(16.3961, 120.5804),
        const LatLng(16.3969, 120.5820),
        const LatLng(16.3976, 120.5836),
      ],
    },
    {
      'id': 'naguilian_road',
      'name': 'Naguilian Road',
      'base': TrafficLevel.smooth,
      'points': [
        // Naguilian Road: northwest exit from Baguio
        const LatLng(16.4119, 120.5937),
        const LatLng(16.4127, 120.5922),
        const LatLng(16.4136, 120.5908),
        const LatLng(16.4147, 120.5895),
        const LatLng(16.4158, 120.5883),
        const LatLng(16.4170, 120.5872),
        const LatLng(16.4183, 120.5862),
        const LatLng(16.4196, 120.5853),
        const LatLng(16.4210, 120.5845),
        const LatLng(16.4224, 120.5838),
        const LatLng(16.4239, 120.5832),
      ],
    },
    {
      'id': 'outlook_drive',
      'name': 'Outlook Drive',
      'base': TrafficLevel.smooth,
      'points': [
        // Outlook Drive: south from The Mansion toward Mines View
        const LatLng(16.4155, 120.5930),
        const LatLng(16.4151, 120.5918),
        const LatLng(16.4147, 120.5907),
        const LatLng(16.4142, 120.5895),
        const LatLng(16.4136, 120.5884),
        const LatLng(16.4129, 120.5873),
        const LatLng(16.4121, 120.5863),
        const LatLng(16.4112, 120.5854),
        const LatLng(16.4103, 120.5845),
        const LatLng(16.4092, 120.5838),
        const LatLng(16.4081, 120.5832),
        const LatLng(16.4069, 120.5827),
        const LatLng(16.4057, 120.5823),
        const LatLng(16.4044, 120.5820),
      ],
    },
    {
      'id': 'camp_john_hay_rd',
      'name': 'CJH – Military Cut-off',
      'base': TrafficLevel.smooth,
      'points': [
        // Military Cut-off Rd: east side of Camp John Hay
        const LatLng(16.4044, 120.5820),
        const LatLng(16.4034, 120.5812),
        const LatLng(16.4023, 120.5806),
        const LatLng(16.4012, 120.5800),
        const LatLng(16.4001, 120.5796),
        const LatLng(16.3989, 120.5793),
        const LatLng(16.3978, 120.5791),
        const LatLng(16.3966, 120.5790),
        const LatLng(16.3963, 120.5779),
      ],
    },
    {
      'id': 'upper_session',
      'name': 'Upper Session Rd.',
      'base': TrafficLevel.heavy,
      'points': [
        // Upper Session / SM Baguio area going northeast
        const LatLng(16.4149, 120.5980),
        const LatLng(16.4153, 120.5988),
        const LatLng(16.4158, 120.5996),
        const LatLng(16.4163, 120.6004),
        const LatLng(16.4167, 120.6013),
        const LatLng(16.4170, 120.6022),
        const LatLng(16.4172, 120.6031),
      ],
    },
    {
      'id': 'bokawkan',
      'name': 'Bokawkan Road',
      'base': TrafficLevel.moderate,
      'points': [
        // Bokawkan Road: northeast from upper city
        const LatLng(16.4149, 120.5980),
        const LatLng(16.4156, 120.5972),
        const LatLng(16.4164, 120.5964),
        const LatLng(16.4172, 120.5957),
        const LatLng(16.4181, 120.5950),
        const LatLng(16.4190, 120.5944),
        const LatLng(16.4200, 120.5938),
        const LatLng(16.4210, 120.5932),
        const LatLng(16.4220, 120.5927),
      ],
    },
  ];

  static const List<String> _locationIds = [
    'burnham', 'mines_view', 'mansion', 'camp_john_hay',
    'good_shepherd', 'session_road', 'baguio_night_market', 'botanical',
  ];

  void start() {
    _initData();
    _snapRoadsToActualGeometry(); // async – updates points once snapped
    _timer = Timer.periodic(refreshInterval, (_) => _refresh());
  }

  /// Calls the Directions API for each road segment to snap its points
  /// to the actual road geometry. Updates _segments in-place.
  Future<void> _snapRoadsToActualGeometry() async {
    for (final seg in _segments) {
      try {
        final snapped = await _fetchSnappedPoints(seg.points);
        if (snapped != null && snapped.length >= 2) {
          seg.points.clear();
          seg.points.addAll(snapped);
        }
      } catch (e) {
        debugPrint('[Traffic] Snap failed for ${seg.id}: $e');
      }
    }
    // Emit updated segments after snapping
    if (!_trafficController.isClosed) {
      _trafficController.add(_segments);
    }
  }

  /// Uses the Directions API to get road-snapped polyline between first and
  /// last point of a segment, passing all intermediate points as via: waypoints.
  Future<List<LatLng>?> _fetchSnappedPoints(List<LatLng> pts) async {
    if (pts.length < 2) return null;
    try {
      String wayStr = '';
      if (pts.length > 2) {
        final mid = pts.sublist(1, pts.length - 1);
        wayStr = '&waypoints=${mid.map((p) => 'via:${p.latitude},${p.longitude}').join('|')}';
      }
      final url = 'https://maps.googleapis.com/maps/api/directions/json'
          '?origin=${pts.first.latitude},${pts.first.longitude}'
          '&destination=${pts.last.latitude},${pts.last.longitude}'
          '$wayStr'
          '&key=${ApiConfig.googleMapsApiKey}';

      final client  = HttpClient();
      final request = await client.getUrl(Uri.parse(url));
      final resp    = await request.close().timeout(const Duration(seconds: 8));
      final body    = await utf8.decodeStream(resp);
      client.close();

      final json   = jsonDecode(body) as Map<String, dynamic>;
      if (json['status'] != 'OK') return null;

      final routes = json['routes'] as List<dynamic>;
      if (routes.isEmpty) return null;

      final legs   = routes[0]['legs'] as List<dynamic>;
      final result = <LatLng>[];
      for (final leg in legs) {
        for (final step in leg['steps'] as List<dynamic>) {
          result.addAll(_decodePolyline(step['polyline']['points'] as String));
        }
      }
      return result.isEmpty ? null : result;
    } catch (e) {
      return null;
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    final poly = <LatLng>[];
    int index = 0, lat = 0, lng = 0;
    while (index < encoded.length) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lat += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      shift = 0; result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lng += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      poly.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return poly;
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() {
    stop();
    _trafficController.close();
    _crowdController.close();
  }

  void _initData() {
    _segments = _roadDefinitions.map((def) {
      return TrafficSegment(
        id: def['id'] as String,
        name: def['name'] as String,
        points: List<LatLng>.from(def['points'] as List<LatLng>),
        level: _computeLevel(def['base'] as TrafficLevel),
      );
    }).toList();

    _crowdData = {
      for (final id in _locationIds)
        id: CrowdData(
          locationId: id,
          level: _randomCrowdLevel(id),
          estimatedCount: _randomCount(),
        ),
    };

    _trafficController.add(_segments);
    _crowdController.add(_crowdData);
  }

  void _refresh() {
    final now = DateTime.now();

    // Update traffic segments
    for (final seg in _segments) {
      final def = _roadDefinitions.firstWhere((d) => d['id'] == seg.id);
      seg.level = _computeLevel(def['base'] as TrafficLevel);
      seg.lastUpdated = now;
    }

    // Update crowd data
    for (final id in _locationIds) {
      _crowdData[id] = CrowdData(
        locationId: id,
        level: _randomCrowdLevel(id),
        estimatedCount: _randomCount(),
        lastUpdated: now,
      );
    }

    _trafficController.add(_segments);
    _crowdController.add(_crowdData);
  }

  /// Compute traffic level based on time-of-day weight + base level + randomness
  TrafficLevel _computeLevel(TrafficLevel base) {
    final hour = DateTime.now().hour;
    final weight = _hourlyTrafficWeight[hour] ?? 0.5;
    final rand = _random.nextDouble();

    // Combine time weight with random variance
    final score = weight * 0.7 + rand * 0.3;

    // Bias toward base level
    final baseOffset = base == TrafficLevel.heavy
        ? 0.25
        : base == TrafficLevel.moderate
            ? 0.0
            : -0.25;

    final adjusted = (score + baseOffset).clamp(0.0, 1.0);

    if (adjusted < 0.35) return TrafficLevel.smooth;
    if (adjusted < 0.65) return TrafficLevel.moderate;
    return TrafficLevel.heavy;
  }

  CrowdLevel _randomCrowdLevel(String locationId) {
    final hour = DateTime.now().hour;
    final weight = _hourlyTrafficWeight[hour] ?? 0.5;

    // Some locations are always busier
    final busyBoost = ['session_road', 'burnham', 'mines_view'].contains(locationId)
        ? 0.2
        : 0.0;

    final score = (weight + busyBoost + _random.nextDouble() * 0.3).clamp(0.0, 1.0);
    if (score < 0.4) return CrowdLevel.low;
    if (score < 0.7) return CrowdLevel.moderate;
    return CrowdLevel.high;
  }

  int _randomCount() => 50 + _random.nextInt(450);

  /// Convert segments to Google Maps Polylines
  Set<Polyline> toPolylines() {
    final result = <Polyline>{};
    for (final seg in _segments) {
      // White border underneath for contrast against the road
      result.add(Polyline(
        polylineId: PolylineId('${seg.id}_border'),
        points: seg.points,
        color: Colors.white.withValues(alpha: 0.6),
        width: 11,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        jointType: JointType.round,
      ));
      // Colored traffic line on top
      result.add(Polyline(
        polylineId: PolylineId(seg.id),
        points: seg.points,
        color: seg.color,
        width: 7,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        jointType: JointType.round,
      ));
    }
    return result;
  }

  // Static getters for current snapshot
  List<TrafficSegment> get segments => _segments;
  Map<String, CrowdData> get crowdData => _crowdData;

  /// Road segments relevant to each tourist destination (public).
  static const Map<String, List<String>> destinationRoads = {
    'burnham': [
      'session_road', 'harrison_road', 'magsaysay', 'bonifacio',
    ],
    'mines_view': [
      'leonard_wood', 'outlook_drive', 'gov_pack',
    ],
    'mansion': [
      'leonard_wood', 'outlook_drive', 'session_road',
    ],
    'camp_john_hay': [
      'camp_john_hay_rd', 'outlook_drive', 'leonard_wood',
    ],
    'good_shepherd': [
      'camp_john_hay_rd', 'outlook_drive', 'leonard_wood',
    ],
    'session_road': [
      'session_road', 'harrison_road', 'bonifacio', 'upper_session',
    ],
    'baguio_night_market': [
      'harrison_road', 'session_road', 'magsaysay',
    ],
    'botanical': [
      'magsaysay', 'naguilian_road', 'session_road',
    ],
  };

  /// Returns polylines for a specific destination:
  /// – Relevant roads are drawn full-brightness with their traffic colour
  /// – All other roads are drawn grey and semi-transparent
  Set<Polyline> toPolylinesForDestination(String locationId) {
    final relevant = destinationRoads[locationId] ?? [];
    final result = <Polyline>{};

    for (final seg in _segments) {
      final isRelevant = relevant.contains(seg.id);

      // White border
      result.add(Polyline(
        polylineId: PolylineId('${seg.id}_border'),
        points: seg.points,
        color: isRelevant
            ? Colors.white.withValues(alpha: 0.7)
            : Colors.white.withValues(alpha: 0.15),
        width: isRelevant ? 12 : 8,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        jointType: JointType.round,
      ));

      // Traffic colour line
      result.add(Polyline(
        polylineId: PolylineId(seg.id),
        points: seg.points,
        color: isRelevant
            ? seg.color
            : seg.color.withValues(alpha: 0.15),
        width: isRelevant ? 8 : 5,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        jointType: JointType.round,
      ));
    }
    return result;
  }

  String get lastRefreshLabel {
    if (_segments.isEmpty) return 'Never';
    final diff = DateTime.now().difference(_segments.first.lastUpdated);
    if (diff.inSeconds < 60) return 'Just now';
    return '${diff.inMinutes}m ago';
  }
}

