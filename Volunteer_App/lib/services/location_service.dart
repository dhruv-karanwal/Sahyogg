import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LocationService {
  StreamController<LatLng>? _locationController;
  StreamSubscription<Position>? _positionStream;
  LatLng _currentLocation = const LatLng(0.0, 0.0);
  final String _volunteerId = 'vol_001'; // Default ID for now
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<LatLng> get locationStream {
    _locationController ??= StreamController<LatLng>.broadcast();
    return _locationController!.stream;
  }

  Future<void> startTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    _positionStream?.cancel();
    
    // Config for continuous GPS tracking
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 10, // Update every 10 meters of movement
    );

    _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings).listen((Position position) {
      _currentLocation = LatLng(position.latitude, position.longitude);
      _locationController?.add(_currentLocation);
      
      // Sync LIVE location to Firebase Admin Command Center
      _syncLocationToFirebase(_currentLocation);
    });
  }

  Future<void> _syncLocationToFirebase(LatLng loc) async {
    try {
      await _db
        .collection('Disasters')
        .doc('Flood')
        .collection('active_volunteers')
        .doc(_volunteerId)
        .set({
          'lat': loc.latitude,
          'lng': loc.longitude,
          'lastUpdate': FieldValue.serverTimestamp(),
          'status': 'active'
        }, SetOptions(merge: true));
    } catch (e) {
      print('Error syncing location: $e');
    }
  }

  void stopTracking() {
    _positionStream?.cancel();
    _positionStream = null;
  }

  LatLng get currentLocation => _currentLocation;

  void dispose() {
    stopTracking();
    _locationController?.close();
  }
}
