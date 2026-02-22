import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:math' show min, max;
import '../services/resource_hub_service.dart';
import '../services/location_service.dart';

class ResourceHubScreen extends StatefulWidget {
  const ResourceHubScreen({super.key});

  @override
  State<ResourceHubScreen> createState() => _ResourceHubScreenState();
}

class _ResourceHubScreenState extends State<ResourceHubScreen> {
  String _selectedType = 'All';
  GoogleMapController? _mapController;
  final Map<String, BitmapDescriptor> _customIcons = {};
  Set<Polyline> _activePolylines = {};

  static const List<String> _types = ['All', 'Safe', 'Food', 'Medical', 'Shelter'];

  @override
  void initState() {
    super.initState();
    _loadCustomIcons();
  }

  Future<void> _loadCustomIcons() async {
    _customIcons['safe_zone'] = await _createCustomMarkerBitmap(Icons.security, Colors.green);
    _customIcons['food'] = await _createCustomMarkerBitmap(Icons.restaurant, Colors.orange);
    _customIcons['medical'] = await _createCustomMarkerBitmap(Icons.medical_services, Colors.blue);
    _customIcons['shelter'] = await _createCustomMarkerBitmap(Icons.house, Colors.purple);
    if (mounted) setState(() {});
  }

  Future<BitmapDescriptor> _createCustomMarkerBitmap(IconData iconData, Color color) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    const double size = 96.0;

    final Paint shadowPaint = Paint()..color = Colors.black.withOpacity(0.3);
    canvas.drawCircle(const Offset(size / 2, size / 2 + 4), size / 2.2, shadowPaint);

    final Paint circlePaint = Paint()..color = color;
    canvas.drawCircle(const Offset(size / 2, size / 2), size / 2.2, circlePaint);

    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0;
    canvas.drawCircle(const Offset(size / 2, size / 2), size / 2.2, borderPaint);

    TextPainter textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(iconData.codePoint),
      style: TextStyle(
        fontSize: size * 0.55,
        fontFamily: iconData.fontFamily,
        package: iconData.fontPackage,
        color: Colors.white,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset((size - textPainter.width) / 2, (size - textPainter.height) / 2),
    );

