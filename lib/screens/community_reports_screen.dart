import 'package:flutter/material.dart';
import '../models/models.dart';

class CommunityReportsScreen extends StatefulWidget {
  const CommunityReportsScreen({super.key});

  @override
  State<CommunityReportsScreen> createState() =>
      _CommunityReportsScreenState();
}

class _CommunityReportsScreenState extends State<CommunityReportsScreen> {
  final List<CommunityReport> _reports = [
    CommunityReport(
      id: '1',
      type: 'Traffic Jam',
      location: 'Session Road near Jollibee',
      description: 'Very heavy traffic, barely moving. Avoid if possible.',
      upvotes: 24,
      timeAgo: '5 mins ago',
      reporterName: 'Tourist A.',
      color: const Color(0xFFE53935),
      icon: Icons.traffic,
    ),
    CommunityReport(
      id: '2',
      type: 'Accident',
      location: 'Bokawkan Road, near Baguio Cathedral',
      description: 'Minor fender-bender, police on scene. Left lane blocked.',
      upvotes: 18,
      timeAgo: '12 mins ago',
      reporterName: 'Local Driver',
      color: const Color(0xFFE53935),
      icon: Icons.car_crash,
    ),
    CommunityReport(
      id: '3',
      type: 'Road Hazard',
      location: 'Kennon Road near Zig-Zag',
      description: 'Large pothole in the right lane. Drive carefully.',
      upvotes: 9,
      timeAgo: '30 mins ago',
      reporterName: 'Visitor B.',
      color: const Color(0xFFFFA726),
      icon: Icons.warning_amber_rounded,
    ),
    CommunityReport(
      id: '4',
      type: 'Road Closure',
      location: 'Leonard Wood Road, near Wright Park',
      description: 'Road closed for repair. Use Magsaysay Ave as alternative.',
      upvotes: 31,
      timeAgo: '1 hr ago',
      reporterName: 'Community Watch',
      color: const Color(0xFFE53935),
      icon: Icons.block,
    ),
    CommunityReport(
      id: '5',
      type: 'Traffic Cleared',
      location: 'Gov. Pack Road',
      description:
          'Traffic has eased up. Road is now flowing smoothly again.',
      upvotes: 12,
      timeAgo: '45 mins ago',
      reporterName: 'User C.',
      color: const Color(0xFF4CAF50),
      icon: Icons.check_circle,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Community Reports',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2D3748),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showReportDialog,
        icon: const Icon(Icons.add_alert),
        label: const Text('Report Issue'),
        backgroundColor: const Color(0xFF9C27B0),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Header info
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF9C27B0), Color(0xFFAB47BC)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.people, color: Colors.white, size: 32),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Community Traffic Reports',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(
                        '${_reports.length} active reports from tourists & locals',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.trending_up,
                    color: Colors.white70, size: 22),
              ],
            ),
          ),
          // Reports list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              itemCount: _reports.length,
              itemBuilder: (_, i) => _buildReportCard(_reports[i], i),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(CommunityReport report, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: report.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                    Icon(report.icon, color: report.color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(report.type,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: report.color)),
                    Text(report.location,
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF9CA3AF))),
                  ],
                ),
              ),
              Text(report.timeAgo,
                  style: const TextStyle(
                      fontSize: 10, color: Color(0xFF9CA3AF))),
            ],
          ),
          const SizedBox(height: 10),
          Text(report.description,
              style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF2D3748),
                  height: 1.4)),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.person_outline,
                  size: 13, color: Color(0xFF9CA3AF)),
              const SizedBox(width: 3),
              Text(report.reporterName,
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFF9CA3AF))),
              const Spacer(),
              // Upvote button
              GestureDetector(
                onTap: () {
                  setState(() => _reports[index] = CommunityReport(
                        id: report.id,
                        type: report.type,
                        location: report.location,
                        description: report.description,
                        upvotes: report.upvotes + 1,
                        timeAgo: report.timeAgo,
                        reporterName: report.reporterName,
                        color: report.color,
                        icon: report.icon,
                      ));
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF9C27B0).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.thumb_up_outlined,
                          size: 13, color: Color(0xFF9C27B0)),
                      const SizedBox(width: 4),
                      Text('${report.upvotes}',
                          style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF9C27B0),
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showReportDialog() {
    String selectedType = 'Traffic Jam';
    final locationCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              left: 16,
              right: 16,
              top: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.add_alert, color: Color(0xFF9C27B0)),
                    const SizedBox(width: 8),
                    const Text('Report a Road Issue',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3748))),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text('Issue Type',
                    style: TextStyle(
                        fontSize: 12, color: Color(0xFF6B7280))),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                  items: [
                    'Traffic Jam',
                    'Accident',
                    'Road Hazard',
                    'Road Closure',
                    'Traffic Cleared',
                    'Landslide',
                    'Flooding',
                  ]
                      .map((t) =>
                          DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) =>
                      setModalState(() => selectedType = v ?? selectedType),
                ),
                const SizedBox(height: 12),
                const Text('Location',
                    style: TextStyle(
                        fontSize: 12, color: Color(0xFF6B7280))),
                const SizedBox(height: 6),
                TextField(
                  controller: locationCtrl,
                  decoration: InputDecoration(
                    hintText: 'e.g. Session Road near SM',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Description',
                    style: TextStyle(
                        fontSize: 12, color: Color(0xFF6B7280))),
                const SizedBox(height: 6),
                TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Describe the road condition...',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (locationCtrl.text.isNotEmpty) {
                        setState(() {
                          _reports.insert(
                            0,
                            CommunityReport(
                              id: DateTime.now()
                                  .millisecondsSinceEpoch
                                  .toString(),
                              type: selectedType,
                              location: locationCtrl.text,
                              description: descCtrl.text.isEmpty
                                  ? 'No description provided.'
                                  : descCtrl.text,
                              upvotes: 0,
                              timeAgo: 'Just now',
                              reporterName: 'You',
                              color: selectedType == 'Traffic Cleared'
                                  ? const Color(0xFF4CAF50)
                                  : selectedType == 'Traffic Jam' ||
                                          selectedType == 'Accident' ||
                                          selectedType == 'Road Closure'
                                      ? const Color(0xFFE53935)
                                      : const Color(0xFFFFA726),
                              icon: selectedType == 'Traffic Jam'
                                  ? Icons.traffic
                                  : selectedType == 'Accident'
                                      ? Icons.car_crash
                                      : selectedType == 'Traffic Cleared'
                                          ? Icons.check_circle
                                          : selectedType == 'Road Closure'
                                              ? Icons.block
                                              : Icons.warning_amber_rounded,
                            ),
                          );
                        });
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✅ Report submitted! Thank you.'),
                            backgroundColor: Color(0xFF4CAF50),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.send),
                    label: const Text('Submit Report'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9C27B0),
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
        });
      },
    );
  }
}

