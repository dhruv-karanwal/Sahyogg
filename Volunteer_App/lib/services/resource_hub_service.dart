import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ResourceHubService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Haversine formula for distance calculation in KM
  double calculateDistance(LatLng p1, LatLng p2) {
    const double p = 0.017453292519943295; // Math.PI / 180
    final double a = 0.5 - cos((p2.latitude - p1.latitude) * p) / 2 +
        cos(p1.latitude * p) * cos(p2.latitude * p) *
        (1 - cos((p2.longitude - p1.longitude) * p)) / 2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }

  Stream<List<Map<String, dynamic>>> getResourcePoints(LatLng center, {String? typeFilter}) {
    return _firestore
        .collection('resource_points')
        .snapshots()
        .map((snapshot) {
      final resources = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        
        // Handle new DB schema formatting vs old
        var lat = 0.0;
        var lng = 0.0;
        
        if (data['latitude'] != null) {
          lat = (data['latitude'] ?? 0.0).toDouble();
          lng = (data['longitude'] ?? 0.0).toDouble();
        } else if (data['location'] != null && data['location'] is Map) {
          lat = (data['location']['latitude'] ?? 0.0).toDouble();
          lng = (data['location']['longitude'] ?? 0.0).toDouble();
        }
        
        // Handle names that might be arrays (like 'items: [Rice Bags]')
        if (data['name'] == null && data['items'] != null && data['items'] is List && (data['items'] as List).isNotEmpty) {
           data['name'] = (data['items'] as List).first.toString();
        }

        final resPos = LatLng(lat, lng);
        
        data['distance'] = calculateDistance(center, resPos);
        return data;
      }).where((res) {
        final double distance = res['distance'] ?? 999.0;
        final bool withinRadius = distance <= 10.0;
        
        if (typeFilter == null || typeFilter == 'All') return withinRadius;
        
        // Map Filter Chips to Firestore 'type' values
        String targetType = typeFilter.toLowerCase();
        if (targetType == 'safe') targetType = 'safe_zone';
        
        final bool matchesType = res['type'] == targetType;
        return withinRadius && matchesType;
      }).toList();
      
      // Sort by proximity
      resources.sort((a, b) => (a['distance'] as double).compareTo(b['distance'] as double));
      return resources;
    });
  }

  // LOGISTICS TRACKING: Blinkit-style pickup/dropoff logic

  Future<void> acceptLogisticsTask(String resourceId, String volunteerId) async {
    await _firestore
        .collection('resource_points')
        .doc(resourceId)
        .update({
      'status': 'IN_TRANSIT',
      'assignedVolunteer': volunteerId,
      'pickupTime': FieldValue.serverTimestamp(),
    });
  }

  Future<void> completeLogisticsTask(String resourceId, String volunteerId) async {
    // 1. Mark the resource point as delivered
    await _firestore
        .collection('resource_points')
        .doc(resourceId)
        .update({
      'status': 'DELIVERED',
      'deliveryTime': FieldValue.serverTimestamp(),
    });

    // 2. Grant Trust Score + Mission points for completing a logistics task
    await _firestore.collection('volunteers').doc(volunteerId).update({
      'totalMissions': FieldValue.increment(1),
      'rating': FieldValue.increment(0.1), // Bump trust score
    });
  }
}
