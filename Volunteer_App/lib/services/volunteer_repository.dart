import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/volunteer_model.dart';

class VolunteerRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'volunteers';

  // Get active volunteer profile
  Stream<VolunteerModel> getVolunteerProfile(String volunteerId) {
    return _firestore
        .collection(_collection)
        .doc(volunteerId)
        .snapshots()
        .map((doc) => VolunteerModel.fromFirestore(doc));
  }

  // Update duty status
  Future<void> updateDutyStatus(String volunteerId, bool isOnDuty) async {
    await _firestore.collection(_collection).doc(volunteerId).update({
      'isOnDuty': isOnDuty,
      'dutyStartTime': isOnDuty ? FieldValue.serverTimestamp() : null,
    });
  }

  // Update stats (completed missions)
  Future<void> incrementMissions(String volunteerId) async {
    await _firestore.collection(_collection).doc(volunteerId).update({
      'totalMissions': FieldValue.increment(1),
    });
  }

  // Update specific profile fields
  Future<void> updateProfile(String volunteerId, Map<String, dynamic> data) async {
    await _firestore.collection(_collection).doc(volunteerId).update(data);
  }

  // Ensure mock profile exists for demo
  Future<void> ensureMockProfileExists(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();
    if (!doc.exists) {
      await _firestore.collection(_collection).doc(id).set({
        'name': 'John Doe',
        'skills': ['Search & Rescue', 'First Aid', 'Boat Handling'],
        'isOnDuty': false,
        'rating': 4.8,
        'totalMissions': 12,
        'dutyStartTime': null,
        'phone': '+91 98765 43210',
        'email': 'john.doe@sahyog.org',
        'bloodGroup': 'O+ Positive',
        'volunteerId': 'VOL-JD77',
        'preferredDisasterType': 'Flood Relief',
        'operationRadius': 15.0,
        'hasVehicle': true,
        'emergencyContactName': 'Jane Doe',
        'emergencyContactPhone': '+91 91234 56789',
        'isDeadManAlertEnabled': false,
        'isLocationSharingEnabled': true,
      });
    }
  }
}
