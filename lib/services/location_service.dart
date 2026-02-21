import 'dart:async';
import 'dart:math';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationService {
  StreamController<LatLng>? _locationController;
  Timer? _locationTimer;
  LatLng _currentLocation = const LatLng(18.5204, 73.8567); // Default Pune coordinates

  Stream<LatLng> get locationStream {
    _locationController ??= StreamController<LatLng>.broadcast();
    return _locationController!.stream;
  }

  void startTracking() {
    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      // Mock slight movement
      double lat = _currentLocation.latitude + (Random().nextDouble() - 0.5) * 0.0001;
      double lng = _currentLocation.longitude + (Random().nextDouble() - 0.5) * 0.0001;
      _currentLocation = LatLng(lat, lng);
      _locationController?.add(_currentLocation);
    });
  }

  void stopTracking() {
    _locationTimer?.cancel();
    _locationTimer = null;
  }

  LatLng get currentLocation => _currentLocation;

  void dispose() {
    stopTracking();
    _locationController?.close();
  }
}
