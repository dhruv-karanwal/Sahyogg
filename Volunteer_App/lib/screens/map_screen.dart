import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/location_service.dart';
import '../services/mission_service.dart';
import '../models/mission_model.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _controller;
  
  // Mock Danger Polygons (Pune area)
  final Set<Polygon> _dangerZones = {
    Polygon(
      polygonId: const PolygonId('danger_1'),
      points: const [
        LatLng(18.520, 73.850),
        LatLng(18.525, 73.850),
        LatLng(18.525, 73.855),
        LatLng(18.520, 73.855),
      ],
      fillColor: Colors.red.withOpacity(0.3),
      strokeColor: Colors.red,
      strokeWidth: 2,
    ),
    Polygon(
      polygonId: const PolygonId('danger_2'),
      points: const [
        LatLng(18.510, 73.840),
        LatLng(18.515, 73.840),
        LatLng(18.515, 73.845),
        LatLng(18.510, 73.845),
      ],
      fillColor: Colors.red.withOpacity(0.3),
      strokeColor: Colors.red,
      strokeWidth: 2,
    ),
  };

  Future<void> _launchDirections(LatLng origin, LatLng destination) async {
    final url = 'https://www.google.com/maps/dir/?api=1&origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&travelmode=driving';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationService = Provider.of<LocationService>(context);
    final missionService = Provider.of<MissionService>(context);
    const volunteerId = 'vol_001';

    return StreamBuilder<LatLng>(
      stream: locationService.locationStream,
      builder: (context, locSnapshot) {
        final pos = locSnapshot.data ?? locationService.currentLocation;
        
        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: missionService.getRescueRequests(),
          builder: (context, requestsSnapshot) {
            return StreamBuilder<List<MissionModel>>(
              stream: missionService.getActiveMissions(volunteerId),
              builder: (context, activeSnapshot) {
                final markers = <Marker>{
                  Marker(
                    markerId: const MarkerId('volunteer'),
                    position: pos,
                    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                    infoWindow: const InfoWindow(title: 'You (On Duty)'),
                  ),
                };

                Map<String, dynamic>? activeRequest;
                if (activeSnapshot.hasData && activeSnapshot.data!.isNotEmpty) {
                  final activeMission = activeSnapshot.data!.first;
                  if (requestsSnapshot.hasData) {
                    try {
                      activeRequest = requestsSnapshot.data!.firstWhere(
                        (r) => r['id'] == activeMission.rescueRequestId
                      );
                    } catch (_) {}
                  }
                }

                if (requestsSnapshot.hasData) {
                  for (var request in requestsSnapshot.data!) {
                    final lat = request['lat'] ?? 18.5204;
                    final lng = request['lng'] ?? 73.8567;
                    final isActive = activeRequest != null && request['id'] == activeRequest['id'];
                    
                    markers.add(Marker(
                      markerId: MarkerId(request['id']),
                      position: LatLng(lat, lng),
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                        isActive ? BitmapDescriptor.hueRed : BitmapDescriptor.hueOrange
                      ),
                      infoWindow: InfoWindow(
                        title: isActive ? 'ACTIVE: ${request['title']}' : request['title'],
                        snippet: request['areaName'] ?? 'Priority: High',
                      ),
                    ));
                  }
                }

                return Scaffold(
                  appBar: AppBar(
                    title: const Text('Tactical Map', style: TextStyle(fontWeight: FontWeight.w900)),
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    elevation: 0,
                  ),
                  body: Stack(
                    children: [
                      GoogleMap(
                        initialCameraPosition: CameraPosition(target: pos, zoom: 14),
                        onMapCreated: (c) => _controller = c,
                        myLocationEnabled: true,
                        myLocationButtonEnabled: true,
                        polygons: _dangerZones,
                        markers: markers,
                      ),
                      
                      // Tactical Legend
                      Positioned(
                        top: 16,
                        left: 16,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('Tactical Index', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Colors.blueGrey, letterSpacing: 0.5)),
                              const SizedBox(height: 8),
                              _buildLegendItem(Colors.red, 'Flood Damage Zone'),
                              _buildLegendItem(Colors.redAccent, 'Active Mission'),
                              _buildLegendItem(Colors.orange, 'Available Request'),
                              _buildLegendItem(Colors.blue, 'Your Location'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  floatingActionButton: activeRequest != null 
                    ? FloatingActionButton.extended(
                        onPressed: () {
                          final destination = LatLng(
                            activeRequest!['lat'] ?? 18.5204,
                            activeRequest!['lng'] ?? 73.8567
                          );
                          _launchDirections(pos, destination);
                        },
                        label: const Text('Get Directions'),
                        icon: const Icon(Icons.directions),
                        backgroundColor: const Color(0xFF6C9EEB),
                      )
                    : null,
                );
              },
            );
          },
        );
      },
    );
  }
  Widget _buildLegendItem(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color.withOpacity(0.4),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: color, width: 1.5),
            ),
          ),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
        ],
      ),
    );
  }
}
