import 'dart:async';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/traffic_service.dart';
import 'navigation_screen.dart';

class RouteSuggestionScreen extends StatefulWidget {
  const RouteSuggestionScreen({super.key});

  @override
  State<RouteSuggestionScreen> createState() => _RouteSuggestionScreenState();
}

class _RouteSuggestionScreenState extends State<RouteSuggestionScreen> {
  String? _selectedOrigin;
  String? _selectedDestination;
  int _selectedRoute = 1; // index of recommended route

  // Live traffic data
  final TrafficService _trafficService = TrafficService();
  StreamSubscription<List<TrafficSegment>>? _trafficSub;
  List<TrafficSegment> _liveSegments = [];

  @override
  void initState() {
    super.initState();
    _trafficService.start();
    _trafficSub = _trafficService.trafficStream.listen((segs) {
      if (!mounted) return;
      setState(() => _liveSegments = segs);
    });
  }

  @override
  void dispose() {
    _trafficSub?.cancel();
    _trafficService.dispose();
    super.dispose();
  }

  static const List<String> _destinations = [
    'My Current Location',
    'Burnham Park',
    'Mines View Park',
    'The Mansion',
    'Camp John Hay',
    'Good Shepherd Convent',
    'Session Road',
    'Baguio Night Market',
    'Botanical Garden',
  ];

  List<RouteOption> get _routes {
    if (_selectedDestination == null || _selectedOrigin == null) {
      return _defaultRoutes;
    }
    return _buildRoutesFor(_selectedDestination!);
  }

  List<RouteOption> get _defaultRoutes => [
    RouteOption(
      id: 'a', name: 'Route A – Session Road',
      duration: _liveDuration(25, ['session_road', 'gov_pack', 'harrison_road']),
      distance: '6.2 km',
      trafficCondition: _worstLabelFor(['session_road', 'gov_pack', 'harrison_road']),
      trafficColor: _worstColorFor(['session_road', 'gov_pack', 'harrison_road']),
      via: ['Session Road', 'Gov. Pack Road', 'Harrison Road'],
    ),
    RouteOption(
      id: 'b', name: 'Route B – Leonard Wood Road',
      duration: _liveDuration(18, ['leonard_wood', 'outlook_drive']),
      distance: '5.8 km',
      trafficCondition: _worstLabelFor(['leonard_wood', 'outlook_drive']),
      trafficColor: _worstColorFor(['leonard_wood', 'outlook_drive']),
      isRecommended: true,
      via: ['Leonard Wood Rd', 'Outlook Drive', 'Military Cut-off'],
    ),
    RouteOption(
      id: 'c', name: 'Route C – Bokawkan Road',
      duration: _liveDuration(22, ['bokawkan', 'magsaysay', 'naguilian_road']),
      distance: '6.5 km',
      trafficCondition: _worstLabelFor(['bokawkan', 'magsaysay', 'naguilian_road']),
      trafficColor: _worstColorFor(['bokawkan', 'magsaysay', 'naguilian_road']),
      via: ['Bokawkan Road', 'Magsaysay Ave.', 'Naguilian Road'],
    ),
  ];

  /// Returns live traffic colour/condition for a segment by ID.
  Color _liveColorFor(String segId) {
    if (_liveSegments.isEmpty) return const Color(0xFF9CA3AF);
    final seg = _liveSegments.where((s) => s.id == segId).firstOrNull;
    return seg?.color ?? const Color(0xFF9CA3AF);
  }

  /// Picks the worst (heaviest) traffic colour from a list of segment IDs.
  Color _worstColorFor(List<String> segIds) {
    Color worst = const Color(0xFF4CAF50);
    for (final id in segIds) {
      final c = _liveColorFor(id);
      if (c == const Color(0xFFE53935)) return c;
      if (c == const Color(0xFFFFA726)) worst = c;
    }
    return worst;
  }

  String _worstLabelFor(List<String> segIds) {
    final c = _worstColorFor(segIds);
    if (c == const Color(0xFFE53935)) return 'Heavy Traffic';
    if (c == const Color(0xFFFFA726)) return 'Moderate Traffic';
    return 'Light Traffic';
  }

