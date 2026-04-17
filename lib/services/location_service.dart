import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

enum LocationStatus { idle, loading, tracking, denied, disabled, error }

class LocationService {
  static const LocationSettings _settings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 5, // update every 5 metres
  );

  final _positionController = StreamController<LatLng>.broadcast();
  final _statusController = StreamController<LocationStatus>.broadcast();

  Stream<LatLng> get positionStream => _positionController.stream;
  Stream<LocationStatus> get statusStream => _statusController.stream;

  LatLng? _currentPosition;
  double? _currentHeading;
  LocationStatus _status = LocationStatus.idle;
  StreamSubscription<Position>? _positionSub;

  LatLng? get currentPosition => _currentPosition;
  double? get currentHeading => _currentHeading;
  LocationStatus get status => _status;
  bool get isTracking => _status == LocationStatus.tracking;

  /// Request permission and start live location updates
  Future<void> startTracking() async {
    _emit(LocationStatus.loading);

    // Check if location services are enabled
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _emit(LocationStatus.disabled);
      return;
    }

    // Check / request permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _emit(LocationStatus.denied);
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      _emit(LocationStatus.denied);
      return;
    }

    // Get initial position fast
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      _updatePosition(pos);
      _emit(LocationStatus.tracking);
    } catch (_) {
      _emit(LocationStatus.error);
      return;
    }

    // Start continuous stream
    _positionSub = Geolocator.getPositionStream(locationSettings: _settings)
        .listen(
      _updatePosition,
      onError: (_) => _emit(LocationStatus.error),
    );
  }

  void stopTracking() {
    _positionSub?.cancel();
    _positionSub = null;
    _emit(LocationStatus.idle);
  }

  void dispose() {
    stopTracking();
    _positionController.close();
    _statusController.close();
  }

  void _updatePosition(Position pos) {
    _currentPosition = LatLng(pos.latitude, pos.longitude);
    _currentHeading = pos.heading;
    _positionController.add(_currentPosition!);
  }

  void _emit(LocationStatus s) {
    _status = s;
    _statusController.add(s);
  }
}

