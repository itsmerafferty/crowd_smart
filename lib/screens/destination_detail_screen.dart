import 'package:flutter/material.dart';
import '../models/models.dart';
import 'route_suggestion_screen.dart';
import 'community_reports_screen.dart';
import 'panorama_screen.dart';

class DestinationDetailScreen extends StatefulWidget {
  final TouristLocation location;

  const DestinationDetailScreen({super.key, required this.location});

  @override
  State<DestinationDetailScreen> createState() =>
      _DestinationDetailScreenState();
}

class _DestinationDetailScreenState extends State<DestinationDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  TouristLocation get loc => widget.location;

  static const List<Map<String, dynamic>> _barData = [
    {'time': '6AM', 'val': 0.15},
    {'time': '8AM', 'val': 0.3},
    {'time': '10AM', 'val': 0.55},
    {'time': '12PM', 'val': 0.90},
    {'time': '2PM', 'val': 0.95},
    {'time': '4PM', 'val': 0.70},
    {'time': '6PM', 'val': 0.45},
    {'time': '8PM', 'val': 0.20},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: NestedScrollView(
        headerSliverBuilder: (ctx, inner) => [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: loc.statusColor,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      loc.statusColor,
                      loc.statusColor.withValues(alpha: 0.7),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 60),
                    Text(loc.emoji, style: const TextStyle(fontSize: 72)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        loc.category,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              isScrollable: true,
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Crowd & Times'),
                Tab(text: '360° View'),
                Tab(text: 'Navigate'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildOverviewTab(),
            _buildCrowdTab(),
            _build360Tab(),
            _buildNavigateTab(),
          ],
        ),
      ),
    );
  }

  // ── Overview Tab ──────────────────────────────────────────────────────────
  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name + rating
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  loc.name,
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748)),
                ),
              ),
              Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.star,
                          size: 18, color: Color(0xFFFFA726)),
                      const SizedBox(width: 3),
                      Text(
                        loc.rating.toString(),
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3748)),
                      ),
                    ],
                  ),
                  const Text('Rating',
                      style:
                          TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Quick info row
          _infoChip(Icons.access_time, loc.travelTime, const Color(0xFF2196F3)),
          const SizedBox(width: 8),
          _infoChip(Icons.near_me, loc.distance, const Color(0xFF4CAF50)),
          const SizedBox(height: 16),
          // Hours and best time
          _infoCard(
            child: Row(
              children: [
                Expanded(
                  child: _infoItem(
                    Icons.schedule,
                    'Open Hours',
                    loc.openHours,
                    const Color(0xFF2196F3),
                  ),
                ),
                Container(
                    height: 50,
                    width: 1,
                    color: const Color(0xFFE5E7EB)),
                const SizedBox(width: 12),
                Expanded(
                  child: _infoItem(
                    Icons.wb_sunny,
                    'Best Time',
                    loc.bestTime,
                    const Color(0xFFFFA726),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Description
          _infoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'About This Place',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748)),
                ),
                const SizedBox(height: 10),
                Text(
                  loc.description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // 360° View Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => PanoramaScreen(location: loc)),
              ),
              icon: const Icon(Icons.threesixty, size: 20),
              label: const Text('View 360° Panorama'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black87,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Report button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const CommunityReportsScreen()),
              ),
              icon: const Icon(Icons.report_problem_outlined),
              label: const Text('Report a Road Issue Here'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF9C27B0),
                side: const BorderSide(color: Color(0xFF9C27B0)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Crowd Tab ─────────────────────────────────────────────────────────────
  Widget _buildCrowdTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Current crowd card
          Container(
            padding: const EdgeInsets.all(20),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.people, color: loc.statusColor),
                    const SizedBox(width: 8),
                    const Text('Current Crowd Density',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3748))),
                  ],
                ),
                const SizedBox(height: 16),
                // Gradient bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    height: 12,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF4CAF50),
                          Color(0xFFFFA726),
                          Color(0xFFE53935),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Low',
                        style:
                            TextStyle(fontSize: 11, color: Color(0xFF4CAF50))),
                    Text('Moderate',
                        style: TextStyle(
                            fontSize: 11, color: Color(0xFFFFA726))),
                    Text('High',
                        style: TextStyle(
                            fontSize: 11, color: Color(0xFFE53935))),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: loc.statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: loc.statusColor, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Current status: ${loc.crowdStatus} crowd density',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: loc.statusColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Peak hours chart
          Container(
            padding: const EdgeInsets.all(20),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.bar_chart, color: Color(0xFF2196F3)),
                    SizedBox(width: 8),
                    Text('Peak Hour Prediction',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3748))),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 130,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: _barData
                        .map((d) => _barChartItem(
                              d['time'] as String,
                              d['val'] as double,
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Best time banner
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.wb_sunny, color: Colors.white, size: 36),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Best Time to Visit',
                        style: TextStyle(
                            color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 2),
                    Text(loc.bestTime,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 360° View Tab ─────────────────────────────────────────────────────────
  Widget _build360Tab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Hero launch card
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => PanoramaScreen(location: loc)),
            ),
            child: Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.black87, loc.statusColor.withValues(alpha: 0.8)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Background emoji
                  Positioned(
                    right: 20,
                    bottom: 10,
                    child: Text(loc.emoji,
                        style: TextStyle(
                            fontSize: 90,
                            color: Colors.white.withValues(alpha: 0.15))),
                  ),
                  // Content
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white54, width: 2),
                        ),
                        child: const Icon(Icons.threesixty,
                            color: Colors.white, size: 36),
                      ),
                      const SizedBox(height: 14),
                      const Text('360° Virtual Tour',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.touch_app,
                                color: Colors.white70, size: 13),
                            SizedBox(width: 5),
                            Text('Tap to explore',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // How to use card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 3)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.help_outline, color: Color(0xFF2196F3), size: 18),
                    SizedBox(width: 8),
                    Text('How to use 360° View',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3748))),
                  ],
                ),
                const SizedBox(height: 12),
                _how360Row('👆', 'Drag finger', 'Pan and look around in all directions'),
                _how360Row('🤏', 'Pinch', 'Zoom in and out'),
                _how360Row('📱', 'Rotate device', 'Switch to landscape for wider view'),
                _how360Row('⚡', 'Tap speed', 'Toggle 1x / 2x pan sensitivity'),
                _how360Row('👁️', 'Tap screen', 'Show / hide controls overlay'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Place info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 3)),
              ],
            ),
            child: Row(
              children: [
                Text(loc.emoji, style: const TextStyle(fontSize: 36)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(loc.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Color(0xFF2D3748))),
                      const SizedBox(height: 4),
                      Text(loc.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                              height: 1.4)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Full launch button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => PanoramaScreen(location: loc)),
              ),
              icon: const Icon(Icons.threesixty, size: 22),
              label: const Text('Launch 360° Panorama',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black87,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _how360Row(String emoji, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Color(0xFF2D3748))),
                Text(desc,
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF9CA3AF))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Navigate Tab ──────────────────────────────────────────────────────────
  Widget _buildNavigateTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Route options
          _infoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Available Routes',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748)),
                ),
                const SizedBox(height: 4),
                Text('To: ${loc.name}',
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF9CA3AF))),
                const SizedBox(height: 14),
                _routeOption('Route A', loc.travelTime, 'Heavy Traffic',
                    const Color(0xFFE53935), false),
                const SizedBox(height: 10),
                _routeOption('Route B', _getFasterTime(loc.travelTime),
                    'Light Traffic', const Color(0xFF4CAF50), true),
                const SizedBox(height: 10),
                _routeOption('Route C', _getMedTime(loc.travelTime),
                    'Moderate Traffic', const Color(0xFFFFA726), false),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const RouteSuggestionScreen()),
              ),
              icon: const Icon(Icons.alt_route),
              label: const Text('View Detailed Route Suggestions'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  Widget _infoCard({required Widget child}) {
    return Container(
      width: double.infinity,
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
      child: child,
    );
  }

  Widget _infoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 12, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _infoItem(IconData icon, String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: Color(0xFF9CA3AF))),
          ],
        ),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3748))),
      ],
    );
  }

  Widget _barChartItem(String label, double value) {
    final Color barColor = value < 0.5
        ? const Color(0xFF4CAF50)
        : value < 0.75
            ? const Color(0xFFFFA726)
            : const Color(0xFFE53935);
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 28,
          height: value * 110,
          decoration: BoxDecoration(
            color: barColor,
            borderRadius: BorderRadius.circular(5),
          ),
        ),
        const SizedBox(height: 6),
        Text(label,
            style: const TextStyle(fontSize: 9, color: Color(0xFF6B7280))),
      ],
    );
  }

  Widget _routeOption(String name, String duration, String traffic,
      Color trafficColor, bool recommended) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: recommended
            ? const Color(0xFF4CAF50).withValues(alpha: 0.06)
            : const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: recommended
              ? const Color(0xFF4CAF50)
              : const Color(0xFFE5E7EB),
          width: recommended ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.route, color: trafficColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Color(0xFF2D3748))),
                Text(traffic,
                    style:
                        TextStyle(fontSize: 11, color: trafficColor)),
              ],
            ),
          ),
          Text(duration,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF2D3748))),
          if (recommended) ...[
            const SizedBox(width: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('Best',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ],
      ),
    );
  }

  String _getFasterTime(String travelTime) {
    try {
      final mins = int.parse(travelTime.replaceAll(RegExp(r'[^0-9]'), ''));
      final faster = (mins * 0.65).round();
      return '$faster mins';
    } catch (_) {
      return travelTime;
    }
  }

  String _getMedTime(String travelTime) {
    try {
      final mins = int.parse(travelTime.replaceAll(RegExp(r'[^0-9]'), ''));
      final med = (mins * 0.85).round();
      return '$med mins';
    } catch (_) {
      return travelTime;
    }
  }
}

