import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/mission_model.dart';

class MissionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // READ ONLY: Get all rescue requests
  Stream<List<Map<String, dynamic>>> getRescueRequests() {
    return _firestore
        .collection('Disasters')
        .doc('Flood')
        .collection('rescue_requests')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  // CREATE: New mission doc in 'missions' collection
  Future<void> acceptMission(String volunteerId, String rescueRequestId) async {
    await _firestore
        .collection('Disasters')
        .doc('Flood')
        .collection('missions')
        .add({
      'volunteerId': volunteerId,
      'rescueRequestId': rescueRequestId,
      'status': 'assigned',
      'timestamp': FieldValue.serverTimestamp(),
    });

    // UPDATE: Status and citizenMessage in rescue_requests
    await _firestore
        .collection('Disasters')
        .doc('Flood')
        .collection('rescue_requests')
        .doc(rescueRequestId)
        .update({
      'status': 'accepted',
      'citizenMessage': 'Volunteer is on the way',
    });
  }

  // UPDATE: Mission status lifecycle
  Future<void> updateMissionStatus(String missionId, MissionStatus status) async {
    await _firestore
        .collection('Disasters')
        .doc('Flood')
        .collection('missions')
        .doc(missionId)
        .update({
      'status': status.toString().split('.').last,
      'updateTimestamp': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<MissionModel>> getActiveMissions(String volunteerId) {
    return _firestore
        .collection('Disasters')
        .doc('Flood')
        .collection('missions')
        .where('volunteerId', isEqualTo: volunteerId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MissionModel.fromFirestore(doc))
          .where((m) => m.status != MissionStatus.completed)
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    });
  }
}