  /// Adjusts a base travel time (minutes) based on live traffic of the given segments.
  /// Heavy  → +40–60 %,  Moderate → +15–25 %,  Light → base time
  String _liveDuration(int baseMinutes, List<String> segIds) {
    if (_liveSegments.isEmpty) return '$baseMinutes mins';
    final c = _worstColorFor(segIds);
    double factor;
    if (c == const Color(0xFFE53935)) {
      factor = 1.50; // heavy – 50 % longer
    } else if (c == const Color(0xFFFFA726)) {
      factor = 1.20; // moderate – 20 % longer
    } else {
      factor = 1.00; // light – base time
    }
    final adjusted = (baseMinutes * factor).round();
    return '$adjusted mins';
  }

  List<RouteOption> _buildRoutesFor(String dest) {
    switch (dest) {
      case 'Burnham Park':
      case 'Baguio Night Market':
        return [
          RouteOption(
            id: 'a', name: 'Route A – Session Road',
            duration: _liveDuration(12, ['session_road', 'harrison_road']),
            distance: '2.8 km',
            trafficCondition: _worstLabelFor(['session_road', 'harrison_road']),
            trafficColor: _worstColorFor(['session_road', 'harrison_road']),
            via: ['Session Road', 'Harrison Road', 'Gov. Pack Road'],
          ),
          RouteOption(
            id: 'b', name: 'Route B – Leonard Wood Rd',
            duration: _liveDuration(9, ['leonard_wood', 'outlook_drive']),
            distance: '2.4 km',
            trafficCondition: _worstLabelFor(['leonard_wood', 'outlook_drive']),
            trafficColor: _worstColorFor(['leonard_wood', 'outlook_drive']),
            isRecommended: true,
            via: ['Leonard Wood Rd', 'Outlook Drive'],
          ),
          RouteOption(
            id: 'c', name: 'Route C – Bokawkan Road',
            duration: _liveDuration(14, ['bokawkan', 'magsaysay']),
            distance: '3.1 km',
            trafficCondition: _worstLabelFor(['bokawkan', 'magsaysay']),
            trafficColor: _worstColorFor(['bokawkan', 'magsaysay']),
            via: ['Bokawkan Road', 'Magsaysay Ave.'],
          ),
        ];

      case 'Session Road':
        return [
          RouteOption(
            id: 'a', name: 'Route A – Harrison Road',
            duration: _liveDuration(8, ['harrison_road', 'magsaysay']),
            distance: '1.9 km',
            trafficCondition: _worstLabelFor(['harrison_road', 'magsaysay']),
            trafficColor: _worstColorFor(['harrison_road', 'magsaysay']),
            via: ['Harrison Road', 'Magsaysay Ave.'],
          ),
          RouteOption(
            id: 'b', name: 'Route B – Leonard Wood Rd',
            duration: _liveDuration(7, ['leonard_wood']),
            distance: '1.7 km',
            trafficCondition: _worstLabelFor(['leonard_wood']),
            trafficColor: _worstColorFor(['leonard_wood']),
            isRecommended: true,
            via: ['Leonard Wood Rd', 'A. Bonifacio St.'],
          ),
          RouteOption(
            id: 'c', name: 'Route C – Bokawkan Road',
            duration: _liveDuration(11, ['bokawkan', 'upper_session']),
            distance: '2.5 km',
            trafficCondition: _worstLabelFor(['bokawkan', 'upper_session']),
            trafficColor: _worstColorFor(['bokawkan', 'upper_session']),
            via: ['Bokawkan Road', 'Upper Session Rd.'],
          ),
        ];

      case 'Mines View Park':
        return [
          RouteOption(
            id: 'a', name: 'Route A – Session → Gov. Pack',
            duration: _liveDuration(22, ['session_road', 'gov_pack', 'outlook_drive']),
            distance: '5.5 km',
            trafficCondition: _worstLabelFor(['session_road', 'gov_pack', 'outlook_drive']),
            trafficColor: _worstColorFor(['session_road', 'gov_pack', 'outlook_drive']),
            via: ['Session Road', 'Gov. Pack Road', 'Outlook Drive'],
          ),
          RouteOption(
            id: 'b', name: 'Route B – Leonard Wood Rd',
            duration: _liveDuration(17, ['leonard_wood', 'camp_john_hay_rd']),
            distance: '4.9 km',
            trafficCondition: _worstLabelFor(['leonard_wood', 'camp_john_hay_rd']),
            trafficColor: _worstColorFor(['leonard_wood', 'camp_john_hay_rd']),
            isRecommended: true,
            via: ['Leonard Wood Rd', 'Military Cut-off', 'Outlook Drive'],
          ),
          RouteOption(
            id: 'c', name: 'Route C – Bokawkan Bypass',
            duration: _liveDuration(20, ['bokawkan', 'naguilian_road']),
            distance: '5.8 km',
            trafficCondition: _worstLabelFor(['bokawkan', 'naguilian_road']),
            trafficColor: _worstColorFor(['bokawkan', 'naguilian_road']),
            via: ['Bokawkan Road', 'Naguilian Road', 'Aspinall Ave'],
          ),
        ];

      case 'The Mansion':
        return [
          RouteOption(
            id: 'a', name: 'Route A – Session → Gov. Pack',
            duration: _liveDuration(14, ['session_road', 'gov_pack']),
            distance: '3.2 km',
            trafficCondition: _worstLabelFor(['session_road', 'gov_pack']),
            trafficColor: _worstColorFor(['session_road', 'gov_pack']),
            via: ['Session Road', 'Gov. Pack Road', 'A. Bonifacio St.'],
          ),
          RouteOption(
            id: 'b', name: 'Route B – Leonard Wood Rd',
            duration: _liveDuration(10, ['leonard_wood', 'outlook_drive']),
            distance: '2.6 km',
            trafficCondition: _worstLabelFor(['leonard_wood', 'outlook_drive']),
            trafficColor: _worstColorFor(['leonard_wood', 'outlook_drive']),
            isRecommended: true,
            via: ['Leonard Wood Rd', 'Outlook Drive'],
          ),
          RouteOption(
            id: 'c', name: 'Route C – Bokawkan → Magsaysay',
            duration: _liveDuration(13, ['bokawkan', 'magsaysay', 'naguilian_road']),
            distance: '3.5 km',
            trafficCondition: _worstLabelFor(['bokawkan', 'magsaysay', 'naguilian_road']),
            trafficColor: _worstColorFor(['bokawkan', 'magsaysay', 'naguilian_road']),
            via: ['Bokawkan Road', 'Magsaysay Ave.', 'Naguilian Road'],
          ),
        ];

      case 'Camp John Hay':
      case 'Good Shepherd Convent':
        return [
          RouteOption(
            id: 'a', name: 'Route A – Session → Kennon',
            duration: _liveDuration(18, ['session_road', 'kennon_road']),
            distance: '4.5 km',
            trafficCondition: _worstLabelFor(['session_road', 'kennon_road']),
            trafficColor: _worstColorFor(['session_road', 'kennon_road']),
            via: ['Session Road', 'Gov. Pack Road', 'Kennon Road'],
          ),
          RouteOption(
            id: 'b', name: 'Route B – Military Cut-off',
            duration: _liveDuration(13, ['leonard_wood', 'camp_john_hay_rd']),
            distance: '3.8 km',
            trafficCondition: _worstLabelFor(['leonard_wood', 'camp_john_hay_rd']),
            trafficColor: _worstColorFor(['leonard_wood', 'camp_john_hay_rd']),
            isRecommended: true,
            via: ['Leonard Wood Rd', 'Military Cut-off', 'CJH Road'],
          ),
          RouteOption(
            id: 'c', name: 'Route C – Bokawkan → Loakan',
            duration: _liveDuration(16, ['bokawkan', 'kennon_road']),
            distance: '4.2 km',
            trafficCondition: _worstLabelFor(['bokawkan', 'kennon_road']),
            trafficColor: _worstColorFor(['bokawkan', 'kennon_road']),
            via: ['Bokawkan Road', 'Magsaysay Ave.', 'Loakan Road'],
          ),
        ];

      case 'Botanical Garden':
        return [
          RouteOption(
            id: 'a', name: 'Route A – Magsaysay Ave',
            duration: _liveDuration(10, ['magsaysay', 'harrison_road']),
            distance: '2.3 km',
            trafficCondition: _worstLabelFor(['magsaysay', 'harrison_road']),
            trafficColor: _worstColorFor(['magsaysay', 'harrison_road']),
            via: ['Magsaysay Ave.', 'Harrison Road', 'Naguilian Road'],
          ),
          RouteOption(
            id: 'b', name: 'Route B – Leonard Wood Rd',
            duration: _liveDuration(8, ['leonard_wood', 'naguilian_road']),
            distance: '2.0 km',
            trafficCondition: _worstLabelFor(['leonard_wood', 'naguilian_road']),
            trafficColor: _worstColorFor(['leonard_wood', 'naguilian_road']),
            isRecommended: true,
            via: ['Leonard Wood Rd', 'Naguilian Road'],
          ),
          RouteOption(
            id: 'c', name: 'Route C – Bokawkan Road',
            duration: _liveDuration(11, ['bokawkan', 'naguilian_road']),
            distance: '2.7 km',
            trafficCondition: _worstLabelFor(['bokawkan', 'naguilian_road']),
            trafficColor: _worstColorFor(['bokawkan', 'naguilian_road']),
            via: ['Bokawkan Road', 'Naguilian Road', 'Aspinall Ave'],
          ),
        ];

      default:
        return [
          RouteOption(
            id: 'a', name: 'Route A – Session Road',
            duration: _liveDuration(28, ['session_road', 'gov_pack', 'harrison_road']),
            distance: '7.1 km',
            trafficCondition: _worstLabelFor(['session_road', 'gov_pack', 'harrison_road']),
            trafficColor: _worstColorFor(['session_road', 'gov_pack', 'harrison_road']),
            via: ['Session Road', 'Gov. Pack Road', 'Harrison Road'],
          ),
          RouteOption(
            id: 'b', name: 'Route B – Leonard Wood Rd',
            duration: _liveDuration(19, ['leonard_wood', 'camp_john_hay_rd']),
            distance: '6.3 km',
            trafficCondition: _worstLabelFor(['leonard_wood', 'camp_john_hay_rd']),
            trafficColor: _worstColorFor(['leonard_wood', 'camp_john_hay_rd']),
            isRecommended: true,
            via: ['Leonard Wood Rd', 'Military Cut-off', 'Outlook Drive'],
          ),
          RouteOption(
            id: 'c', name: 'Route C – Bokawkan Road',
            duration: _liveDuration(24, ['bokawkan', 'magsaysay', 'naguilian_road']),
            distance: '7.8 km',
            trafficCondition: _worstLabelFor(['bokawkan', 'magsaysay', 'naguilian_road']),
            trafficColor: _worstColorFor(['bokawkan', 'magsaysay', 'naguilian_road']),
            via: ['Bokawkan Road', 'Magsaysay Ave.', 'Naguilian Road'],
          ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Smart Route Suggestions',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2D3748),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Origin / Destination pickers
            _buildLocationPicker(),
            const SizedBox(height: 16),
            // Route comparison
            const Text(
              'Available Routes',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748)),
            ),
            const SizedBox(height: 4),
            const Text(
              'Tap a route to select it',
              style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
            ),
            const SizedBox(height: 12),
            ...List.generate(_routes.length, (i) => _buildRouteCard(i)),
            const SizedBox(height: 16),
            // Traffic Summary
            _buildTrafficSummary(),
            const SizedBox(height: 16),
            // Navigate CTA
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _selectedOrigin != null &&
                        _selectedDestination != null
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => NavigationScreen(
                              route: _routes[_selectedRoute],
                              origin: _selectedOrigin!,
                              destination: _selectedDestination!,
                            ),
                          ),
                        );
                      }
                    : null,
                icon: const Icon(Icons.navigation),
                label: const Text('Start Navigation'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFE5E7EB),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationPicker() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          // Origin
          Row(
            children: [
              const Icon(Icons.radio_button_checked,
                  color: Color(0xFF4CAF50), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedOrigin,
                    hint: const Text('Select starting point',
                        style: TextStyle(
                            color: Color(0xFF9CA3AF), fontSize: 13)),
                    items: _destinations
                        .map((d) => DropdownMenuItem(
                              value: d,
                              child: Text(d,
                                  style: const TextStyle(fontSize: 13)),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedOrigin = v),
                    isExpanded: true,
                  ),
                ),
              ),
            ],
          ),
          // Connector
          Padding(
            padding: const EdgeInsets.only(left: 9),
            child: Row(
              children: [
                Column(
                  children: List.generate(
                    4,
                    (_) => Container(
                      width: 2,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF9CA3AF),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Destination
          Row(
            children: [
              const Icon(Icons.location_on,
                  color: Color(0xFFE53935), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedDestination,
                    hint: const Text('Select destination',
                        style: TextStyle(
                            color: Color(0xFF9CA3AF), fontSize: 13)),
                    items: _destinations
                        .map((d) => DropdownMenuItem(
                              value: d,
                              child: Text(d,
                                  style: const TextStyle(fontSize: 13)),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedDestination = v),
                    isExpanded: true,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRouteCard(int index) {
    final route = _routes[index];
    final isSelected = _selectedRoute == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedRoute = index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? route.trafficColor.withValues(alpha: 0.06)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? route.trafficColor : const Color(0xFFE5E7EB),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ─────────────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                    color: route.trafficColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.route, color: route.trafficColor, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        route.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Color(0xFF2D3748)),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 2),
                      // Via roads – wrappable
                      Text(
                        'via ${route.via.join(' → ')}',
                        style: const TextStyle(
                            fontSize: 10, color: Color(0xFF9CA3AF)),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                // Badge column (recommended / selected)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (route.isRecommended)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('⭐ Best',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold)),
                      ),
                    if (isSelected && !route.isRecommended)
                      const Icon(Icons.check_circle,
                          color: Color(0xFF2196F3), size: 18),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 10),

            // ── Stats row ───────────────────────────────────────────────────
            Row(
              children: [
                // Duration chip
                _statChip(Icons.access_time, route.duration),
                const SizedBox(width: 6),
                // Distance chip
                _statChip(Icons.near_me, route.distance),
                const SizedBox(width: 6),
                // Traffic condition – flexible, text ellipsis
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: route.trafficColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle,
                            size: 7, color: route.trafficColor),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            route.trafficCondition,
                            style: TextStyle(
                                fontSize: 10,
                                color: route.trafficColor,
                                fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrafficSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Live Traffic Conditions',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748))),
              const Spacer(),
              // Live indicator dot
              if (_liveSegments.isNotEmpty) ...[
                Container(
                  width: 7, height: 7,
                  decoration: const BoxDecoration(
                    color: Color(0xFF4CAF50), shape: BoxShape.circle),
                ),
                const SizedBox(width: 4),
                const Text('LIVE',
                    style: TextStyle(
                        fontSize: 9,
                        color: Color(0xFF4CAF50),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5)),
              ],
            ],
          ),
          const SizedBox(height: 12),
          if (_liveSegments.isEmpty)
            // Loading state
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 14, height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Color(0xFF4CAF50)),
                  ),
                  SizedBox(width: 8),
                  Text('Loading live traffic…',
                      style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
                ],
              ),
            )
          else
            // All live road segments
            ...(_liveSegments.map((seg) => _trafficRow(
                  seg.name,
                  seg.label,
                  seg.color,
                ))),
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF6B7280)),
          const SizedBox(width: 3),
          Text(label,
              style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _trafficRow(String road, String status, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(road,
                style: const TextStyle(
                    fontSize: 13, color: Color(0xFF2D3748))),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(status,
                style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

