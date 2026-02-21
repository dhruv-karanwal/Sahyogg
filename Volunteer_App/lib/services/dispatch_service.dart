import 'dart:math';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/volunteer_model.dart';

class DispatchService {
  // Logic to filter rescue requests based on volunteer skills
  List<Map<String, dynamic>> filterRequestsBySkills(
    List<Map<String, dynamic>> requests,
    List<String> volunteerSkills,
  ) {
    if (volunteerSkills.isEmpty) return [];

    return requests.where((request) {
      List<String> requiredSkills = List<String>.from(request['requiredSkills'] ?? []);
      if (requiredSkills.isEmpty) return true;
      return requiredSkills.any((skill) => volunteerSkills.contains(skill));
    }).toList();
  }

  // Calculate Smart Priority Score (0-100)
  double calculatePriorityScore(Map<String, dynamic> request, LatLng userPos) {
    double score = 50.0; // Base score

    // 1. Proximity (40% weight)
    final reqLat = request['lat'] as double? ?? userPos.latitude;
    final reqLng = request['lng'] as double? ?? userPos.longitude;
    final dist = _calculateDistance(userPos.latitude, userPos.longitude, reqLat, reqLng);
    // Inverse distance score: closer = higher score. Max 40 points.
    // Assuming distance is in Decimal Degrees for simple hackathon mock
    final proximityScore = max(0.0, 40.0 - (dist * 1000)); 
    score += proximityScore;

    // 2. Impact Severity (30% weight)
    // Check for high-risk flags or people count
    final peopleCount = request['peopleCount'] as int? ?? 1;
    if (peopleCount > 5) score += 15;
    if (request['category'] == 'Medical' || request['category'] == 'Elderly') score += 15;

    // 3. Weather/Risk (30% weight) - Mocked based on area or hardcoded severity
    final severity = request['severity'] as String? ?? 'Moderate';
    if (severity.toLowerCase() == 'high') score += 20;
    if (severity.toLowerCase() == 'critical') score += 30;

    return score.clamp(0.0, 100.0);
  }

  // Generate a Unique Professional Mission Name
  String generateMissionName(Map<String, dynamic> request) {
    final cat = request['category'] ?? 'Rescue';
    final area = request['areaName'] ?? 'Sector';
    final id = request['id'].toString().substring(0, 3).toUpperCase();
    
    final List<String> prefixes = ['Operation', 'Mission', 'Project', 'Task'];
    final prefix = prefixes[Random().nextInt(prefixes.length)];

    return '$prefix $cat-$id ($area)';
  }

  // Generate Detailed Mock Metadata for Mission Detail View
  Map<String, dynamic> generateDetailedMetadata(Map<String, dynamic> request) {
    final random = Random();
    
    return {
      'peopleAlive': request['peopleCount'] ?? (random.nextInt(10) + 1),
      'peopleInjured': random.nextInt(5),
      'damageLevel': request['severity'] ?? (random.nextBool() ? 'High' : 'Moderate'),
      'foodFacility': random.nextBool() ? 'Available' : 'Unavailable',
      'roadBlockage': random.nextBool() ? 'Cleared' : 'Severe Blockage',
      'logisticsStatus': 'Ready',
      'firstAid': random.nextBool() ? 'Provided' : 'Pending',
      'ambulanceNearby': random.nextBool() ? 'Yes' : 'No',
      'nearestHelp': '${random.nextInt(5) + 1} km away',
    };
  }

  // Calculate mock distance
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return sqrt(pow(lat1 - lat2, 2) + pow(lon1 - lon2, 2));
  }
}
