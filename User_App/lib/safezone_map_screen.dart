// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:http/http.dart' as http;

// // Add your OpenRouteService API key here
// const String ORS_API_KEY = 'eyJvcmciOiI1YjNjZTM1OTc4NTExMTAwMDFjZjYyNDgiLCJpZCI6IjZiMzQ4NjAzNjAzYzQ5OWNhOWJkMTMyNWFmZDg0OGUwIiwiaCI6Im11cm11cjY0In0=';

// class SafeZoneMapScreen extends StatefulWidget {
//   final List<Map<String, dynamic>> zones;
//   final LatLng userLocation;
//   final int selectedIndex;

//   const SafeZoneMapScreen({
//     super.key,
//     required this.zones,
//     required this.userLocation,
//     this.selectedIndex = 0,
//   });

//   @override
//   State<SafeZoneMapScreen> createState() => _SafeZoneMapScreenState();
// }

// class _SafeZoneMapScreenState extends State<SafeZoneMapScreen> {
//   late List<Map<String, dynamic>> zones;
//   late int selectedIndex;
//   GoogleMapController? _mapController;
  
//   Set<Polyline> _polylines = {};
//   Set<Marker> _markers = {};
//   bool _isLoadingRoute = false;

//   @override
//   void initState() {
//     super.initState();
//     zones = List<Map<String, dynamic>>.from(widget.zones);
//     selectedIndex = widget.selectedIndex.clamp(0, zones.length - 1);
    
//     // Create initial markers
//     _updateMarkers();

//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _focusOnSelected();
//       _fetchRouteToSelected();
//     });
//   }

//   LatLng _zoneLatLng(int idx) {
//     // Check if coordinate is List (Firestore format often array or geopoint, but here likely array based on prev code)
//     final c = zones[idx]['coordinate'];
//     if (c is List) {
//       return LatLng((c[0] as num).toDouble(), (c[1] as num).toDouble());
//     }
//     // Fallback if needed
//     return const LatLng(0,0);
//   }

//   void _updateMarkers() {
//     Set<Marker> newMarkers = {};
    
//     // Zone Markers
//     for (int i = 0; i < zones.length; i++) {
//         final pt = _zoneLatLng(i);
//         final isSelected = i == selectedIndex;
        
//         newMarkers.add(
//            Marker(
//              markerId: MarkerId('zone_$i'),
//              position: pt,
//              icon: BitmapDescriptor.defaultMarkerWithHue(
//                 isSelected ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed
//              ),
//              infoWindow: InfoWindow(title: zones[i]['name'] ?? 'Safe Zone'),
//              onTap: () {
//                setState(() => selectedIndex = i);
//                _updateMarkers();
//                _focusOnSelected();
//                _fetchRouteToSelected();
//              }
//            )
//         );
//     }

//     // User Marker
//     newMarkers.add(
//        Marker(
//          markerId: const MarkerId('user_loc'),
//          position: widget.userLocation,
//          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
//          infoWindow: const InfoWindow(title: 'You are here'),
//        )
//     );

//     setState(() {
//       _markers = newMarkers;
//     });
//   }

//   void _focusOnSelected() {
//     final latlng = _zoneLatLng(selectedIndex);
//     _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latlng, 13));
//   }

//   Future<void> _fetchRouteToSelected() async {
//     setState(() => _isLoadingRoute = true);

//     try {
//       final start = [
//         widget.userLocation.longitude,
//         widget.userLocation.latitude,
//       ];

//       final dest = _zoneLatLng(selectedIndex);

//       final end = [
//         dest.longitude,
//         dest.latitude,
//       ];

//       final uri = Uri.parse(
//         'https://api.openrouteservice.org/v2/directions/driving-car/geojson',
//       );

//       final response = await http.post(
//         uri,
//         headers: {
//           'Authorization': ORS_API_KEY,
//           'Content-Type': 'application/json',
//           'Accept': 'application/geo+json',
//         },
//         body: jsonEncode({
//           "coordinates": [start, end],
//         }),
//       );

//       if (response.statusCode != 200) {
//         throw Exception('ORS ${response.statusCode}: ${response.body}');
//       }

//       final data = jsonDecode(response.body);
//       final List coords = data['features'][0]['geometry']['coordinates'];

//       final List<LatLng> points = coords
//           .map<LatLng>((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
//           .toList();

//       setState(() {
//         _polylines = {
//           Polyline(
//             polylineId: const PolylineId('route'),
//             points: points,
//             color: Colors.blue,
//             width: 5,
//           ),
//         };
//         _isLoadingRoute = false;
//       });
      
//       // zoom to route
//       if (_mapController != null && points.isNotEmpty) {
//          // simple bound fit
//          double minLat = points.first.latitude;
//          double maxLat = points.first.latitude;
//          double minLng = points.first.longitude;
//          double maxLng = points.first.longitude;
//          for (var p in points) {
//             if (p.latitude < minLat) minLat = p.latitude;
//             if (p.latitude > maxLat) maxLat = p.latitude;
//             if (p.longitude < minLng) minLng = p.longitude;
//             if (p.longitude > maxLng) maxLng = p.longitude;
//          }
//          _mapController!.animateCamera(CameraUpdate.newLatLngBounds(
//            LatLngBounds(southwest: LatLng(minLat, minLng), northeast: LatLng(maxLat, maxLng)), 
//            50
//          ));
//       }

//     } catch (e) {
//       setState(() => _isLoadingRoute = false);
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Route error: $e')),
//         );
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final selectedZone = zones[selectedIndex];

//     return Scaffold(
//       appBar: AppBar(title: const Text('Safe Zones Map')),
//       body: Stack(
//         children: [
//           GoogleMap(
//              initialCameraPosition: CameraPosition(
//                 target: _zoneLatLng(selectedIndex),
//                 zoom: 13,
//              ),
//              onMapCreated: (c) => _mapController = c,
//              markers: _markers,
//              polylines: _polylines,
//              myLocationEnabled: true,
//              myLocationButtonEnabled: true,
//           ),

//           // top info and controls
//           Positioned(
//             top: 12,
//             left: 12,
//             right: 12,
//             child: Row(
//               children: [
//                 Expanded(
//                   child: Card(
//                     child: Padding(
//                       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//                       child: Row(
//                         children: [
//                           Expanded(child: Text(selectedZone['name'] ?? 'Selected zone')),
//                           if (_isLoadingRoute) const SizedBox(width: 8),
//                           if (_isLoadingRoute) const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 ElevatedButton(
//                   onPressed: _focusOnSelected,
//                   child: const Icon(Icons.my_location),
//                 )
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
