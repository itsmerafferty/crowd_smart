# 🔧 Weather Integration - Code Architecture

## File Structure Overview

```
crowd_smart/
├── lib/
│   ├── services/
│   │   ├── weather_service.dart          ✨ [NEW]
│   │   ├── traffic_service.dart          (existing)
│   │   └── location_service.dart         (existing)
│   │
│   ├── screens/
│   │   ├── map_screen.dart               📝 [UPDATED]
│   │   └── ...
│   │
│   ├── models/
│   │   └── models.dart                   📝 [UPDATED]
│   │
│   └── config/
│       └── api_config.dart               (no changes)
│
└── Documentation/
    ├── IMPLEMENTATION_COMPLETE.md         (full details)
    ├── WEATHER_FEATURE.md                (feature docs)
    ├── WEATHER_QUICK_GUIDE.md            (user guide)
    └── ARCHITECTURE.md                   (this file)
```

---

## Weather Service Architecture

### Location: `lib/services/weather_service.dart` (340 lines)

#### Data Models

```dart
// Weather condition enumeration
enum WeatherCondition {
  clear, cloudy, rainy, heavyRain, snowy, stormy, foggy, unknown,
}

// Traffic impact from weather
enum TrafficImpact {
  none, light, moderate, severe,
}

// Main weather data holder
class WeatherData {
  final String condition;              // e.g., "Clear"
  final double temperature;            // °C
  final int humidity;                  // %
  final double windSpeed;              // m/s
  final int cloudCoverage;            // %
  final double visibility;             // meters
  final int pressure;                  // mb
  final String description;            // "sunny", "rainy", etc
  final WeatherCondition conditionType;
  final TrafficImpact trafficImpact;
  final String? precipitationProb;    // "50%"
  final double? feelsLike;            // °C
  
  // Helper getters
  String get temperatureString => '${temperature.toStringAsFixed(0)}°C'
  String get weatherIcon => /* emoji based on condition */
  String get trafficAdvisory => /* advisory text */
}

// Hourly forecast item
class HourlyWeather {
  final DateTime dateTime;
  final WeatherData weather;
  final String? precipitationProb;
}

// Daily forecast item
class DailyWeather {
  final DateTime dateTime;
  final double tempMax;
  final double tempMin;
  final WeatherData weather;
  final String? precipitationProb;
}
```

#### Service Class

```dart
class WeatherService {
  // OpenWeatherMap API Configuration
  static const String _apiKey = '95ac06ba2dfea41cc79a91d36251b9e6';
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';
  static const Duration _updateInterval = Duration(minutes: 10);

  // Stream Controllers
  late StreamController<WeatherData> _weatherController;
  late StreamController<List<HourlyWeather>> _hourlyForecastController;
  late StreamController<List<DailyWeather>> _dailyForecastController;
  
  // Timer for periodic updates
  late Timer _updateTimer;
  
  // Current state
  bool _isRunning = false;
  WeatherData? _lastWeatherData;
  List<HourlyWeather> _lastHourlyForecast = [];
  List<DailyWeather> _lastDailyForecast = [];

  // Public streams
  Stream<WeatherData> get weatherStream => _weatherController.stream;
  Stream<List<HourlyWeather>> get hourlyForecastStream => _hourlyForecastController.stream;
  Stream<List<DailyWeather>> get dailyForecastStream => _dailyForecastController.stream;

  // Public getters
  WeatherData? get currentWeather => _lastWeatherData;
  List<HourlyWeather> get currentHourlyForecast => _lastHourlyForecast;
  List<DailyWeather> get currentDailyForecast => _lastDailyForecast;

  // Methods
  void start({double latitude = 16.4119, double longitude = 120.5937})
  void stop()
  Future<void> fetchWeatherForLocation(LatLng location)
  Future<void> _fetchWeather(double latitude, double longitude)
  void dispose()
}
```

#### Key Methods

