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
    final newDocRef = _firestore.collection('emergency_alerts').doc();
    
    final newDoc = {
      'volunteerId': volunteerId,
      'location': {
        'latitude': location.latitude,
        'longitude': location.longitude,
      },
      'description': description ?? 'Emergency Flare Triggered',
      'hasVoiceNote': hasVoiceNote,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'critical',
      'priority': 'high',
    };

    batch.set(newDocRef, newDoc);

    // Sync with global Admin Analytics to guarantee it appears on dashboards
    // Using default Admin App schema stubs just in case it's still needed,
    // though the primary alert relies on emergency_alerts now.
    final summaryRef = _firestore.doc('Disasters/Flood/rescue_summary/Volunteer Operations/cities/Mobile Field Unit/areas/Ground Dispatch');
    
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
