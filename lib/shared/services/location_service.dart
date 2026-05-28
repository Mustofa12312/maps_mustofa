import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../../core/constants/app_constants.dart';

class LocationService extends ChangeNotifier {
  Position? _currentPosition;
  bool _isTracking = false;
  String _error = '';
  double _heading = 0;
  double _speed = 0;

  Position? get currentPosition => _currentPosition;
  bool get isTracking => _isTracking;
  String get error => _error;
  double get heading => _heading;
  double get speed => _speed;
  double get speedKmh => _speed * 3.6;

  LocationModel? get currentLocationModel {
    if (_currentPosition == null) return null;
    return LocationModel(
      latitude: _currentPosition!.latitude,
      longitude: _currentPosition!.longitude,
      name: 'Lokasi Saya',
    );
  }

  Future<bool> requestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _error = 'Layanan GPS tidak aktif';
      notifyListeners();
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _error = 'Izin lokasi ditolak';
        notifyListeners();
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _error = 'Izin lokasi ditolak permanen';
      notifyListeners();
      return false;
    }

    return true;
  }

  Future<Position?> getCurrentPosition() async {
    try {
      final hasPermission = await requestPermission();
      if (!hasPermission) return null;

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      _currentPosition = position;
      notifyListeners();
      return position;
    } catch (e) {
      _error = 'Gagal mendapatkan lokasi: $e';
      notifyListeners();
      return null;
    }
  }

  void startTracking() {
    if (_isTracking) return;
    _isTracking = true;

    final locationSettings = AndroidSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: AppConstants.locationDistanceFilterM.round(),
      intervalDuration: const Duration(
        milliseconds: AppConstants.locationUpdateIntervalMs,
      ),
    );

    Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position position) {
      _currentPosition = position;
      _speed = position.speed;
      if (position.heading >= 0) {
        _heading = position.heading;
      }
      notifyListeners();
    }, onError: (e) {
      _error = 'Error GPS: $e';
      notifyListeners();
    });
  }

  void stopTracking() {
    _isTracking = false;
    notifyListeners();
  }

  /// Calculate distance between two points in kilometers
  static double calculateDistance(
    double lat1, double lng1, double lat2, double lng2,
  ) {
    const r = 6371.0; // Earth radius km
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRad(lat1)) *
            math.cos(_toRad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }

  static double _toRad(double deg) => deg * math.pi / 180;
}
