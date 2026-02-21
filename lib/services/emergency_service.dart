import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class EmergencyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // CREATE: Emergency alert
  Future<void> triggerEmergency(
    String volunteerId, 
    LatLng location, {
    String? description,
    bool hasVoiceNote = false,
  }) async {
    await _firestore.collection('emergency_alerts').add({
      'volunteerId': volunteerId,
      'location': {
        'latitude': location.latitude,
        'longitude': location.longitude,
      },
      'description': description ?? 'Emergency Flare Triggered',
      'hasVoiceNote': hasVoiceNote,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'critical',
      'priority': 'high', // High priority for Admin App
    });
  }
}
