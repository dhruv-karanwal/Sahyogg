import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
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

  static const List<String> _types = ['All', 'Safe', 'Food', 'Medical', 'Shelter'];

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
            
            // BLINKIT-STYLE LOGISTICS BUTTONS
            if (resource['status'] == 'PENDING' || resource['status'] == null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {
                     Provider.of<ResourceHubService>(context, listen: false).acceptLogisticsTask(resource['id'], 'vol_001');
                     Navigator.pop(context);
                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Logistics Task Accepted! You are now in transit.')));
                  },
                  icon: const Icon(Icons.delivery_dining),
                  label: const Text('ACCEPT PICKUP TASK', style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              ),
            ] else if (resource['status'] == 'IN_TRANSIT' && resource['assignedVolunteer'] == 'vol_001') ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {
                     Provider.of<ResourceHubService>(context, listen: false).completeLogisticsTask(resource['id'], 'vol_001');
                     Navigator.pop(context);
                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Delivery Complete! Trust Score increased.')));
                  },
                  icon: const Icon(Icons.check_circle),
                  label: const Text('CONFIRM DROPOFF', style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              ),
            ],
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
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
              final pos = locSnapshot.data ?? locationService.currentLocation;
              
              return StreamBuilder<List<Map<String, dynamic>>>(
                stream: resourceService.getResourcePoints(pos, typeFilter: _selectedType),
                builder: (context, resSnapshot) {
                  final markers = (resSnapshot.data ?? []).map((res) {
                    return Marker(
                      markerId: MarkerId(res['id']),
                      position: LatLng(res['latitude'], res['longitude']),
                      icon: BitmapDescriptor.defaultMarkerWithHue(_getMarkerHue(res['type'])),
                      onTap: () => _showResourceDetails(res, pos),
                    );
                  }).toSet();

                  return GoogleMap(
                    initialCameraPosition: CameraPosition(target: pos, zoom: 13.5),
                    onMapCreated: (c) => _mapController = c,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                    markers: markers,
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
