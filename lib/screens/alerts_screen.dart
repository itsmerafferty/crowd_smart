import 'package:flutter/material.dart';
import '../models/models.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  String _filterSeverity = 'All';

  List<RoadIncident> get _filtered {
    if (_filterSeverity == 'All') return AppData.incidents;
    return AppData.incidents
        .where((i) => i.severity == _filterSeverity)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final highCount =
        AppData.incidents.where((i) => i.severity == 'High').length;
    final modCount =
        AppData.incidents.where((i) => i.severity == 'Moderate').length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Road Alerts',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2D3748),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Summary
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE53935), Color(0xFFEF5350)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: Colors.white, size: 36),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Active Road Alerts',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15)),
                      const SizedBox(height: 2),
                      Text(
                        '$highCount High · $modCount Moderate',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${AppData.incidents.length} Total',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          // Filter chips
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: ['All', 'High', 'Moderate'].map((label) {
                final selected = _filterSeverity == label;
                final color = label == 'High'
                    ? const Color(0xFFE53935)
                    : label == 'Moderate'
                        ? const Color(0xFFFFA726)
                        : const Color(0xFF2196F3);
                return GestureDetector(
                  onTap: () =>
                      setState(() => _filterSeverity = label),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected
                          ? color
                          : color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color:
                              selected ? Colors.white : color),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          // Incidents list
          Expanded(
            child: _filtered.isEmpty
                ? const Center(
                    child: Text('No alerts found',
                        style: TextStyle(color: Color(0xFF9CA3AF))),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: _filtered.length,
                    itemBuilder: (_, i) => _buildIncidentCard(_filtered[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncidentCard(RoadIncident incident) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border(
          left: BorderSide(
            color: incident.severityColor,
            width: 4,
          ),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: incident.severityColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(incident.icon,
                    color: incident.severityColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(incident.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF2D3748))),
                    const SizedBox(height: 2),
                    Text(incident.location,
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF9CA3AF))),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color:
                          incident.severityColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(incident.severity,
                        style: TextStyle(
                            fontSize: 10,
                            color: incident.severityColor,
                            fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 4),
                  Text(incident.timeAgo,
                      style: const TextStyle(
                          fontSize: 10, color: Color(0xFF9CA3AF))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _typeChip(incident.type),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Alternative route shown for: ${incident.location}'),
                      backgroundColor: const Color(0xFF4CAF50),
                    ),
                  );
                },
                icon: const Icon(Icons.alt_route, size: 14),
                label: const Text('Alt Route'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF2196F3),
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _typeChip(String type) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Text(type,
          style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
    );
  }
}

