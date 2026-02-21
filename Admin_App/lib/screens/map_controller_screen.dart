import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'dart:math' as math;
import '../controllers/lg_controller.dart';
import 'package:permission_handler/permission_handler.dart';

class MapControllerScreen extends StatefulWidget {
  final LGController lgController;
  final String disasterType;

  const MapControllerScreen({super.key, required this.lgController, required this.disasterType});

  @override
  State<MapControllerScreen> createState() => _MapControllerScreenState();
}

class _MapControllerScreenState extends State<MapControllerScreen> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Circle> _circles = {};
  
  bool _isLoading = false;
  bool _syncWithLG = true;
  bool _myLocationEnabled = false;
  String _mapMode = 'normal';
  
  // Default Kerala location
  static const LatLng _defaultLocation = LatLng(10.1071, 76.3636);
  LatLng _currentCenter = _defaultLocation;
  double _currentZoom = 10.0;
  double _currentTilt = 0.0;
  double _currentBearing = 0.0;

  // Safe zone creation
  LatLng? _pendingSafeZoneLocation;
  final _safeZoneNameController = TextEditingController();
  final _safeZoneCapacityController = TextEditingController();
  String _selectedSafeZoneType = 'Relief Camp';
  
  // Sync control
  Timer? _syncDebounceTimer;
  Timer? _liveSyncTimer;
  bool _isSyncing = false;
  bool _isUserInteracting = false;
  int _syncSkipCounter = 0; // Skip initial syncs on load
  DateTime _lastSyncTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
    _loadRescueRequests();
    _loadSafeZones();
  }

  @override
  void dispose() {
    _syncDebounceTimer?.cancel();
    _liveSyncTimer?.cancel();
    _mapController?.dispose();
    _safeZoneNameController.dispose();
    _safeZoneCapacityController.dispose();
    super.dispose();
  }

  Future<void> _requestLocationPermission() async {
    try {
      final status = await Permission.location.request();
      if (mounted) {
        setState(() {
          _myLocationEnabled = status.isGranted;
        });
      }
    } catch (e) {
      debugPrint('Error requesting location permission: $e');
    }
  }

  Future<void> _loadRescueRequests() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('Disasters').doc(widget.disasterType).collection('rescue_requests')
          .where('status', isEqualTo: 'PENDING')
          .get();

      final markers = <Marker>{};
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final lat = (data['lat'] as num?)?.toDouble() ?? 0.0;
        final lng = (data['lng'] as num?)?.toDouble() ?? 0.0;
        final name = data['name'] as String? ?? 'Unknown';
        final urgency = data['urgency'] as String? ?? 'Medium';
        
        markers.add(
          Marker(
            markerId: MarkerId('rescue_${doc.id}'),
            position: LatLng(lat, lng),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              urgency == 'Critical' ? BitmapDescriptor.hueRed :
              urgency == 'High' ? BitmapDescriptor.hueOrange :
              BitmapDescriptor.hueYellow,
            ),
            infoWindow: InfoWindow(
              title: '🆘 $name',
              snippet: 'Urgency: $urgency\nTap to send to LG',
            ),
            onTap: () => _sendRescueLocationToLG(lat, lng, name),
          ),
        );
      }

      if (mounted) {
        setState(() {
          _markers.addAll(markers);
        });
      }
    } catch (e) {
      debugPrint('Error loading rescue requests: $e');
    }
  }

  Future<void> _loadSafeZones() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('Disasters').doc(widget.disasterType).collection('safe_zones')
          .where('visibleToPublic', isEqualTo: true)
          .get();

      final markers = <Marker>{};
      final circles = <Circle>{};
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final lat = (data['lat'] as num?)?.toDouble() ?? 0.0;
        final lng = (data['lng'] as num?)?.toDouble() ?? 0.0;
        final name = data['name'] as String? ?? 'Safe Zone';
        final capacity = data['capacity'] as int? ?? 0;
        final type = data['type'] as String? ?? 'Relief Camp';
        
        final position = LatLng(lat, lng);
        
        markers.add(
          Marker(
            markerId: MarkerId('safe_${doc.id}'),
            position: position,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
            infoWindow: InfoWindow(
              title: '🏕️ $name',
              snippet: 'Type: $type\nCapacity: $capacity\nTap to send to LG',
            ),
            onTap: () => _sendSafeZoneToLG(lat, lng, name),
          ),
        );
        
        circles.add(
          Circle(
            circleId: CircleId('circle_${doc.id}'),
            center: position,
            radius: 500,
            fillColor: Colors.green.withOpacity(0.1),
            strokeColor: Colors.green.withOpacity(0.5),
            strokeWidth: 2,
          ),
        );
      }

      if (mounted) {
        setState(() {
          _markers.addAll(markers);
          _circles.addAll(circles);
        });
      }
    } catch (e) {
      debugPrint('Error loading safe zones: $e');
    }
  }

  Future<void> _sendRescueLocationToLG(double lat, double lng, String name) async {
    if (!widget.lgController.isConnected) {
      _showError('Not connected to Liquid Galaxy');
      return;
    }

    setState(() => _isLoading = true);
    
    // Temporarily disable sync during programmatic movement
    final wasSyncing = _syncWithLG;
    _syncWithLG = false;
    
    try {
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(lat, lng),
            zoom: 15.0,
            tilt: 45.0,
            bearing: 0.0,
          ),
        ),
      );
      
      await Future.delayed(const Duration(milliseconds: 800));
      await widget.lgController.sendRescueMarker(lat, lng);
      _showSuccess('Rescue location sent to LG: $name');
      
    } catch (e) {
      _showError('Failed to send to LG: $e');
    } finally {
      // Re-enable sync
      await Future.delayed(const Duration(milliseconds: 500));
      _syncWithLG = wasSyncing;
      
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _sendSafeZoneToLG(double lat, double lng, String name) async {
    if (!widget.lgController.isConnected) {
      _showError('Not connected to Liquid Galaxy');
      return;
    }

    setState(() => _isLoading = true);
    
    final wasSyncing = _syncWithLG;
    _syncWithLG = false;
    
    try {
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(lat, lng),
            zoom: 14.0,
            tilt: 30.0,
            bearing: 0.0,
          ),
        ),
      );
      
      await Future.delayed(const Duration(milliseconds: 800));
      await widget.lgController.sendAreaSummary(lat: lat, lng: lng, areaName: name);
      _showSuccess('Safe zone sent to LG: $name');
      
    } catch (e) {
      _showError('Failed to send to LG: $e');
    } finally {
      await Future.delayed(const Duration(milliseconds: 500));
      _syncWithLG = wasSyncing;
      
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Calculate range from zoom level using accurate formula
  double _calculateRangeFromZoom(double zoom, double latitude) {
    const double earthRadius = 6371000.0;
    final latRad = latitude * math.pi / 180.0;
    final metersPerPixel = (2 * math.pi * earthRadius * math.cos(latRad)) / 
                           (256 * math.pow(2, zoom));
    const screenHeightPixels = 800;
    final range = metersPerPixel * screenHeightPixels;
    return range;
  }

  /// Main sync function - sends current map position to LG
  Future<void> _syncMapPositionToLG() async {
    if (!widget.lgController.isConnected || 
        !_syncWithLG || 
        _isSyncing ||
        _mapController == null) {
      return;
    }

    // Skip first few syncs to avoid initial load position
    if (_syncSkipCounter < 3) {
      _syncSkipCounter++;
      return;
    }

    _isSyncing = true;
    
    try {
      // Get visible region to calculate accurate center
      final bounds = await _mapController!.getVisibleRegion();
      
      // Calculate center from bounds
      final centerLat = (bounds.northeast.latitude + bounds.southwest.latitude) / 2.0;
      final centerLng = (bounds.northeast.longitude + bounds.southwest.longitude) / 2.0;
      
      final lat = centerLat;
      final lng = centerLng;
      
      // Calculate range using zoom and latitude
      final range = _calculateRangeFromZoom(_currentZoom, lat);
      
      // Build KML LookAt tag - compact format without extra whitespace
      final lookAtKml = '<LookAt>'
          '<longitude>$lng</longitude>'
          '<latitude>$lat</latitude>'
          '<altitude>0</altitude>'
          '<range>$range</range>'
          '<tilt>${_currentTilt.round()}</tilt>'
          '<heading>${_currentBearing.round()}</heading>'
          '<gx:altitudeMode>relativeToSeaFloor</gx:altitudeMode>'
          '</LookAt>';
      
      // Send to Liquid Galaxy using the flytoview command
      await widget.lgController.query('flytoview=$lookAtKml');
      
      _lastSyncTime = DateTime.now();
      
      debugPrint('🌍 Synced → Lat: ${lat.toStringAsFixed(4)}, '
                'Lng: ${lng.toStringAsFixed(4)}, '
                'Zoom: ${_currentZoom.toStringAsFixed(1)}, '
                'Range: ${(range / 1000).toStringAsFixed(1)}km, '
                'Tilt: ${_currentTilt.round()}°, '
                'Heading: ${_currentBearing.round()}°');
      
    } catch (e) {
      debugPrint('❌ Sync error: $e');
    } finally {
      _isSyncing = false;
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    debugPrint('✅ Map controller initialized');
  }

  void _onCameraMove(CameraPosition position) {
    // Update current position
    _currentCenter = position.target;
    _currentZoom = position.zoom;
    _currentTilt = position.tilt;
    _currentBearing = position.bearing;

    // Mark that user is actively moving the map
    _isUserInteracting = true;

    // Cancel any existing live sync timer
    _liveSyncTimer?.cancel();
    
    // Schedule a live sync during movement (throttled to every 300ms)
    final timeSinceLastSync = DateTime.now().difference(_lastSyncTime);
    if (timeSinceLastSync.inMilliseconds >= 300) {
      _liveSyncTimer = Timer(const Duration(milliseconds: 50), () {
        _syncMapPositionToLG();
      });
    }
  }

  void _onCameraIdle() {
    // User stopped moving the map
    _isUserInteracting = false;
    
    // Cancel any pending timers
    _liveSyncTimer?.cancel();
    _syncDebounceTimer?.cancel();
    
    // Do a final sync after user stops moving (debounced)
    _syncDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (!_isUserInteracting && _syncWithLG && mounted) {
        debugPrint('📍 Camera idle - Final sync');
        _syncMapPositionToLG();
      }
    });
  }

  void _onMapTap(LatLng position) {
    if (_mapMode == 'add_safe_zone') {
      setState(() {
        _pendingSafeZoneLocation = position;
      });
      _showAddSafeZoneDialog();
    }
  }

  void _showAddSafeZoneDialog() {
    if (_pendingSafeZoneLocation == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Add Safe Zone', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _safeZoneNameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Safe Zone Name',
                  labelStyle: const TextStyle(color: Colors.white70),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.tealAccent),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedSafeZoneType,
                dropdownColor: const Color(0xFF2A2A2A),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Type',
                  labelStyle: const TextStyle(color: Colors.white70),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.tealAccent),
                  ),
                ),
                items: ['Relief Camp', 'Shelter', 'Hospital', 'Assembly Point']
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) {
                    setState(() => _selectedSafeZoneType = v);
                  }
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _safeZoneCapacityController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Capacity (People)',
                  labelStyle: const TextStyle(color: Colors.white70),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.tealAccent),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.tealAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.tealAccent.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    const Text(
                      '📍 Selected Location',
                      style: TextStyle(
                        color: Colors.tealAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Lat: ${_pendingSafeZoneLocation!.latitude.toStringAsFixed(6)}',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    Text(
                      'Lng: ${_pendingSafeZoneLocation!.longitude.toStringAsFixed(6)}',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _pendingSafeZoneLocation = null;
                _mapMode = 'normal';
              });
              Navigator.pop(context);
            },
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () => _saveSafeZone(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.tealAccent,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Save Zone', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _saveSafeZone() async {
    if (_pendingSafeZoneLocation == null) return;
    
    if (_safeZoneNameController.text.trim().isEmpty) {
      Navigator.pop(context);
      Future.delayed(const Duration(milliseconds: 300), () {
        _showError('Please enter a name');
      });
      return;
    }

    Navigator.pop(context);
    setState(() => _isLoading = true);

    try {
      final capacity = int.tryParse(_safeZoneCapacityController.text.trim()) ?? 100;
      
      await FirebaseFirestore.instance.collection('Disasters').doc(widget.disasterType).collection('safe_zones').add({
        'name': _safeZoneNameController.text.trim(),
        'type': _selectedSafeZoneType,
        'category': 'Primary Shelter',
        'lat': _pendingSafeZoneLocation!.latitude,
        'lng': _pendingSafeZoneLocation!.longitude,
        'capacity': capacity,
        'district': 'Ernakulam',
        'city': 'Aluva',
        'status': 'ACTIVE',
        'visibleToPublic': true,
        'updatedAt': FieldValue.serverTimestamp(),
        'createdVia': 'map_controller',
      });

      _safeZoneNameController.clear();
      _safeZoneCapacityController.clear();
      
      if (mounted) {
        setState(() {
          _pendingSafeZoneLocation = null;
          _mapMode = 'normal';
          _markers.clear();
          _circles.clear();
        });
        
        _loadSafeZones();
        _loadRescueRequests();

        Future.delayed(const Duration(milliseconds: 300), () {
          _showSuccess('Safe zone added successfully');
        });
      }
      
    } catch (e) {
      Future.delayed(const Duration(milliseconds: 300), () {
        _showError('Failed to save: ${e.toString()}');
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Map Controller'),
        backgroundColor: Colors.black.withOpacity(0.7),
        elevation: 0,
        actions: [
          // Connection status indicator
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: widget.lgController.isConnected 
                  ? Colors.green.withOpacity(0.3) 
                  : Colors.red.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: widget.lgController.isConnected ? Colors.green : Colors.red,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.lgController.isConnected ? Icons.link : Icons.link_off,
                  size: 16,
                  color: widget.lgController.isConnected ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 6),
                Text(
                  widget.lgController.isConnected ? 'LG' : 'Offline',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: widget.lgController.isConnected ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ),
          // LG Sync Toggle
          IconButton(
            icon: Icon(_syncWithLG ? Icons.sync : Icons.sync_disabled),
            tooltip: _syncWithLG ? 'LG Sync ON - Map syncs with LG' : 'LG Sync OFF',
            color: _syncWithLG ? Colors.tealAccent : Colors.grey,
            onPressed: () {
              setState(() {
                _syncWithLG = !_syncWithLG;
                if (_syncWithLG) {
                  // Reset skip counter when enabling
                  _syncSkipCounter = 0;
                  // Do immediate sync
                  Future.delayed(const Duration(milliseconds: 500), () {
                    _syncMapPositionToLG();
                  });
                }
              });
              Future.delayed(const Duration(milliseconds: 200), () {
                _showSuccess(_syncWithLG 
                    ? 'LG Sync enabled - Move map to control LG' 
                    : 'LG Sync disabled');
              });
            },
          ),
          // Refresh markers
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Data',
            onPressed: () {
              setState(() {
                _markers.clear();
                _circles.clear();
              });
              _loadRescueRequests();
              _loadSafeZones();
              Future.delayed(const Duration(milliseconds: 200), () {
                _showSuccess('Data refreshed');
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _defaultLocation,
              zoom: _currentZoom,
            ),
            markers: _markers,
            circles: _circles,
            onCameraMove: _onCameraMove,
            onCameraIdle: _onCameraIdle,
            onTap: _onMapTap,
            myLocationEnabled: _myLocationEnabled,
            myLocationButtonEnabled: _myLocationEnabled,
            compassEnabled: true,
            mapToolbarEnabled: false,
            zoomControlsEnabled: false,
            mapType: MapType.hybrid,
            minMaxZoomPreference: const MinMaxZoomPreference(5, 20),
          ),
          
          // Loading indicator
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.tealAccent),
                    SizedBox(height: 16),
                    Text(
                      'Processing...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),

          // Mode selector
          Positioned(
            top: 100,
            right: 16,
            child: Column(
              children: [
                _buildModeButton(
                  icon: Icons.explore,
                  label: 'Browse',
                  isActive: _mapMode == 'normal',
                  color: Colors.blue,
                  onPressed: () => setState(() => _mapMode = 'normal'),
                ),
                const SizedBox(height: 8),
                _buildModeButton(
                  icon: Icons.add_location_alt,
                  label: 'Add Zone',
                  isActive: _mapMode == 'add_safe_zone',
                  color: Colors.green,
                  onPressed: () => setState(() => _mapMode = 'add_safe_zone'),
                ),
              ],
            ),
          ),

          // Sync status indicator
          if (_syncWithLG && widget.lgController.isConnected)
            Positioned(
              top: 100,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.tealAccent.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.tealAccent.withOpacity(0.3),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isUserInteracting ? Icons.sync : Icons.check_circle,
                      color: Colors.black,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isUserInteracting ? 'Syncing...' : 'LG Synced',
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Legend
          Positioned(
            bottom: 100,
            left: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.85),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.tealAccent, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Legend',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildLegendItem(Colors.red, '🆘 Critical Rescue'),
                  _buildLegendItem(Colors.orange, '🆘 High Priority'),
                  _buildLegendItem(Colors.yellow, '🆘 Medium Priority'),
                  _buildLegendItem(Colors.green, '🏕️ Safe Zones'),
                ],
              ),
            ),
          ),

          // Status banner
          if (_mapMode == 'add_safe_zone')
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade700, Colors.green.shade500],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.4),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Row(
                  children: [
                    Icon(Icons.touch_app, color: Colors.white, size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Tap anywhere on the map to add a safe zone',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Fly to Kerala
          FloatingActionButton(
            heroTag: 'kerala',
            backgroundColor: Colors.purple,
            child: const Icon(Icons.home, color: Colors.white),
            onPressed: () async {
              // Temporarily disable sync
              final wasSyncing = _syncWithLG;
              _syncWithLG = false;
              
              _mapController?.animateCamera(
                CameraUpdate.newCameraPosition(
                  const CameraPosition(
                    target: _defaultLocation,
                    zoom: 10.0,
                    tilt: 0,
                    bearing: 0,
                  ),
                ),
              );
              
              if (wasSyncing && widget.lgController.isConnected) {
                await Future.delayed(const Duration(milliseconds: 800));
                const lookAtKml = '<LookAt>'
                    '<longitude>76.3636</longitude>'
                    '<latitude>10.1071</latitude>'
                    '<altitude>0</altitude>'
                    '<range>500000</range>'
                    '<tilt>0</tilt>'
                    '<heading>0</heading>'
                    '<gx:altitudeMode>relativeToSeaFloor</gx:altitudeMode>'
                    '</LookAt>';
                await widget.lgController.query('flytoview=$lookAtKml');
              }
              
              // Re-enable sync
              await Future.delayed(const Duration(milliseconds: 1000));
              _syncWithLG = wasSyncing;
            },
          ),
          const SizedBox(height: 12),
          // Clear KMLs
          FloatingActionButton(
            heroTag: 'clear',
            backgroundColor: Colors.red,
            child: const Icon(Icons.clear_all, color: Colors.white),
            onPressed: () async {
              if (widget.lgController.isConnected) {
                setState(() => _isLoading = true);
                try {
                  await widget.lgController.clearKmls();
                  Future.delayed(const Duration(milliseconds: 200), () {
                    _showSuccess('Cleared LG displays');
                  });
                } catch (e) {
                  _showError('Failed to clear: ${e.toString()}');
                } finally {
                  if (mounted) {
                    setState(() => _isLoading = false);
                  }
                }
              } else {
                _showError('Not connected to LG');
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isActive ? color.withOpacity(0.9) : Colors.black.withOpacity(0.75),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive ? color : Colors.white.withOpacity(0.3),
              width: isActive ? 3 : 2,
            ),
            boxShadow: isActive ? [
              BoxShadow(
                color: color.withOpacity(0.5),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ] : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 28),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.5),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}