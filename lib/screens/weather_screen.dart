import 'package:flutter/material.dart';

class WeatherScreen extends StatelessWidget {
  const WeatherScreen({super.key});

  static const _hourlyForecast = [
    {'time': 'Now', 'icon': '☁️', 'temp': '18°', 'rain': '40%'},
    {'time': '2PM', 'icon': '🌧️', 'temp': '17°', 'rain': '75%'},
    {'time': '4PM', 'icon': '🌧️', 'temp': '16°', 'rain': '80%'},
    {'time': '6PM', 'icon': '🌦️', 'temp': '15°', 'rain': '50%'},
    {'time': '8PM', 'icon': '⛅', 'temp': '14°', 'rain': '20%'},
    {'time': '10PM', 'icon': '🌙', 'temp': '13°', 'rain': '10%'},
  ];

  static const _dailyForecast = [
    {'day': 'Today', 'icon': '🌧️', 'high': '20°', 'low': '13°', 'condition': 'Rainy'},
    {'day': 'Tomorrow', 'icon': '⛅', 'high': '21°', 'low': '14°', 'condition': 'Partly Cloudy'},
    {'day': 'Wed', 'icon': '☀️', 'high': '23°', 'low': '15°', 'condition': 'Sunny'},
    {'day': 'Thu', 'icon': '🌦️', 'high': '19°', 'low': '12°', 'condition': 'Showers'},
    {'day': 'Fri', 'icon': '🌧️', 'high': '18°', 'low': '12°', 'condition': 'Heavy Rain'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Weather & Driving Conditions',
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
            // Main weather card
            _buildMainWeatherCard(),
            const SizedBox(height: 16),
            // Driving alert
            _buildDrivingAlert(),
            const SizedBox(height: 16),
            // Hourly forecast
            _buildHourlyForecast(),
            const SizedBox(height: 16),
            // Daily forecast
            _buildDailyForecast(),
            const SizedBox(height: 16),
            // Weather stats
            _buildWeatherStats(),
            const SizedBox(height: 16),
            // Driving tips
            _buildDrivingTips(),
          ],
        ),
      ),
    );
  }

  Widget _buildMainWeatherCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1565C0).withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Baguio City',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  Text('Benguet, Philippines',
                      style: TextStyle(color: Colors.white60, fontSize: 12)),
                ],
              ),
              Text('PAGASA',
                  style: TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 20),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('🌧️', style: TextStyle(fontSize: 60)),
              SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('18°C',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 52,
                          fontWeight: FontWeight.bold,
                          height: 1.0)),
                  Text('Rainy / Foggy',
                      style: TextStyle(
                          color: Colors.white70, fontSize: 14)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white24),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _WeatherMiniStat(icon: '💧', value: '85%', label: 'Humidity'),
              _WeatherMiniStat(icon: '🌬️', value: '25 km/h', label: 'Wind'),
              _WeatherMiniStat(icon: '👁️', value: '3 km', label: 'Visibility'),
              _WeatherMiniStat(icon: '🌡️', value: '20°/13°', label: 'Hi/Lo'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDrivingAlert() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFF6F00).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFF6F00), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.directions_car, color: Color(0xFFFF6F00), size: 20),
              SizedBox(width: 8),
              Text('⚠️ Driving Alert',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFFFF6F00))),
            ],
          ),
          const SizedBox(height: 10),
          _alertRow('🌫️',
              'Dense fog expected in mountain roads – reduce speed'),
          _alertRow('🌧️', 'Slippery roads due to rain – use headlights'),
          _alertRow('🏔️',
              'Landslide risk in Kennon Road and Marcos Highway'),
          _alertRow('⚡', 'Thunderstorm warning from 2PM–6PM today'),
        ],
      ),
    );
  }

  Widget _buildHourlyForecast() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Hourly Forecast',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748))),
        const SizedBox(height: 10),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _hourlyForecast.length,
            itemBuilder: (_, i) {
              final h = _hourlyForecast[i];
              return Container(
                width: 72,
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: i == 0
                      ? const Color(0xFF2196F3).withValues(alpha: 0.1)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: i == 0
                        ? const Color(0xFF2196F3)
                        : const Color(0xFFE5E7EB),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text(h['time']!,
                        style: TextStyle(
                            fontSize: 11,
                            color: i == 0
                                ? const Color(0xFF2196F3)
                                : const Color(0xFF9CA3AF))),
                    Text(h['icon']!,
                        style: const TextStyle(fontSize: 22)),
                    Text(h['temp']!,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3748))),
                    Text(h['rain']!,
                        style: const TextStyle(
                            fontSize: 10, color: Color(0xFF2196F3))),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDailyForecast() {
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
          const Text('5-Day Forecast',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748))),
          const SizedBox(height: 12),
          ..._dailyForecast.map((d) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    SizedBox(
                        width: 60,
                        child: Text(d['day']!,
                            style: const TextStyle(
                                fontSize: 13, color: Color(0xFF6B7280)))),
                    Text(d['icon']!,
                        style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(d['condition']!,
                          style: const TextStyle(
                              fontSize: 13, color: Color(0xFF2D3748))),
                    ),
                    Text('${d['low']!} - ${d['high']!}',
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF6B7280))),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildWeatherStats() {
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
          const Text('Detailed Conditions',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748))),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _statCard('🌡️', 'Feels Like', '15°C',
                    const Color(0xFF2196F3)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _statCard('🌧️', 'Rain Chance', '75%',
                    const Color(0xFF1565C0)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _statCard(
                    '☁️', 'Cloud Cover', '90%', const Color(0xFF607D8B)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _statCard('💦', 'Dew Point', '14°C',
                    const Color(0xFF00BCD4)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDrivingTips() {
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
          const Row(
            children: [
              Icon(Icons.tips_and_updates, color: Color(0xFF4CAF50)),
              SizedBox(width: 8),
              Text('Rainy Weather Driving Tips',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748))),
            ],
          ),
          const SizedBox(height: 12),
          _tipRow('Reduce speed to 30–40 km/h on mountain roads'),
          _tipRow('Turn on headlights in fog and heavy rain'),
          _tipRow('Maintain larger following distance on wet roads'),
          _tipRow('Avoid Kennon Road during heavy rain – risk of landslide'),
          _tipRow('Check PAGASA updates before starting your trip'),
        ],
      ),
    );
  }

  Widget _alertRow(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF2D3748),
                    height: 1.4)),
          ),
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

  Widget _statCard(
      String emoji, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 10, color: Color(0xFF9CA3AF))),
              Text(value,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color)),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeatherMiniStat extends StatelessWidget {
  final String icon;
  final String value;
  final String label;

  const _WeatherMiniStat(
      {required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold)),
        Text(label,
            style:
                const TextStyle(color: Colors.white54, fontSize: 9)),
      ],
    );
  }
}