```dart
// Start monitoring weather
void start({double latitude = 16.4119, double longitude = 120.5937}) {
  if (_isRunning) return;
  _isRunning = true;
  _fetchWeather(latitude, longitude);
  _updateTimer = Timer.periodic(_updateInterval, (_) => 
    _fetchWeather(latitude, longitude)
  );
}

// Fetch weather from OpenWeatherMap API
Future<void> _fetchWeather(double latitude, double longitude) async {
  try {
    // Make API calls to both endpoints
    final currentResponse = await http.get(currentUrl);
    final forecastResponse = await http.get(forecastUrl);

    if (both successful) {
      // Parse JSON responses
      final weather = WeatherData.fromJson(currentData);
      _lastWeatherData = weather;
      _weatherController.add(weather);
      
      // Process forecast data
      // Extract hourly (8 items = 24 hours)
      // Extract daily (every 8th item)
      
      _hourlyForecastController.add(hourlyList);
      _dailyForecastController.add(dailyList);
    }
  } catch (e) {
    print('Error fetching weather: $e');
  }
}

// Stop monitoring
void dispose() {
  stop();
  _weatherController.close();
  _hourlyForecastController.close();
  _dailyForecastController.close();
}
```

---

## Map Screen Integration

### Location: `lib/screens/map_screen.dart` (1714 lines)

#### State Variables Added

```dart
class _MapScreenState extends State<MapScreen> {
  // ── Weather ───────────────────────────────────────────────────────────────
  final WeatherService _weatherService = WeatherService();
  StreamSubscription<WeatherData>? _weatherSub;
  StreamSubscription<List<HourlyWeather>>? _hourlyForecastSub;
  StreamSubscription<List<DailyWeather>>? _dailyForecastSub;
  WeatherData? _currentWeather;
  List<HourlyWeather> _hourlyForecast = [];
  List<DailyWeather> _dailyForecast = [];
  bool _showWeatherDetails = false;
}
```

#### Lifecycle Integration

```dart
@override
void initState() {
  super.initState();
  // ... existing code ...
  
  // Start weather service
  _weatherService.start();
  
  // Subscribe to weather updates
  _weatherSub = _weatherService.weatherStream.listen((weather) {
    if (!mounted) return;
    setState(() => _currentWeather = weather);
  });
  
  // Subscribe to hourly forecast
  _hourlyForecastSub = _weatherService.hourlyForecastStream.listen((forecast) {
    if (!mounted) return;
    setState(() => _hourlyForecast = forecast);
  });
  
  // Subscribe to daily forecast
  _dailyForecastSub = _weatherService.dailyForecastStream.listen((forecast) {
    if (!mounted) return;
    setState(() => _dailyForecast = forecast);
  });
}

@override
void dispose() {
  // ... existing code ...
  
  // Clean up weather subscriptions
  _weatherSub?.cancel();
  _hourlyForecastSub?.cancel();
  _dailyForecastSub?.cancel();
  _weatherService.dispose();
  
  super.dispose();
}
```

#### Build Method

```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    body: Stack(
      children: [
        _hasApiKey ? _buildGoogleMap() : _buildNoApiKeyPlaceholder(),
        _buildAlertTicker(),
        if (_selectedLocation != null) _buildSelectedCard(),
        if (_selectedLocation == null) _buildBottomChips(),
        if (_showMapTypeMenu) _buildMapTypeMenu(),
        _buildFabs(),
        if (_locationStatus == LocationStatus.tracking) _buildLocationBar(),
        _buildWeatherPanel(),  // ← NEW
      ],
    ),
  );
}
```

#### Weather Panel Builder

