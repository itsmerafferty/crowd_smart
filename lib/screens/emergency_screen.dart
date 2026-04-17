import 'package:flutter/material.dart';
import '../models/models.dart';

class EmergencyScreen extends StatelessWidget {
  const EmergencyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Emergency Assistance',
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
            // SOS Button
            _buildSOSButton(context),
            const SizedBox(height: 20),
            // Emergency numbers
            const Text(
              'Nearby Emergency Services',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748)),
            ),
            const SizedBox(height: 4),
            const Text('Baguio City',
                style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
            const SizedBox(height: 14),
            ...AppData.emergencyServices.map((s) => _buildServiceCard(context, s)),
            const SizedBox(height: 16),
            // Safety tips
            _buildSafetyCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildSOSButton(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.emergency, color: Color(0xFFE53935)),
                SizedBox(width: 8),
                Text('SOS Alert'),
              ],
            ),
            content: const Text(
              'This will send your current location to emergency services and your emergency contact.\n\nAre you sure?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('🚨 SOS SENT! Help is on the way.'),
                      backgroundColor: Color(0xFFE53935),
                      duration: Duration(seconds: 4),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE53935),
                  foregroundColor: Colors.white,
                ),
                child: const Text('SEND SOS'),
              ),
            ],
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFE53935), Color(0xFFB71C1C)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE53935).withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: const Icon(Icons.sos, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 12),
            const Text(
              'HOLD FOR SOS',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2),
            ),
            const SizedBox(height: 4),
            const Text(
              'Long press to activate emergency alert',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard(BuildContext context, EmergencyService service) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: service.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(service.icon, color: service.color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(service.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF2D3748))),
                const SizedBox(height: 2),
                Text(service.address,
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF9CA3AF))),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.near_me,
                        size: 11, color: Color(0xFF9CA3AF)),
                    const SizedBox(width: 3),
                    Text(service.distance,
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF9CA3AF))),
                  ],
                ),
              ],
            ),
          ),
          // Call button
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Calling ${service.name}...'),
                  backgroundColor: service.color,
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: service.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.phone, color: service.color, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF4CAF50).withValues(alpha: 0.4)),
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
          const Row(
            children: [
              Icon(Icons.health_and_safety, color: Color(0xFF4CAF50)),
              SizedBox(width: 8),
              Text('Tourist Safety Tips',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748))),
            ],
          ),
          const SizedBox(height: 12),
          _tipRow('Save emergency numbers in your phone before traveling'),
          _tipRow('Share your itinerary with family or friends'),
          _tipRow('Carry a physical map in case of signal loss'),
          _tipRow('Stay on designated tourist paths'),
          _tipRow('Register with DOT tourist assistance center'),
          _tipRow('Keep hydrated – altitude in Baguio can cause AMS'),
        ],
      ),
    );
  }

  Widget _tipRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 5),
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Color(0xFF4CAF50),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                    height: 1.5)),
          ),
        ],
      ),
    );
  }
}

