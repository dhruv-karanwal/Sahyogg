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

  // Check if profile exists
  Future<bool> hasProfile(String volunteerId) async {
    final doc = await _firestore.collection(_collection).doc(volunteerId).get();
    return doc.exists;
  }
}
