import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:user_gdg/widgets/live_advisory_banner.dart';
import 'package:user_gdg/widgets/sos_dialog.dart';
import 'package:user_gdg/services/google_vision_service.dart';
import 'package:user_gdg/services/nlp_triage_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:user_gdg/advisory_screen.dart'; // Missing import
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:user_gdg/providers/locale_provider.dart';

class FloodMapScreen extends StatefulWidget {
  final LatLng? targetLocation;
  final String disasterType; // Added dynamic disaster type

  const FloodMapScreen({super.key, this.targetLocation, required this.disasterType});

  @override
  State<FloodMapScreen> createState() => _FloodMapScreenState();
}

class _FloodMapScreenState extends State<FloodMapScreen>
    with SingleTickerProviderStateMixin {
  GoogleMapController? _mapController;

  Set<Polygon> _polygons = {};
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  
  String _selectedLayer = '';
  bool _isLoading = false;
  bool _isLoadingRoute = false;

  // User Location
  LatLng? _userLocation;
  StreamSubscription<Position>? _positionStream;
  StreamSubscription? _safeZoneSubscription;

  // FAB Animation
  late AnimationController _fabAnimationController;
  late Animation<double> _fabExpandAnimation;
  late Animation<double> _fabRotateAnimation;
  bool _isFabOpen = false;

  // SOS State
  bool _sendingSOS = false;
  String? _activeSOSId;
  
  // Camera & Upload State
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  // OpenRouteService API Key
  static const String _orsApiKey = 'eyJvcmciOiI1YjNjZTM1OTc4NTExMTAwMDFjZjYyNDgiLCJpZCI6IjZiMzQ4NjAzNjAzYzQ5OWNhOWJkMTMyNWFmZDg0OGUwIiwiaCI6Im11cm11cjY0In0=';
  
  // Route information
  String? _routeDistance;
  String? _routeDuration;
  LatLng? _selectedDestination;

  // Custom marker icons
  BitmapDescriptor? _reliefCampIcon;
  BitmapDescriptor? _hospitalIcon;

  static const CameraPosition _keralaDefault = CameraPosition(
    target: LatLng(10.1076, 76.3519),
    zoom: 12,
  );

  @override
  void initState() {
    super.initState();
    _startLocationUpdates();
    _createCustomMarkerIcons();
    
    // Automatically load safe zones for this disaster!
    _selectedLayer = 'safe_zones_relief';
    _loadLayer(_selectedLayer);

    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _fabExpandAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.fastOutSlowIn,
    );
    _fabRotateAnimation = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(
        parent: _fabAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  Future<void> _createCustomMarkerIcons() async {
    _reliefCampIcon = await _createCustomIcon(Icons.home, Colors.green);
    _hospitalIcon = await _createCustomIcon(Icons.local_hospital, Colors.red);
    if (mounted) setState(() {});
  }

  Future<BitmapDescriptor> _createCustomIcon(IconData icon, Color color) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final paint = Paint()..color = color;
    
    const double size = 120.0;
    
    // Draw circle background
    canvas.drawCircle(const Offset(size / 2, size / 2), size / 2, paint);
    
    // Draw white border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;
    canvas.drawCircle(const Offset(size / 2, size / 2), size / 2 - 4, borderPaint);
    
    // Draw icon
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontSize: 60,
        fontFamily: icon.fontFamily,
        color: Colors.white,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size - textPainter.width) / 2,
        (size - textPainter.height) / 2,
      ),
    );

    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    
    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }

  @override
  void dispose() {
    _safeZoneSubscription?.cancel();
    _positionStream?.cancel();
    _fabAnimationController.dispose();
    super.dispose();
  }

  Future<void> _startLocationUpdates() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      await Geolocator.requestPermission();
    }

    try {
      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen((Position position) {
        if (mounted) {
          setState(() {
            _userLocation = LatLng(position.latitude, position.longitude);
          });
          
          // Update route if one is active
          if (_selectedDestination != null) {
            _getRouteToSafeZone(_selectedDestination!);
          }
        }
      });
    } catch (e) {
      debugPrint('Error getting location stream: $e');
    }
  }

  // OpenRouteService Route Fetching
  Future<void> _getRouteToSafeZone(LatLng destination) async {
    if (_userLocation == null) {
      _showSnackBar('Unable to get your current location', isError: true);
      return;
    }

    setState(() {
      _isLoadingRoute = true;
      _selectedDestination = destination;
    });

    try {
      final url = Uri.parse(
        'https://api.openrouteservice.org/v2/directions/driving-car',
      );

      final response = await http.post(
        url,
        headers: {
          'Authorization': _orsApiKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'coordinates': [
            [_userLocation!.longitude, _userLocation!.latitude],
            [destination.longitude, destination.latitude],
          ],
          'instructions': true,
          'elevation': false,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _processRouteData(data, destination);
      } else {
        throw Exception('Route API error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching route: $e');
      _showSnackBar('Failed to get route: $e', isError: true);
      setState(() {
        _isLoadingRoute = false;
        _selectedDestination = null;
      });
    }
  }

  void _processRouteData(Map<String, dynamic> data, LatLng destination) {
    try {
      final routes = data['routes'] as List<dynamic>;
      if (routes.isEmpty) {
        throw Exception('No routes found');
      }
      
      final route = routes[0] as Map<String, dynamic>;
      final summary = route['summary'] as Map<String, dynamic>;

      final distanceMeters = summary['distance'] as num;
      final durationSeconds = summary['duration'] as num;
      
      final distance = (distanceMeters / 1000).toStringAsFixed(1);
      final duration = (durationSeconds / 60).toStringAsFixed(0);

      setState(() {
        _routeDistance = '$distance km';
        _routeDuration = '$duration min';
      });

      List<LatLng> routePoints = [];
      final geometry = route['geometry'];
      
      if (geometry is String) {
        routePoints = _decodeEncodedPolyline(geometry);
      } else if (geometry is Map) {
        final coordinates = geometry['coordinates'] as List<dynamic>;
        routePoints = _decodeGeoJsonCoordinates(coordinates);
      }

      if (routePoints.isEmpty) {
        throw Exception('No route points decoded');
      }

      setState(() {
        _polylines.clear();
        _polylines.add(
          Polyline(
            polylineId: const PolylineId('route_to_safe_zone'),
            points: routePoints,
            color: Colors.blue,
            width: 6,
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
            jointType: JointType.round,
          ),
        );
        _isLoadingRoute = false;
      });

      // Animate camera to show complete route
      final bounds = _boundsFromLatLngList([
        _userLocation!,
        destination,
        ...routePoints,
      ]);
      _mapController?.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 100),
      );

      _showSnackBar('Route: $_routeDistance, $_routeDuration', isError: false);
    } catch (e) {
      print('Error processing route: $e');
      _showSnackBar('Error processing route', isError: true);
      setState(() => _isLoadingRoute = false);
    }
  }

  List<LatLng> _decodeGeoJsonCoordinates(List<dynamic> coordinates) {
    List<LatLng> points = [];
    try {
      for (var coord in coordinates) {
        if (coord is List && coord.length >= 2) {
          final lng = (coord[0] as num).toDouble();
          final lat = (coord[1] as num).toDouble();
          points.add(LatLng(lat, lng));
        }
      }
    } catch (e) {
      print('Error decoding GeoJSON: $e');
    }
    return points;
  }

  List<LatLng> _decodeEncodedPolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0;
    int len = encoded.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int b;
      int shift = 0;
      int result = 0;
      
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return points;
  }

  void _clearRoute() {
    setState(() {
      _polylines.clear();
      _routeDistance = null;
      _routeDuration = null;
      _selectedDestination = null;
    });
  }

  void _toggleFab() {
    setState(() {
      _isFabOpen = !_isFabOpen;
      if (_isFabOpen) {
        _fabAnimationController.forward();
      } else {
        _fabAnimationController.reverse();
      }
    });
  }

  Future<void> _sendSOSDialog() async {
    try {
      setState(() => _sendingSOS = true);

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw 'Location services are disabled';

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw 'Location permission denied';
      }

      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      String district = 'Unknown District';
      String city = 'Unknown City';
      String area = 'Unknown Area';

      String _safeString(String? val, String fallback) {
        if (val == null || val.trim().isEmpty) return fallback;
        return val.replaceAll('/', '_');
      }

      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
            position.latitude, position.longitude);
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          district = _safeString(place.subAdministrativeArea, _safeString(place.administrativeArea, 'Unknown District'));
          city = _safeString(place.locality, _safeString(place.subLocality, district));
          area = _safeString(place.name, _safeString(place.street, city));
        }
      } catch (e) {
        print('Geocoding error: $e');
      }

      setState(() => _sendingSOS = false);

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => SOSDialog(
          isSending: _sendingSOS,
          onSubmit: (data) async {
            // Close dialog FIRST before starting the heavy async task so context is preserved for the main screen
            Navigator.pop(context);
            await _submitSOSData(
              position: position,
              district: district,
              city: city,
              area: area,
              userProvidedData: data,
            );
          },
        ),
      );
    } catch (e) {
      setState(() => _sendingSOS = false);
      _showSnackBar('Error getting location: $e', isError: true);
    }
  }

  Future<void> _submitSOSData({
    required Position position,
    required String district,
    required String city,
    required String area,
    required Map<String, dynamic> userProvidedData,
  }) async {
    try {
      setState(() => _sendingSOS = true);

      // Analyze the SOS description using NLP Triage Service
      final description = userProvidedData['description'] ?? '';
      final emergencyType = userProvidedData['emergencyType'] ?? '';
      final triageResult = NLPTriageService.analyzeSOS(description, emergencyType);

      final db = FirebaseFirestore.instance;
      final batch = db.batch();

      final priority = triageResult['priority'];
      final triageTag = triageResult['tag'];
      final phone = userProvidedData['phone'] ?? '';

      final newDocRef = db.collection('Disasters').doc(widget.disasterType).collection('rescue_requests').doc();

      batch.set(newDocRef, {
        'district': district,
        'city': city,
        'area': area,
        'lat': position.latitude,
        'lng': position.longitude,
        'description': description,
        'peopleCount': userProvidedData['peopleCount'] ?? 1,
        'emergencyType': emergencyType,
        'priority': priority,
        'triageTag': triageTag,
        'phone': phone,
        'status': 'PENDING',
        'source': 'MOBILE_USER',
        'createdAt': FieldValue.serverTimestamp(),
      });

      final summaryRef =
          db.doc('Disasters/${widget.disasterType}/rescue_summary/$district/cities/$city/areas/$area');

      batch.set(
          summaryRef,
          {
            'district': district,
            'city': city,
            'area': area,
            'lat': position.latitude,
            'lng': position.longitude,
            'totalSOS': FieldValue.increment(1),
            'pending': FieldValue.increment(1),
            'lastUpdated': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true));

      await batch.commit();

      setState(() {
        _activeSOSId = newDocRef.id;
      });

      _mapController?.animateCamera(
        CameraUpdate.newLatLng(LatLng(position.latitude, position.longitude)),
      );

      _showSnackBar('SOS Sent! Rescue teams alerted.', isError: false);
    } catch (e) {
      _showSnackBar('Failed to send SOS: $e', isError: true);
    } finally {
      if (mounted) setState(() => _sendingSOS = false);
    }
  }

  Future<void> _captureAndUploadPhoto() async {
    try {
      // 1. Check Location Permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
           // Allow, but location will be unknown
        }
      }

      // 2. Capture Photo
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70, // Optimize size
      );

      if (photo == null) return; // User canceled

      setState(() => _isUploading = true);
      _showSnackBar('Uploading photo...', isError: false);

      // 3. Get Location
      Position? position;
      try {
         position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium);
      } catch (e) {
        print('Location error: $e');
      }

      final lat = position?.latitude ?? 0.0;
      final lng = position?.longitude ?? 0.0;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      
      // 4. Upload to Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('user_reports/images/$timestamp.jpg');

      final uploadTask = storageRef.putFile(File(photo.path));
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // 5. Analyze Image with Google Vision API
      _showSnackBar('Analyzing image for flood verification...', isError: false);
      
      final visionService = GoogleVisionService();
      final analysis = await visionService.analyzeImageUrl(downloadUrl);
      
      final status = analysis['status'];
      final isFlood = analysis['isFloodLikely'] as bool? ?? false;
      final floodScore = analysis['floodScore'] as double? ?? 0.0;
      final reason = analysis['reason'] ?? 'unknown';

      // 6. Store Result in Firestore (flood_reports)
      await FirebaseFirestore.instance.collection('Disasters').doc(widget.disasterType).collection('flood_reports').add({
        'imageUrl': downloadUrl,
        'lat': lat,
        'lng': lng,
        'uploadedBy': 'USER_APP', // Replace with Auth UID if available
        'timestamp': FieldValue.serverTimestamp(),
        'status': status, // verified_flood, rejected_not_flood, rejected_unsafe
        'floodScore': floodScore,
        'isFloodLikely': isFlood,
        'visionLabels': analysis['visionLabels'],
        'safeSearch': analysis['safeSearch'],
        'reason': reason,
        'district': 'Unknown', // Can be enriched with geocoding
        'city': 'Unknown',
      });

      // 7. Handle Result UI & Storage Cleanup
      if (status == 'verified_flood') {
        final confidence = (floodScore * 100).clamp(0, 100).toStringAsFixed(1);
        _showSnackBar('Flood report verified ✅ (Confidence: $confidence%)', isError: false);

        // Save to crowdsourced_reports for map display
        await FirebaseFirestore.instance.collection('Disasters').doc(widget.disasterType).collection('crowdsourced_reports').add({
          'imageUrl': downloadUrl,
          'lat': lat,
          'lng': lng,
          'reportedBy': 'USER_APP',
          'district': 'Unknown', 
          'city': 'Unknown',
          'type': 'GROUND_IMAGE',
          'status': 'VERIFIED',
          'timestamp': FieldValue.serverTimestamp(),
          'floodScore': floodScore,
        });

      } else {
        // Reject - Show error
        String errorMsg = 'Upload rejected';
        if (status == 'rejected_unsafe') errorMsg = 'Upload rejected: Unsafe content detected ⚠️';
        if (status == 'rejected_not_flood') errorMsg = 'Upload rejected: Not a flood image ❌';
        
        _showSnackBar(errorMsg, isError: true);
        
        // Optional: Delete rejected image to save space
         try {
           await storageRef.delete(); 
           print('Rejected image deleted from storage.');
         } catch (e) {
           print('Error deleting rejected image: $e');
         }
      }

    } catch (e) {
      _showSnackBar('Process failed. Try again.', isError: true);
      print('Upload/Analysis Error: $e');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isError ? Icons.error : Icons.check_circle,
                color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade800 : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _loadLayer(String layer) async {
    setState(() {
      _isLoading = true;
      _polygons = {};
      _markers = {};
      _clearRoute();
    });

    if (layer == 'safe_zones_relief') {
      _safeZoneSubscription?.cancel();

      _safeZoneSubscription = FirebaseFirestore.instance
          .collection('Disasters').doc(widget.disasterType).collection('safe_zones')
          .where('status', isEqualTo: 'ACTIVE')
          .snapshots()
          .listen((snapshot) {
        if (!mounted) return;
        
        final newMarkers = <Marker>{};

        for (final doc in snapshot.docs) {
          final data = doc.data();
          final double? lat = (data['lat'] as num?)?.toDouble();
          final double? lng = (data['lng'] as num?)?.toDouble();

          if (lat == null || lng == null) continue;

          final point = LatLng(lat, lng);
          final category = data['category'] as String? ?? 'Relief Camp';
          final capacity = data['capacity']?.toString() ?? 'N/A';
          final name = data['name'] ?? 'Safe Zone';
          final type = data['type'] as String? ?? 'Other';

          BitmapDescriptor? icon;
          if (category == 'Medical Facility' || type == 'Hospital') {
            icon = _hospitalIcon;
          } else {
            icon = _reliefCampIcon;
          }

          newMarkers.add(
            Marker(
              markerId: MarkerId(doc.id),
              position: point,
              infoWindow: InfoWindow(
                title: name,
                snippet: '$category • Capacity: $capacity',
                onTap: () {
                  _showSafeZoneDetails(point, data);
                },
              ),
              icon: icon ?? BitmapDescriptor.defaultMarker,
              onTap: () {
                _showSafeZoneDetails(point, data);
              },
            ),
          );
        }

        setState(() {
          _markers = newMarkers;
          _isLoading = false;
        });
        
      }, onError: (e) {
        print('Error listening to safe zones: $e');
        if (mounted) {
          final loc = Provider.of<LocaleProvider>(context, listen: false);
          _showSnackBar('${loc.get('sync_error')} Safe Zones: $e', isError: true);
          setState(() => _isLoading = false);
        }
      });
      return;
    }

    try {
      final docRef = FirebaseFirestore.instance
          .collection('floods')
          .doc('kerela-flood')
          .collection(layer)
          .doc('points');

      final doc = await docRef.get();
      if (!doc.exists) {
        setState(() => _isLoading = false);
        _showSnackBar('No data found for layer: $layer');
        return;
      }

      final data = doc.data();
      final coords = (data?['coordinates'] as List<dynamic>?) ?? [];
      
      _processCoordinates(coords, layer);

    } catch (e) {
      print('Error loading layer: $e');
      setState(() {
        _polygons = {};
        _markers = {};
        _isLoading = false;
      });
      _showSnackBar('Error loading layer: ${e.toString()}', isError: true);
    }
  }

  Future<void> _processCoordinates(List<dynamic> coords, String layer) async {
    List<LatLng> points = [];
    for (var item in coords) {
       final p = _parseCoordinate(item);
       if (p != null) points.add(p);
    }

    if (points.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    if (_shouldShowMarkers(layer)) {
      _markers = {};
      for (var i = 0; i < points.length; i++) {
        final point = points[i];

       _markers.add(
          Marker(
            markerId: MarkerId('${layer}_$i'),
            position: point,
            infoWindow: InfoWindow(title: layer.replaceAll('_', ' ').toUpperCase()),
            icon: BitmapDescriptor.defaultMarkerWithHue(
                _getLayerHue(layer)),
          ),
        );
      }
    }

    if (points.length >= 3) {
      final colors = _getLayerColors(layer);
      _polygons = {
        Polygon(
          polygonId: PolygonId(layer),
          points: points,
          fillColor: colors['fill']!,
          strokeColor: colors['border']!,
          strokeWidth: 2,
        )
      };
    }

    setState(() => _isLoading = false);

    if (points.isNotEmpty) {
       LatLngBounds bounds = _boundsFromLatLngList(points);
       _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
    }
  }

  LatLngBounds _boundsFromLatLngList(List<LatLng> list) {
    double? x0, x1, y0, y1;
    for (LatLng latLng in list) {
      if (x0 == null) {
        x0 = x1 = latLng.latitude;
        y0 = y1 = latLng.longitude;
      } else {
        if (latLng.latitude > x1!) x1 = latLng.latitude;
        if (latLng.latitude < x0) x0 = latLng.latitude;
        if (latLng.longitude > y1!) y1 = latLng.longitude;
        if (latLng.longitude < y0!) y0 = latLng.longitude;
      }
    }
    return LatLngBounds(
        northeast: LatLng(x1!, y1!), southwest: LatLng(x0!, y0!));
  }

  LatLng? _parseCoordinate(dynamic item) {
    try {
      if (item is Map) {
        final num? lat = item['lat'] ?? item['latitude'];
        final num? lng = item['lng'] ?? item['longitude'] ?? item['long'];
        if (lat != null && lng != null) return LatLng(lat.toDouble(), lng.toDouble());
        
        var value = item.values.first;
         if (value is Map) {
             final num? lat2 = value['lat']; 
             final num? lng2 = value['lng'];
             if (lat2 != null && lng2 != null) return LatLng(lat2.toDouble(), lng2.toDouble());
         } else if (value is List && value.length >= 2) {
             return LatLng((value[0] as num).toDouble(), (value[1] as num).toDouble());
         }
      } else if (item is List && item.length >= 2) {
        return LatLng((item[0] as num).toDouble(), (item[1] as num).toDouble());
      }
    } catch (_) {}
    return null;
  }

  bool _shouldShowMarkers(String layer) {
    return layer == 'household_impact' || layer == 'disaster_tour'; 
  }

  Map<String, Color> _getLayerColors(String layer) {
    switch (layer) {
      case 'after_flood_extent':
        return {'fill': Colors.red.withOpacity(0.4), 'border': Colors.red};
      case 'before_flood':
        return {'fill': Colors.blue.withOpacity(0.3), 'border': Colors.blue};
      case 'disaster_tour':
        return {'fill': Colors.orange.withOpacity(0.4), 'border': Colors.orange};
      case 'household_impact':
        return {'fill': Colors.purple.withOpacity(0.4), 'border': Colors.purple};
      case 'rainfall_severity':
        return {'fill': Colors.indigo.withOpacity(0.4), 'border': Colors.indigo};
      case 'urban_flood_hotspots':
        return {'fill': Colors.deepOrange.withOpacity(0.4), 'border': Colors.deepOrange};
      case 'vegetation_agriculture_loss':
        return {'fill': Colors.brown.withOpacity(0.4), 'border': Colors.brown};
      default:
        return {'fill': Colors.grey.withOpacity(0.3), 'border': Colors.grey};
    }
  }

  double _getLayerHue(String layer) {
     if (layer == 'household_impact') return BitmapDescriptor.hueViolet;
     return BitmapDescriptor.hueRed;
  }
  
  void _showSafeZoneDetails(LatLng point, Map<String, dynamic> data) {
    final loc = Provider.of<LocaleProvider>(context, listen: false);
    final String name = data['name'] ?? loc.get('safe_zone');
    final String status = data['status'] ?? 'Open';
    final String category = data['category'] ?? 'Emergency Shelter';
    final String capacity = data['capacity']?.toString() ?? 'N/A';
    
    String distanceStr = '';
    if (_userLocation != null) {
       final dist = Geolocator.distanceBetween(
         _userLocation!.latitude, _userLocation!.longitude, 
         point.latitude, point.longitude) / 1000;
       distanceStr = '${dist.toStringAsFixed(1)} km away';
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: const [
             BoxShadow(color: Colors.black26, blurRadius: 10, spreadRadius: 2),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[600], borderRadius: BorderRadius.circular(2)))),
             const SizedBox(height: 20),
             Row(
               children: [
                 Icon(category == 'Hospital' ? Icons.local_hospital : Icons.home, 
                   color: category == 'Hospital' ? Colors.redAccent : Colors.greenAccent, size: 28),
                 const SizedBox(width: 12),
                 Expanded(
                   child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(category, style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                   ]),
                 ),
                 Container(
                   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                   decoration: BoxDecoration(
                     border: Border.all(color: status == 'ACTIVE' ? Colors.green : Colors.red),
                     borderRadius: BorderRadius.circular(20),
                   ),
                   child: Text(status.toUpperCase(), style: TextStyle(color: status == 'ACTIVE' ? Colors.greenAccent : Colors.redAccent, fontSize: 12)),
                 ),
               ],
             ),
             const SizedBox(height: 24),
             if (distanceStr.isNotEmpty) Row(
               children: [
                 Icon(Icons.directions_walk, color: Colors.blue[200], size: 20),
                 const SizedBox(width: 8),
                 Text(distanceStr, style: const TextStyle(color: Colors.white)),
                 const SizedBox(width: 24),
                 Icon(Icons.people, color: Colors.blue[200], size: 20),
                 const SizedBox(width: 8),
                 Text('${loc.get('capacity')} $capacity', style: const TextStyle(color: Colors.white)),
               ], 
             ),
             
             if (_routeDistance != null && _routeDuration != null && _selectedDestination == point) ...[
               const SizedBox(height: 16),
               Container(
                 padding: const EdgeInsets.all(12),
                 decoration: BoxDecoration(
                   color: Colors.blue.withOpacity(0.1),
                   borderRadius: BorderRadius.circular(12),
                   border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
                 ),
                 child: Row(
                   children: [
                     const Icon(Icons.route, color: Colors.blueAccent, size: 20),
                     const SizedBox(width: 12),
                     Text('Route: $_routeDistance • $_routeDuration', 
                       style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.w500)),
                   ],
                 ),
               ),
             ],
             
             const SizedBox(height: 24),
             Row(
               children: [
                 if (_userLocation != null) ...[
                   Expanded(
                     child: ElevatedButton.icon(
                       style: ElevatedButton.styleFrom(
                         backgroundColor: Colors.blueAccent[700],
                         padding: const EdgeInsets.symmetric(vertical: 16),
                       ),
                       onPressed: _isLoadingRoute 
                         ? null 
                         : () {
                             Navigator.pop(context);
                             _getRouteToSafeZone(point);
                           },
                       icon: _isLoadingRoute 
                         ? const SizedBox(
                             width: 16, 
                             height: 16, 
                             child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                           )
                         : const Icon(Icons.directions),
                       label: Text(
                         _isLoadingRoute ? loc.get('loading') : loc.get('get_directions'),
                         style: const TextStyle(color: Colors.white),
                       ),
                     ),
                   ),
                   if (_selectedDestination == point) ...[
                     const SizedBox(width: 8),
                     ElevatedButton(
                       style: ElevatedButton.styleFrom(
                         backgroundColor: Colors.red[700],
                         padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                       ),
                       onPressed: () {
                         Navigator.pop(context);
                         _clearRoute();
                       },
                       child: const Icon(Icons.close, color: Colors.white),
                     ),
                   ],
                 ],
               ],
             ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<LocaleProvider>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        automaticallyImplyLeading: true,
        title: const Text(
          'SAHYOG',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (_isUploading)
             const Padding(
               padding: EdgeInsets.symmetric(horizontal: 16.0),
               child: Center(
                 child: SizedBox(
                   width: 20, height: 20,
                   child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                 ),
               ),
             )
          else
            IconButton(
              icon: const Icon(Icons.camera_alt),
              onPressed: _captureAndUploadPhoto,
              tooltip: 'Report Disaster',
            ),
            
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
           Column(
             children: [
               LiveAdvisoryBanner(disasterType: widget.disasterType),
               Expanded(
                 child: GoogleMap(
                   initialCameraPosition: widget.targetLocation != null 
                       ? CameraPosition(target: widget.targetLocation!, zoom: 10)
                       : _keralaDefault,
                   onMapCreated: (controller) => _mapController = controller,
                   myLocationEnabled: true,
                   myLocationButtonEnabled: true,
                   mapType: MapType.normal,
                   markers: _markers,
                   polygons: _polygons,
                   polylines: _polylines,
                 ),
               ),
             ],
           ),
           
           if (_sendingSOS)
             Positioned(
               bottom: 24, left: 24,
               child: Container(
                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                 decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.9), borderRadius: BorderRadius.circular(30)),
                 child: const Row(children: [
                    SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                    SizedBox(width: 12),
                    Text('SOS SIGNAL: SENDING...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                 ]),
               ),
             ),
             
           if (!_sendingSOS && _activeSOSId != null)
             Positioned(
                bottom: 24, left: 20, right: 120,
                child: StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance.collection('Disasters').doc(widget.disasterType).collection('rescue_requests').doc(_activeSOSId).snapshots(),
                  builder: (context, snapshot) {
                     if (!snapshot.hasData || !snapshot.data!.exists) return const SizedBox.shrink();
                     final data = snapshot.data!.data() as Map<String, dynamic>;
                     return GestureDetector(
                       onTap: () => _showSOSDetailsWrapped(data),
                       child: _buildSOSStatusCard(data['status'] ?? 'PENDING'),
                     );
                  },
                ),
             ),

           if (_isFabOpen)
             Positioned.fill(child: GestureDetector(onTap: _toggleFab, child: Container(color: Colors.black.withOpacity(0.5)))),
             
           Positioned(
             bottom: 90, right: 24,
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.end,
               children: [
                 SizeTransition(
                   sizeFactor: _fabExpandAnimation,
                   axis: Axis.vertical,
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.end,
                     children: [
                       _buildFabAction(Icons.phone, 'Call 112', Colors.redAccent, () async {
                         final Uri url = Uri(scheme: 'tel', path: '112');
                         if (await canLaunchUrl(url)) {
                           await launchUrl(url);
                         } else {
                           if (context.mounted) {
                             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not launch phone dialer')));
                           }
                         }
                       }),
                       _buildFabAction(Icons.shield_outlined, 'Safe Zones', Colors.green, () {
                          setState(() => _selectedLayer = 'safe_zones_relief');
                          _loadLayer('safe_zones_relief');
                       }),
                       _buildFabAction(Icons.warning_amber_rounded, 'Advisories', Colors.orange, () => Navigator.push(context, MaterialPageRoute(builder: (context) => AdvisoryScreen(disasterType: widget.disasterType)))),
                       _buildFabAction(_sendingSOS ? Icons.hourglass_top : Icons.sos, 'Send SOS', Colors.red, _sendingSOS ? () {} : _sendSOSDialog),
                     ],
                   ),
                 ),
                 FloatingActionButton(
                   onPressed: _toggleFab,
                   backgroundColor: Colors.blue.shade800,
                   child: RotationTransition(turns: _fabRotateAnimation, child: const Icon(Icons.add, size: 32, color: Colors.white)),
                 ),
               ],
             ),
           ),
        ],
      ),
    );
  }

  void _showSOSDetailsWrapped(Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey[700],
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'SOS Request Details',
              style: TextStyle(
                  color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildDetailRow(Icons.access_time, 'Sent',
                _formatTimestamp(data['createdAt'])),
            const SizedBox(height: 12),
            _buildDetailRow(Icons.location_on, 'Location',
                '${(data['lat'] as num).toStringAsFixed(4)}, ${(data['lng'] as num).toStringAsFixed(4)}'),
            const SizedBox(height: 12),
            _buildDetailRow(
                Icons.info_outline, 'Status', data['status'] ?? 'PENDING'),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.security, color: Colors.orangeAccent),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Your location has been shared with official disaster response teams.',
                      style:
                          TextStyle(color: Colors.orangeAccent, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Just now';
    if (timestamp is Timestamp) {
      final dt = timestamp.toDate();
      return '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return 'Just now';
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[400], size: 20),
        const SizedBox(width: 12),
        Text('$label: ',
            style: TextStyle(color: Colors.grey[500], fontSize: 14)),
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }
  
  Widget _buildSOSStatusCard(String status) {
    Color cardColor;
    Color textColor;
    String statusText;
    IconData icon;

    switch (status.toUpperCase()) {
      case 'PENDING':
        cardColor = Colors.orange.shade800;
        textColor = Colors.white;
        statusText = 'SOS PENDING';
        icon = Icons.access_time_filled;
        break;
      case 'ACKNOWLEDGED':
        cardColor = Colors.blue.shade700;
        textColor = Colors.white;
        statusText = 'ASSISTANCE ON WAY';
        icon = Icons.verified;
        break;
      case 'IN_PROGRESS':
        cardColor = Colors.yellow.shade700;
        textColor = Colors.black87;
        statusText = 'RESCUE IN PROGRESS';
        icon = Icons.directions_run;
        break;
      case 'RESOLVED':
        cardColor = Colors.green.shade700;
        textColor = Colors.white;
        statusText = 'SOS RESOLVED';
        icon = Icons.check_circle;
        break;
      default:
        cardColor = Colors.grey.shade800;
        textColor = Colors.white;
        statusText = 'SOS SENT';
        icon = Icons.error_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (status != 'RESOLVED') ...[
            SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: textColor)),
            const SizedBox(width: 12),
          ] else ...[
            Icon(icon, color: textColor, size: 20),
            const SizedBox(width: 8),
          ],
          Text(
            statusText,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFabAction(IconData icon, String label, Color color, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Colors.grey[800],
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          FloatingActionButton(
            heroTag: label,
            onPressed: () {
              _toggleFab();
              onTap();
            },
            backgroundColor: color,
            foregroundColor: Colors.white,
            elevation: 4,
            mini: true,
            shape: const CircleBorder(),
            child: Icon(icon, size: 20),
          ),
        ],
      ),
    );
  }
}