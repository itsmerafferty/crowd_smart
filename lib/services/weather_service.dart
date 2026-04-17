// CrowdSmart – Weather Service
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';

// ─────────────────────────────────────────────────────────────────────────────
// WEATHER DATA MODELS
// ─────────────────────────────────────────────────────────────────────────────

enum WeatherCondition {
  clear,
  cloudy,
  rainy,
  heavyRain,
  snowy,
  stormy,
  foggy,
  unknown,
}

enum TrafficImpact {
  none,
  light,
  moderate,
  severe,
}

class WeatherData {
  final String condition;
  final double temperature;
  final int humidity;
  final double windSpeed;
  final int cloudCoverage;
  final double visibility;
  final int pressure;
  final String description;
  final WeatherCondition conditionType;
  final TrafficImpact trafficImpact;
  final String? precipitationProb;
  final double? feelsLike;

  WeatherData({
    required this.condition,
    required this.temperature,
    required this.humidity,
    required this.windSpeed,
    required this.cloudCoverage,
    required this.visibility,
    required this.pressure,
    required this.description,
    required this.conditionType,
    required this.trafficImpact,
    this.precipitationProb,
    this.feelsLike,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    final main = json['main'] as Map<String, dynamic>? ?? {};
    final clouds = json['clouds'] as Map<String, dynamic>? ?? {};
    final wind = json['wind'] as Map<String, dynamic>? ?? {};
    final weatherList = (json['weather'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    final condition = weatherList.isNotEmpty ? weatherList[0]['main'] as String? ?? 'Unknown' : 'Unknown';
    final description = weatherList.isNotEmpty ? weatherList[0]['description'] as String? ?? '' : '';
    final temperature = (main['temp'] as num?)?.toDouble() ?? 0.0;
    final humidity = (main['humidity'] as num?)?.toInt() ?? 0;
    final windSpeed = (wind['speed'] as num?)?.toDouble() ?? 0.0;
    final cloudCoverage = (clouds['all'] as num?)?.toInt() ?? 0;
    final visibility = (json['visibility'] as num?)?.toDouble() ?? 10000.0;
    final pressure = (main['pressure'] as num?)?.toInt() ?? 1013;
    final feelsLike = (main['feels_like'] as num?)?.toDouble();
    final precipitationProb = json['pop'] != null ? '${(json['pop'] as num) * 100}%' : null;

    final conditionType = _parseCondition(condition);
    final trafficImpact = _calculateTrafficImpact(condition, humidity, windSpeed, visibility, temperature);

    return WeatherData(
      condition: condition,
      temperature: temperature,
      humidity: humidity,
      windSpeed: windSpeed,
      cloudCoverage: cloudCoverage,
      visibility: visibility,
      pressure: pressure,
      description: description,
      conditionType: conditionType,
      trafficImpact: trafficImpact,
      precipitationProb: precipitationProb,
      feelsLike: feelsLike,
    );
  }

  static WeatherCondition _parseCondition(String condition) {
    final lower = condition.toLowerCase();
    if (lower.contains('clear') || lower.contains('sunny')) return WeatherCondition.clear;
    if (lower.contains('cloud')) return WeatherCondition.cloudy;
    if (lower.contains('rain')) {
      return lower.contains('heavy') || lower.contains('thunderstorm')
          ? WeatherCondition.heavyRain
          : WeatherCondition.rainy;
    }
    if (lower.contains('snow')) return WeatherCondition.snowy;
    if (lower.contains('storm') || lower.contains('thunder')) return WeatherCondition.stormy;
    if (lower.contains('fog') || lower.contains('mist')) return WeatherCondition.foggy;
    return WeatherCondition.unknown;
  }

  static TrafficImpact _calculateTrafficImpact(
    String condition,
    int humidity,
    double windSpeed,
    double visibility,
    double temperature,
  ) {
    final lower = condition.toLowerCase();

    // Severe impact: heavy rain, thunderstorms, heavy snow
    if (lower.contains('heavy') || lower.contains('thunder') || lower.contains('storm')) {
      return TrafficImpact.severe;
    }

    // Moderate impact: rain, snow, fog, low visibility
    if (lower.contains('rain') || lower.contains('snow') || lower.contains('fog') || lower.contains('mist')) {
      if (visibility < 1000) return TrafficImpact.severe;
      if (visibility < 5000) return TrafficImpact.moderate;
      return TrafficImpact.light;
    }

    // Check visibility
    if (visibility < 500) return TrafficImpact.severe;
    if (visibility < 2000) return TrafficImpact.moderate;

    // Check wind
    if (windSpeed > 15) return TrafficImpact.severe;
    if (windSpeed > 10) return TrafficImpact.moderate;

    // Check temperature extremes (icy conditions, extreme heat)
    if (temperature < 0) return TrafficImpact.light; // Potential ice
    if (temperature > 40) return TrafficImpact.light; // Extreme heat affecting visibility/brakes

    return TrafficImpact.none;
  }

  String get weatherIcon {
    switch (conditionType) {
      case WeatherCondition.clear:
        return '☀️';
      case WeatherCondition.cloudy:
        return '☁️';
      case WeatherCondition.rainy:
        return '🌧️';
      case WeatherCondition.heavyRain:
        return '⛈️';
      case WeatherCondition.snowy:
        return '❄️';
      case WeatherCondition.stormy:
        return '⛈️';
      case WeatherCondition.foggy:
        return '🌫️';
      case WeatherCondition.unknown:
        return '🌤️';
    }
  }

  String get trafficAdvisory {
    switch (trafficImpact) {
      case TrafficImpact.none:
        return 'Clear driving conditions';
      case TrafficImpact.light:
        return 'Slight weather impact on traffic';
      case TrafficImpact.moderate:
        return 'Moderate weather impact - use caution';
      case TrafficImpact.severe:
        return 'Severe weather - exercise extreme caution';
    }
  }

  String get temperatureString => '${temperature.toStringAsFixed(0)}°C';
}

class HourlyWeather {
  final DateTime dateTime;
  final WeatherData weather;
  final String? precipitationProb;

  HourlyWeather({
    required this.dateTime,
    required this.weather,
    this.precipitationProb,
  });

  factory HourlyWeather.fromJson(Map<String, dynamic> json) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch((json['dt'] as int?) ?? 0, isUtc: true);
    final weather = WeatherData.fromJson(json);
    final precipProb = json['pop'] != null ? '${((json['pop'] as num) * 100).toInt()}%' : null;

    return HourlyWeather(
      dateTime: dateTime,
      weather: weather,
      precipitationProb: precipProb,
    );
  }
}

class DailyWeather {
  final DateTime dateTime;
  final double tempMax;
  final double tempMin;
  final WeatherData weather;
  final String? precipitationProb;

  DailyWeather({
    required this.dateTime,
    required this.tempMax,
    required this.tempMin,
    required this.weather,
    this.precipitationProb,
  });

  factory DailyWeather.fromJson(Map<String, dynamic> json) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch((json['dt'] as int?) ?? 0, isUtc: true);
    final temp = json['temp'] as Map<String, dynamic>? ?? {};
    final tempMax = (temp['max'] as num?)?.toDouble() ?? 0.0;
    final tempMin = (temp['min'] as num?)?.toDouble() ?? 0.0;
    final weather = WeatherData.fromJson(json);
    final precipProb = json['pop'] != null ? '${((json['pop'] as num) * 100).toInt()}%' : null;

    return DailyWeather(
      dateTime: dateTime,
      tempMax: tempMax,
      tempMin: tempMin,
      weather: weather,
      precipitationProb: precipProb,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WEATHER SERVICE
// ─────────────────────────────────────────────────────────────────────────────

class WeatherService {
  static const String _apiKey = '95ac06ba2dfea41cc79a91d36251b9e6'; // OpenWeatherMap API
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';
  static const Duration _updateInterval = Duration(minutes: 10);

  late StreamController<WeatherData> _weatherController;
  late StreamController<List<HourlyWeather>> _hourlyForecastController;
  late StreamController<List<DailyWeather>> _dailyForecastController;
  late Timer _updateTimer;

  bool _isRunning = false;
  WeatherData? _lastWeatherData;
  List<HourlyWeather> _lastHourlyForecast = [];
  List<DailyWeather> _lastDailyForecast = [];

  WeatherService() {
    _weatherController = StreamController<WeatherData>.broadcast();
    _hourlyForecastController = StreamController<List<HourlyWeather>>.broadcast();
    _dailyForecastController = StreamController<List<DailyWeather>>.broadcast();
  }

  Stream<WeatherData> get weatherStream => _weatherController.stream;
  Stream<List<HourlyWeather>> get hourlyForecastStream => _hourlyForecastController.stream;
  Stream<List<DailyWeather>> get dailyForecastStream => _dailyForecastController.stream;

  WeatherData? get currentWeather => _lastWeatherData;
  List<HourlyWeather> get currentHourlyForecast => _lastHourlyForecast;
  List<DailyWeather> get currentDailyForecast => _lastDailyForecast;

  /// Start weather updates for Baguio City
  void start({double latitude = 16.4119, double longitude = 120.5937}) {
    if (_isRunning) return;
    _isRunning = true;
    _fetchWeather(latitude, longitude);
    _updateTimer = Timer.periodic(_updateInterval, (_) => _fetchWeather(latitude, longitude));
  }

  /// Stop weather updates
  void stop() {
    _isRunning = false;
    _updateTimer.cancel();
  }

  /// Fetch weather for specific location
  Future<void> fetchWeatherForLocation(LatLng location) async {
    await _fetchWeather(location.latitude, location.longitude);
  }

  Future<void> _fetchWeather(double latitude, double longitude) async {
    try {
      final currentUrl = Uri.parse(
        '$_baseUrl/weather?lat=$latitude&lon=$longitude&units=metric&appid=$_apiKey',
      );
      final forecastUrl = Uri.parse(
        '$_baseUrl/forecast?lat=$latitude&lon=$longitude&units=metric&appid=$_apiKey',
      );

      final currentResponse = await http.get(currentUrl);
      final forecastResponse = await http.get(forecastUrl);

      if (currentResponse.statusCode == 200 && forecastResponse.statusCode == 200) {
        final currentData = jsonDecode(currentResponse.body) as Map<String, dynamic>;
        final forecastData = jsonDecode(forecastResponse.body) as Map<String, dynamic>;

        final weather = WeatherData.fromJson(currentData);
        _lastWeatherData = weather;
        _weatherController.add(weather);

        // Process 5-day forecast (forecast endpoint gives 40 items at 3-hour intervals)
        final forecastList = (forecastData['list'] as List? ?? []).cast<Map<String, dynamic>>();

        // Extract hourly forecast (first 24 hours = 8 items)
        final hourlyList = forecastList.take(8).map((item) => HourlyWeather.fromJson(item)).toList();
        _lastHourlyForecast = hourlyList;
        _hourlyForecastController.add(hourlyList);

        // Extract daily forecast (get one from each day - indices 7, 15, 23, 31, 39)
        final dailyList = <DailyWeather>[];
        for (var i = 7; i < forecastList.length; i += 8) {
          dailyList.add(DailyWeather.fromJson(forecastList[i]));
        }
        _lastDailyForecast = dailyList;
        _dailyForecastController.add(dailyList);
      }
    } catch (e) {
      print('Error fetching weather: $e');
    }
  }

  void dispose() {
    stop();
    _weatherController.close();
    _hourlyForecastController.close();
    _dailyForecastController.close();
  }
}