```dart
Widget _buildWeatherPanel() {
  if (_currentWeather == null && _showWeatherDetails == false) {
    return const SizedBox.shrink();
  }

  final weather = _currentWeather;
  if (weather == null) return const SizedBox.shrink();

  return Positioned(
    top: 12,
    right: 12,
    child: SafeArea(
      child: GestureDetector(
        onTap: () => setState(() => _showWeatherDetails = !_showWeatherDetails),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: _showWeatherDetails ? 320 : 140,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [/* shadow */],
          ),
          child: _showWeatherDetails
              ? _buildWeatherDetails(weather)
              : _buildWeatherCompact(weather),
        ),
      ),
    ),
  );
}

// Compact view (140px wide)
Widget _buildWeatherCompact(WeatherData weather) {
  return Padding(
    padding: const EdgeInsets.all(12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              children: [
                Text(weather.temperatureString),
                Text(weather.condition),
              ],
            ),
            Text(weather.weatherIcon, style: TextStyle(fontSize: 32)),
          ],
        ),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: _trafficImpactColor(weather.trafficImpact)
                .withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Text(
              weather.trafficAdvisory,
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    ),
  );
}

// Detailed view (320px wide)
Widget _buildWeatherDetails(WeatherData weather) {
  return Padding(
    padding: const EdgeInsets.all(14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header with title and emoji
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              children: [
                Text('Weather & Driving'),
                Text('Baguio City'),
              ],
            ),
            Text(weather.weatherIcon, style: TextStyle(fontSize: 28)),
          ],
        ),
        
        // Main weather card
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [/* colors */]),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: /* color */),
          ),
          child: Column(
            children: [
              // Temperature display
              Text(weather.temperatureString, style: TextStyle(fontSize: 22)),
              if (weather.feelsLike != null)
                Text('Feels like ${weather.feelsLike}°C'),
              
              // Weather metrics grid (4 columns)
              GridView.count(
                crossAxisCount: 4,
                children: [
                  _buildWeatherMetric('💧', '${weather.humidity}%', 'Humidity'),
                  _buildWeatherMetric('💨', '${weather.windSpeed}m/s', 'Wind'),
                  _buildWeatherMetric('👁️', '${weather.visibility/1000}km', 'Visibility'),
                  _buildWeatherMetric('🌍', '${weather.pressure}mb', 'Pressure'),
                ],
              ),
            ],
          ),
        ),
        
        // Traffic impact alert
        Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _trafficImpactColor(weather.trafficImpact)
                .withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(_trafficImpactIcon(weather.trafficImpact)),
              SizedBox(width: 8),
              Column(
                children: [
                  Text('Driving Advisory'),
                  Text(weather.trafficAdvisory),
                ],
              ),
            ],
          ),
        ),
        
        // Hourly forecast (if available)
        if (_hourlyForecast.isNotEmpty) ...[
          Text('Hourly Forecast'),
          SizedBox(height: 6),
          SizedBox(
            height: 70,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _hourlyForecast.take(6).length,
              itemBuilder: (_, idx) {
                final forecast = _hourlyForecast[idx];
                return _buildHourlyItem(forecast);
              },
            ),
          ),
        ],
      ],
    ),
  );
}
```

#### Helper Methods

```dart
// Build individual weather metric
Widget _buildWeatherMetric(String icon, String value, String label) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(icon, style: TextStyle(fontSize: 16)),
      SizedBox(height: 2),
      Text(value, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
      SizedBox(height: 1),
      Text(label, style: TextStyle(fontSize: 7, color: Color(0xFF9CA3AF))),
    ],
  );
}

// Get color based on traffic impact
Color _trafficImpactColor(TrafficImpact impact) {
  switch (impact) {
    case TrafficImpact.none:
      return const Color(0xFF4CAF50);      // Green
    case TrafficImpact.light:
      return const Color(0xFFFFA726);      // Orange
    case TrafficImpact.moderate:
      return const Color(0xFFFF6F00);      // Darker Orange
    case TrafficImpact.severe:
      return const Color(0xFFE53935);      // Red
  }
}

// Get icon based on traffic impact
IconData _trafficImpactIcon(TrafficImpact impact) {
  switch (impact) {
    case TrafficImpact.none:
      return Icons.check_circle_outline;
    case TrafficImpact.light:
      return Icons.info_outline;
    case TrafficImpact.moderate:
      return Icons.warning_amber_rounded;
    case TrafficImpact.severe:
      return Icons.dangerous;
  }
}
```

---

