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
    final batch = _firestore.batch();
    final newDocRef = _firestore.collection('Disasters').doc('Flood').collection('rescue_requests').doc();
    
    final newDoc = {
      'volunteerId': volunteerId,
      'lat': location.latitude,
      'lng': location.longitude,
      'description': description ?? 'Emergency Flare Triggered',
      'hasVoiceNote': hasVoiceNote,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'PENDING',
      'priority': 'High',
      'source': 'VOLUNTEER_FLARE',
      'phone': 'VOLUNTEER_DISPATCH',
      'emergencyType': 'Volunteer Emergency',
      'district': 'Volunteer Operations',
      'city': 'Mobile Field Unit',
      'area': 'Ground Dispatch',
    };

    batch.set(newDocRef, newDoc);

    // Sync with global Admin Analytics to guarantee it appears on dashboards
    final summaryRef = _firestore.doc('Disasters/Flood/rescue_summary/${newDoc['district']}/cities/${newDoc['city']}/areas/${newDoc['area']}');
    
    batch.set(
      summaryRef,
      {
        'district': newDoc['district'],
        'city': newDoc['city'],
        'area': newDoc['area'],
        'lat': location.latitude,
        'lng': location.longitude,
        'totalSOS': FieldValue.increment(1),
        'pending': FieldValue.increment(1),
        'lastUpdated': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    await batch.commit();
  }
}