    final ui.Picture picture = pictureRecorder.endRecording();
    final ui.Image image = await picture.toImage(size.toInt(), size.toInt());
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'safe_zone': return Colors.green;
      case 'food': return Colors.orange;
      case 'medical': return Colors.blue;
      case 'shelter': return Colors.purple;
      default: return Colors.grey;
    }
  }

  double _getMarkerHue(String type) {
    switch (type.toLowerCase()) {
      case 'safe_zone': return BitmapDescriptor.hueGreen;
      case 'food': return BitmapDescriptor.hueOrange;
      case 'medical': return BitmapDescriptor.hueAzure;
      case 'shelter': return BitmapDescriptor.hueViolet;
      default: return BitmapDescriptor.hueYellow;
    }
  }

  void _showResourceDetails(Map<String, dynamic> resource, LatLng userPos) {
    final destination = LatLng(resource['latitude'], resource['longitude']);

    setState(() {
      _activePolylines = {
        Polyline(
          polylineId: const PolylineId('route_line'),
          points: [userPos, destination],
          color: Colors.blueAccent,
          width: 5,
          patterns: [PatternItem.dash(20), PatternItem.gap(10)],
        )
      };
    });

    // Animate camera to fit both source and destination
    Future.delayed(const Duration(milliseconds: 300), () {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(min(userPos.latitude, destination.latitude), min(userPos.longitude, destination.longitude)),
            northeast: LatLng(max(userPos.latitude, destination.latitude), max(userPos.longitude, destination.longitude)),
          ),
          80.0, // padding
        ),
      );
    });

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    resource['name'] ?? 'Resource',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getTypeColor(resource['type']).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _getTypeColor(resource['type']).withOpacity(0.3)),
                  ),
                  child: Text(
                    resource['type']?.toString().toUpperCase() ?? 'OTHER',
                    style: TextStyle(
                      color: _getTypeColor(resource['type']),
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.near_me, size: 18, color: Colors.blueGrey),
                const SizedBox(width: 8),
                Text(
                  '${resource['distance']?.toStringAsFixed(2)} km away',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // ACTION TYPE (Pickup Available / Delivery Needed)
            if (resource['actionType'] != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: resource['actionType'] == 'Pickup Available' ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: resource['actionType'] == 'Pickup Available' ? Colors.green.withOpacity(0.3) : Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      resource['actionType'] == 'Pickup Available' ? Icons.inventory_2 : Icons.local_shipping,
                      color: resource['actionType'] == 'Pickup Available' ? Colors.green.shade700 : Colors.orange.shade800,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      resource['actionType'],
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: resource['actionType'] == 'Pickup Available' ? Colors.green.shade700 : Colors.orange.shade800,
                      ),
                    ),
                  ],
                ),
              ),
              
            // LOGISTICS ITEMS LIST
            if (resource['items'] != null && (resource['items'] as List).isNotEmpty) ...[
              const Text('LOGISTICS REQUIRED:', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Colors.blueGrey, letterSpacing: 0.5)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: (resource['items'] as List<dynamic>).map((item) => Chip(
                  label: Text(item.toString(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  backgroundColor: Colors.blueGrey.shade50,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  side: BorderSide(color: Colors.blueGrey.withOpacity(0.2)),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                )).toList(),
              ),
              const SizedBox(height: 24),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C9EEB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                ),
                onPressed: () => _launchDirections(userPos, LatLng(resource['latitude'], resource['longitude'])),
                icon: const Icon(Icons.directions),
                label: const Text('GET DIRECTIONS', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5)),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    ).whenComplete(() {
      if (mounted) {
        setState(() => _activePolylines.clear());
        _mapController?.animateCamera(CameraUpdate.newLatLngZoom(userPos, 13.5));
      }
    });
  }

  Future<void> _launchDirections(LatLng origin, LatLng destination) async {
    final url = 'https://www.google.com/maps/dir/?api=1&origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&travelmode=driving';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final resourceService = Provider.of<ResourceHubService>(context);
    final locationService = Provider.of<LocationService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resource Hub', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Stack(
        children: [
          StreamBuilder<LatLng>(
            stream: locationService.locationStream,
            builder: (context, locSnapshot) {
              // Fallback to Pune Railway Station or current GPS
              LatLng pos = locSnapshot.data ?? locationService.currentLocation;
              if (pos.latitude == 0.0 && pos.longitude == 0.0) {
                 pos = const LatLng(18.5284, 73.8738);
              }
              
              return StreamBuilder<List<Map<String, dynamic>>>(
                stream: resourceService.getResourcePoints(pos, typeFilter: _selectedType),
                builder: (context, resSnapshot) {
                  final markers = (resSnapshot.data ?? []).map((res) {
                    final type = res['type'] ?? 'unknown';
                    return Marker(
                      markerId: MarkerId(res['id']),
                      position: LatLng(res['latitude'], res['longitude']),
                      icon: _customIcons[type] ?? BitmapDescriptor.defaultMarkerWithHue(_getMarkerHue(type)),
                      onTap: () => _showResourceDetails(res, pos),
                    );
                  }).toSet();
                  
                  // Explicitly add Volunteer's Current Location Marker
                  markers.add(
                    Marker(
                      markerId: const MarkerId('volunteer_location'),
                      position: pos,
                      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
                      infoWindow: const InfoWindow(title: 'You are here'),
                      zIndex: 999,
                    ),
                  );

                  return GoogleMap(
                    initialCameraPosition: CameraPosition(target: pos, zoom: 13.5),
                    onMapCreated: (c) => _mapController = c,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                    markers: markers,
                    polylines: _activePolylines,
                    zoomControlsEnabled: false,
                    mapToolbarEnabled: false,
                  );
                },
              );
            },
          ),
          
          // Filter Chips
          Positioned(
            top: 16,
            left: 0,
            right: 0,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: _types.map((type) {
                  final isSelected = _selectedType == type;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      label: Text(type),
                      selected: isSelected,
                      onSelected: (val) => setState(() => _selectedType = type),
                      backgroundColor: Colors.white.withOpacity(0.9),
                      selectedColor: const Color(0xFF6C9EEB),
                      checkmarkColor: Colors.white,
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isSelected ? const Color(0xFF6C9EEB) : Colors.black12,
                          width: 1,
                        ),
                      ),
                      elevation: 2,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          
          // Radius Indicator Overlay
          Positioned(
            bottom: 30,
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle),
                    child: const Icon(Icons.radar, size: 14, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('PROXIMITY RADAR', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Colors.blueAccent)),
                      Text('Showing within 10km', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black87)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}