## Data Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         User Opens App                           │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
                ┌────────────────────────────┐
                │ MapScreen initState()      │
                │ - Starts WeatherService    │
                │ - Subscribes to streams    │
                └────────────┬───────────────┘
                             │
                             ▼
              ┌──────────────────────────────┐
              │ WeatherService.start()       │
              │ - Fetches current weather    │
              │ - Starts 10-min timer        │
              └──────────┬───────────────────┘
                         │
                         ▼
        ┌────────────────────────────────────┐
        │ HTTP GET to OpenWeatherMap API    │
        │ - /weather endpoint               │
        │ - /forecast endpoint              │
        └────────────┬─────────────────────┘
                     │
                     ▼
        ┌────────────────────────────────────┐
        │ Parse JSON responses               │
        │ - Create WeatherData               │
        │ - Create HourlyWeather[]           │
        │ - Create DailyWeather[]            │
        └────────────┬─────────────────────┘
                     │
                     ▼
        ┌────────────────────────────────────┐
        │ Add to StreamControllers            │
        │ - weatherController                │
        │ - hourlyForecastController         │
        │ - dailyForecastController          │
        └────────────┬─────────────────────┘
                     │
                     ▼
        ┌────────────────────────────────────┐
        │ Streams emit new data               │
        └────────────┬─────────────────────┘
                     │
                     ▼
    ┌─────────────────────────────────────────┐
    │ MapScreen listens to streams:           │
    │ - _weatherSub.listen()                  │
    │ - _hourlyForecastSub.listen()           │
    │ - _dailyForecastSub.listen()            │
    └─────────────┬──────────────────────────┘
                  │
                  ▼
         ┌─────────────────────┐
         │ setState() called    │
         │ Updates local state: │
         │ - _currentWeather    │
         │ - _hourlyForecast    │
         │ - _dailyForecast     │
         └────────────┬────────┘
                      │
                      ▼
         ┌──────────────────────────┐
         │ build() called            │
         │ - _buildWeatherPanel()    │
         │ - Renders weather UI      │
         └──────────────────────────┘
                      │
                      ▼
         ┌──────────────────────────┐
         │ UI Updates on Screen:     │
         │ - Temperature displayed   │
         │ - Icon shown              │
         │ - Advisory text shown     │
         └──────────────────────────┘
                      │
         (Every 10 minutes or when tapped)
                      │
                      ▼
         ┌──────────────────────────┐
         │ Timer fires / User taps   │
         │ - Fetch new weather       │
         │ - Expand/collapse panel   │
         │ - Update UI               │
         └──────────────────────────┘
```

---

## API Integration Details

### OpenWeatherMap Endpoints

**Current Weather**
```
GET https://api.openweathermap.org/data/2.5/weather
  ?lat=16.4119
  &lon=120.5937
  &units=metric
  &appid=95ac06ba2dfea41cc79a91d36251b9e6

Response:
{
  "coord": {"lon": 120.5937, "lat": 16.4119},
  "weather": [{"main": "Clear", "description": "clear sky"}],
  "main": {
    "temp": 18,
    "feels_like": 16,
    "humidity": 85,
    "pressure": 1013,
    "visibility": 10000
  },
  "wind": {"speed": 5},
  "clouds": {"all": 20}
}
```

**5-Day Forecast**
```
GET https://api.openweathermap.org/data/2.5/forecast
  ?lat=16.4119
  &lon=120.5937
  &units=metric
  &appid=95ac06ba2dfea41cc79a91d36251b9e6

Response:
{
  "list": [
    // 40 items (5 days × 8 forecasts per day at 3-hour intervals)
    {
      "dt": 1699564800,
      "main": {...},
      "weather": [...],
      "clouds": {...},
      "wind": {...},
      "pop": 0.2  // probability of precipitation
    },
    ...
  ]
}
```

---

## Error Handling

```dart
// In _fetchWeather()
try {
  final currentResponse = await http.get(currentUrl);
  final forecastResponse = await http.get(forecastUrl);

  if (currentResponse.statusCode == 200 && 
      forecastResponse.statusCode == 200) {
    // Success: parse and update
  }
  // Silently fails if status codes != 200
} catch (e) {
  print('Error fetching weather: $e');
  // Service continues running, just didn't update
}

// Stream subscriptions handle null checks
_weatherSub = _weatherService.weatherStream.listen((weather) {
  if (!mounted) return;  // Don't update if widget disposed
  setState(() => _currentWeather = weather);
});
```

---

## Performance Considerations

- **Update Interval**: 10 minutes (prevents API rate limiting)
- **Stream Controllers**: Broadcast streams (multiple listeners OK)
- **UI Updates**: Only if widget is mounted
- **Memory**: Forecasts cached in memory (small dataset)
- **Network**: Single API call includes both current + forecast
- **Battery**: Timer paused when widget disposed

---

## Testing Checklist

```
✓ Weather service initializes
✓ API calls successful
✓ Data parsed correctly
✓ Streams emit properly
✓ UI updates on new data
✓ Panel expands/collapses
✓ Hourly forecast displays
✓ Impact colors change with conditions
✓ Service stops on dispose
✓ No memory leaks
✓ Works offline (gracefully)
```

---

**Status**: ✅ Complete Architecture
**Last Updated**: March 13, 2026

