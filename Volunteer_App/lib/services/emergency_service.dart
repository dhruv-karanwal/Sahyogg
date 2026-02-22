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
    await _firestore
        .collection('Disasters')
        .doc('Flood')
        .collection('rescue_requests')
        .add({
      'volunteerId': volunteerId,
      'lat': location.latitude,
      'lng': location.longitude,
      'description': description ?? 'Emergency Flare Triggered',
      'hasVoiceNote': hasVoiceNote,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'PENDING',
      'priority': 'High',
      'source': 'VOLUNTEER_FLARE',
    });
  }
}
