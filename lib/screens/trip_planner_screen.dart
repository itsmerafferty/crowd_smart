import 'package:flutter/material.dart';
import '../models/models.dart';

class TripPlannerScreen extends StatefulWidget {
  const TripPlannerScreen({super.key});

  @override
  State<TripPlannerScreen> createState() => _TripPlannerScreenState();
}

class _TripPlannerScreenState extends State<TripPlannerScreen> {
  final List<TripStop> _stops = [];
  bool _isOptimized = false;

  int get _totalMinutes {
    if (_stops.isEmpty) return 0;
    return _stops.fold(0, (sum, s) => sum + s.estimatedMinutes) +
        (_stops.length - 1) * 10; // 10 min transit between stops
  }

  String get _totalTime {
    final mins = _totalMinutes;
    if (mins < 60) return '${mins}m';
    return '${mins ~/ 60}h ${mins % 60}m';
  }

  void _addStop(TouristLocation loc) {
    if (_stops.any((s) => s.location.id == loc.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${loc.name} is already in your trip!'),
          backgroundColor: const Color(0xFFFFA726),
        ),
      );
      return;
    }
    setState(() {
      _stops.add(TripStop(
        location: loc,
        scheduledTime: _getNextTime(),
        estimatedMinutes: 60,
      ));
      _isOptimized = false;
    });
  }

  String _getNextTime() {
    if (_stops.isEmpty) return '8:00 AM';
    final times = ['8:00 AM', '10:00 AM', '12:00 PM', '2:00 PM', '4:00 PM', '6:00 PM'];
    return times[_stops.length % times.length];
  }

  void _removeStop(int index) {
    setState(() {
      _stops.removeAt(index);
      _isOptimized = false;
    });
  }

  void _reorderStop(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final stop = _stops.removeAt(oldIndex);
      _stops.insert(newIndex, stop);
      _isOptimized = false;
    });
  }

  void _optimizeRoute() {
    if (_stops.length < 2) return;
    setState(() {
      // Sort by crowd status: Low first, then Moderate, then High
      final order = {'Low': 0, 'Moderate': 1, 'High': 2};
      _stops.sort((a, b) =>
          (order[a.location.crowdStatus] ?? 1)
              .compareTo(order[b.location.crowdStatus] ?? 1));
      // Reassign times
      final times = ['8:00 AM', '10:00 AM', '12:00 PM', '2:00 PM', '4:00 PM', '6:00 PM'];
      for (int i = 0; i < _stops.length; i++) {
        _stops[i].scheduledTime = times[i % times.length];
      }
      _isOptimized = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
            '✅ Route optimized! Arranged to minimize traffic & crowd.'),
        backgroundColor: Color(0xFF4CAF50),
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.calendar_today,
                          color: Color(0xFF2196F3), size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Trip Planner',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3748)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Build and optimize your Baguio itinerary',
                    style:
                        TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                  ),
                  if (_stops.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _summaryChip(Icons.place,
                            '${_stops.length} stops', const Color(0xFF2196F3)),
                        const SizedBox(width: 8),
                        _summaryChip(Icons.access_time, _totalTime,
                            const Color(0xFF4CAF50)),
                        if (_isOptimized) ...[
                          const SizedBox(width: 8),
                          _summaryChip(Icons.check_circle,
                              'Optimized', const Color(0xFF4CAF50)),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // Body
            Expanded(
              child: _stops.isEmpty
                  ? _buildEmptyState()
                  : _buildItinerary(),
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_stops.length >= 2)
            FloatingActionButton.extended(
              onPressed: _optimizeRoute,
              heroTag: 'optimize',
              backgroundColor: const Color(0xFF2196F3),
              icon: const Icon(Icons.auto_fix_high),
              label: const Text('Optimize Route'),
            ),
          if (_stops.length >= 2) const SizedBox(height: 10),
          FloatingActionButton(
            onPressed: _showAddStopDialog,
            heroTag: 'add',
            backgroundColor: const Color(0xFF4CAF50),
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFF2196F3).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add_location_alt,
                size: 48, color: Color(0xFF2196F3)),
          ),
          const SizedBox(height: 16),
          const Text(
            'Plan Your Baguio Trip',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748)),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Add destinations to build your itinerary. We\'ll optimize the route to minimize travel time and avoid crowds.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF), height: 1.5),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddStopDialog,
            icon: const Icon(Icons.add),
            label: const Text('Add Your First Stop'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItinerary() {
    return Column(
      children: [
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            itemCount: _stops.length,
            onReorder: _reorderStop,
            itemBuilder: (ctx, index) {
              final stop = _stops[index];
              return _buildStopCard(stop, index, key: ValueKey(stop.location.id));
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStopCard(TripStop stop, int index, {required Key key}) {
    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 10),
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
        children: [
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            leading: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: stop.location.statusColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: stop.location.statusColor),
                    ),
                  ),
                ),
              ],
            ),
            title: Text(
              stop.location.name,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF2D3748)),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.schedule,
                        size: 12, color: const Color(0xFF9CA3AF)),
                    const SizedBox(width: 3),
                    Text(stop.scheduledTime,
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF6B7280))),
                    const SizedBox(width: 8),
                    Icon(Icons.people,
                        size: 12, color: stop.location.statusColor),
                    const SizedBox(width: 3),
                    Text(stop.location.crowdStatus,
                        style: TextStyle(
                            fontSize: 11,
                            color: stop.location.statusColor,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(stop.location.emoji,
                    style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.close,
                      size: 18, color: Color(0xFF9CA3AF)),
                  onPressed: () => _removeStop(index),
                ),
              ],
            ),
          ),
          // Duration slider
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
            child: Row(
              children: [
                const Icon(Icons.hourglass_bottom,
                    size: 14, color: Color(0xFF9CA3AF)),
                Expanded(
                  child: Slider(
                    value: stop.estimatedMinutes.toDouble(),
                    min: 30,
                    max: 180,
                    divisions: 10,
                    activeColor: stop.location.statusColor,
                    label: '${stop.estimatedMinutes} mins',
                    onChanged: (v) {
                      setState(() => stop.estimatedMinutes = v.round());
                    },
                  ),
                ),
                SizedBox(
                  width: 60,
                  child: Text(
                    '${stop.estimatedMinutes} mins',
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF6B7280)),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
          // Connector line (except last)
        ],
      ),
    );
  }

  void _showAddStopDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          expand: false,
          builder: (__, scrollCtrl) => Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Add a Stop',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748)),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: AppData.locations.length,
                  itemBuilder: (ctx, i) {
                    final loc = AppData.locations[i];
                    final alreadyAdded =
                        _stops.any((s) => s.location.id == loc.id);
                    return ListTile(
                      leading: Text(loc.emoji,
                          style: const TextStyle(fontSize: 28)),
                      title: Text(loc.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2D3748))),
                      subtitle: Row(
                        children: [
                          Icon(Icons.people,
                              size: 12, color: loc.statusColor),
                          const SizedBox(width: 3),
                          Text(loc.crowdStatus,
                              style: TextStyle(
                                  fontSize: 11, color: loc.statusColor)),
                          const SizedBox(width: 8),
                          const Icon(Icons.access_time,
                              size: 12, color: Color(0xFF9CA3AF)),
                          const SizedBox(width: 3),
                          Text(loc.travelTime,
                              style: const TextStyle(
                                  fontSize: 11, color: Color(0xFF9CA3AF))),
                        ],
                      ),
                      trailing: alreadyAdded
                          ? const Icon(Icons.check_circle,
                              color: Color(0xFF4CAF50))
                          : IconButton(
                              icon: const Icon(Icons.add_circle_outline,
                                  color: Color(0xFF2196F3)),
                              onPressed: () {
                                _addStop(loc);
                                Navigator.pop(context);
                              },
                            ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _summaryChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}


