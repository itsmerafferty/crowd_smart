import 'package:flutter/material.dart';
import '../models/models.dart';
import '../widgets/location_card.dart';
import 'map_screen.dart';
import 'destination_detail_screen.dart';
import 'trip_planner_screen.dart';
import 'parking_screen.dart';
import 'alerts_screen.dart';
import 'community_reports_screen.dart';
import 'weather_screen.dart';
import 'emergency_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  List<TouristLocation> get _filteredLocations {
    if (_searchQuery.isEmpty) return AppData.locations;
    return AppData.locations
        .where((loc) =>
            loc.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            loc.category.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            loc.description.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeTab();
      case 1:
        return const MapScreen();
      case 2:
        return const TripPlannerScreen();
      case 3:
        return _buildMoreTab();
      default:
        return _buildHomeTab();
    }
  }

  Widget _buildHomeTab() {
    return SafeArea(
      child: Column(
        children: [
          // Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Logo and title
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4CAF50), Color(0xFF2196F3)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.location_on, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CrowdSmart',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3748),
                          ),
                        ),
                        Text(
                          'Baguio City Navigator',
                          style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Weather badge
                    GestureDetector(
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const WeatherScreen())),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2196F3).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.cloud, color: Color(0xFF2196F3), size: 16),
                            SizedBox(width: 4),
                            Text('18°C',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF2196F3))),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Alert badge
                    GestureDetector(
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const AlertsScreen())),
                      child: Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE53935).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.notifications_active,
                                color: Color(0xFFE53935), size: 22),
                          ),
                          Positioned(
                            right: 4,
                            top: 4,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFFE53935),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Search Bar
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F7FA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Search tourist spots in Baguio...',
                      hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF9CA3AF)),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Color(0xFF9CA3AF)),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                // Quick Action Buttons
                SizedBox(
                  height: 80,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildQuickAction(Icons.map, 'Live Map', const Color(0xFF2196F3),
                          () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const MapScreen()))),
                      _buildQuickAction(Icons.route, 'Routes', const Color(0xFF4CAF50),
                          () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const MapScreen()))),
                      _buildQuickAction(
                          Icons.local_parking, 'Parking', const Color(0xFFFFA726),
                          () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const ParkingScreen()))),
                      _buildQuickAction(Icons.warning_amber_rounded, 'Alerts',
                          const Color(0xFFE53935),
                          () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const AlertsScreen()))),
                      _buildQuickAction(Icons.people, 'Reports', const Color(0xFF9C27B0),
                          () => Navigator.push(context,
                              MaterialPageRoute(
                                  builder: (_) => const CommunityReportsScreen()))),
                      _buildQuickAction(Icons.emergency, 'SOS', const Color(0xFFE53935),
                          () => Navigator.push(context,
                              MaterialPageRoute(
                                  builder: (_) => const EmergencyScreen()))),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
          // Content
          Expanded(
            child: _filteredLocations.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off, size: 64, color: Color(0xFF9CA3AF)),
                        const SizedBox(height: 12),
                        Text(
                          'No results for "$_searchQuery"',
                          style: const TextStyle(color: Color(0xFF6B7280)),
                        ),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    children: [
                      // Traffic Alert Banner
                      _buildTrafficAlertBanner(),
                      const SizedBox(height: 16),
                      // Section Title
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _searchQuery.isEmpty
                                ? 'Tourist Destinations'
                                : 'Search Results (${_filteredLocations.length})',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D3748),
                            ),
                          ),
                          if (_searchQuery.isEmpty)
                            TextButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.filter_list, size: 16),
                              label: const Text('Filter'),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF6B7280),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Location Cards
                      ..._filteredLocations.map(
                        (loc) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: LocationCard(
                            location: loc,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    DestinationDetailScreen(location: loc),
                              ),
                            ),
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

  Widget _buildQuickAction(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 68,
        margin: const EdgeInsets.only(right: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrafficAlertBanner() {
    return GestureDetector(
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => const AlertsScreen())),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFE53935), Color(0xFFEF5350)],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE53935).withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '2 active road alerts nearby',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
                  ),
                  Text(
                    'Session Road: Heavy traffic · Kennon: Construction',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildMoreTab() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            const Text(
              'More Features',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748)),
            ),
            const SizedBox(height: 4),
            const Text('All CrowdSmart tools',
                style: TextStyle(color: Color(0xFF9CA3AF))),
            const SizedBox(height: 20),
            _buildMoreItem(Icons.local_parking, 'Parking Finder',
                'Find available parking near tourist spots', const Color(0xFFFFA726),
                () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ParkingScreen()))),
            _buildMoreItem(Icons.warning_amber_rounded, 'Road Alerts',
                'Traffic incidents and road closures', const Color(0xFFE53935),
                () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const AlertsScreen()))),
            _buildMoreItem(Icons.people, 'Community Reports',
                'Waze-like user traffic reports', const Color(0xFF9C27B0),
                () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const CommunityReportsScreen()))),
            _buildMoreItem(Icons.cloud, 'Weather & Fog Alerts',
                'PAGASA weather info for drivers', const Color(0xFF2196F3),
                () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const WeatherScreen()))),
            _buildMoreItem(Icons.emergency, 'Emergency Assistance',
                'Police, hospitals, SOS button', const Color(0xFFE53935),
                () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const EmergencyScreen()))),
            _buildMoreItem(Icons.map, 'Live Traffic Map',
                'Real-time traffic visualization', const Color(0xFF4CAF50),
                () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const MapScreen()))),
            _buildMoreItem(Icons.calendar_month, 'Trip Planner',
                'Build and optimize your itinerary', const Color(0xFF00BCD4),
                () {
              setState(() => _currentIndex = 2);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildMoreItem(
      IconData icon, String title, String subtitle, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF2D3748))),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF9CA3AF))),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF9CA3AF)),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: _currentIndex,
      selectedItemColor: const Color(0xFF4CAF50),
      unselectedItemColor: const Color(0xFF9CA3AF),
      selectedLabelStyle:
          const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
      onTap: (i) => setState(() => _currentIndex = i),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
        BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today), label: 'Trip Planner'),
        BottomNavigationBarItem(icon: Icon(Icons.menu), label: 'More'),
      ],
    );
  }
}

